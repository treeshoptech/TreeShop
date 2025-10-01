import SwiftUI
import SwiftData

@Model
final class EQUIPMENT {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - BASIC INFORMATION
    var equipmentName: String
    var equipmentType: String // "Truck", "Chipper", "Stump Grinder", "Crane", etc.
    var make: String?
    var model: String?
    var year: Int?
    var serialNumber: String?
    var licensePlate: String?
    var vin: String?

    // MARK: - 6-INPUT COST SYSTEM
    // Input 1: Purchase Price
    var purchasePrice: Double
    var purchaseDate: Date

    // Input 2: Annual Usage Hours (realistic)
    var annualUsageHours: Double // e.g., 1,200 hours (200 days × 6 hours)

    // Input 3: Fuel Consumption
    var fuelConsumptionGPH: Double // Gallons per hour
    var currentFuelPricePerGallon: Double

    // Input 4: Depreciation (auto-calculated)
    var depreciationYears: Int // Ownership cycle (typically 5 years)

    // Input 5: Maintenance Cost
    var annualMaintenancePercentage: Double // % of purchase price annually (typically 15%)

    // Input 6: Insurance and Fixed Costs
    var annualInsuranceCost: Double
    var annualRegistrationCost: Double
    var annualStorageCost: Double

    // MARK: - CALCULATED COSTS
    var fuelCostPerHour: Double // GPH × Fuel Price
    var depreciationCostPerHour: Double // Purchase Price ÷ (Years × Annual Hours)
    var maintenanceCostPerHour: Double // (Purchase Price × %) ÷ Annual Hours
    var insuranceFixedCostPerHour: Double // (Insurance + Registration + Storage) ÷ Annual Hours
    var totalHourlyCost: Double // Sum of all above
    var minimumBillingRate: Double // Required rate to break even

    // MARK: - UTILIZATION TRACKING
    var totalHoursUsed: Double
    var hoursUsedThisYear: Double
    var lastUsedDate: Date?
    var utilizationRate: Double // Actual hours ÷ Annual hours target

    // MARK: - MAINTENANCE TRACKING
    var lastMaintenanceDate: Date?
    var nextMaintenanceDue: Date?
    var maintenanceIntervalHours: Double?
    var maintenanceHistory: [MAINTENANCE_RECORD]

    // MARK: - PERFORMANCE METRICS
    var pointsCompletedPerHour: Double? // Equipment efficiency
    var averageJobRevenue: Double?
    var totalRevenueGenerated: Double
    var profitabilityScore: Double? // Revenue vs. cost

    // MARK: - STATUS
    var equipmentStatus: String // "Active", "In Maintenance", "Out of Service", "Sold", "Retired"
    var isAvailable: Bool
    var currentJobID: UUID?
    var assignedToEmployeeID: UUID?

    // MARK: - REPLACEMENT TRIGGERS
    var shouldConsiderReplacement: Bool
    var replacementTriggerNotes: String?

    // MARK: - INITIALIZER
    init(
        equipmentName: String,
        equipmentType: EQUIPMENT_TYPE,
        purchasePrice: Double,
        purchaseDate: Date,
        annualUsageHours: Double,
        fuelConsumptionGPH: Double,
        currentFuelPrice: Double
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Basic info
        self.equipmentName = equipmentName
        self.equipmentType = equipmentType.rawValue
        self.make = nil
        self.model = nil
        self.year = nil
        self.serialNumber = nil
        self.licensePlate = nil
        self.vin = nil

        // 6-Input system
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.annualUsageHours = annualUsageHours
        self.fuelConsumptionGPH = fuelConsumptionGPH
        self.currentFuelPricePerGallon = currentFuelPrice
        self.depreciationYears = 5 // Standard 5-year cycle
        self.annualMaintenancePercentage = 0.15 // 15% standard
        self.annualInsuranceCost = 0.0
        self.annualRegistrationCost = 0.0
        self.annualStorageCost = 0.0

        // Calculate costs
        let costs = EQUIPMENT.calculateCosts(
            purchasePrice: purchasePrice,
            annualHours: annualUsageHours,
            fuelGPH: fuelConsumptionGPH,
            fuelPrice: currentFuelPrice,
            depreciationYears: 5,
            maintenancePercentage: 0.15,
            insuranceAnnual: 0,
            registrationAnnual: 0,
            storageAnnual: 0
        )

        self.fuelCostPerHour = costs.fuel
        self.depreciationCostPerHour = costs.depreciation
        self.maintenanceCostPerHour = costs.maintenance
        self.insuranceFixedCostPerHour = costs.insuranceFixed
        self.totalHourlyCost = costs.total
        self.minimumBillingRate = costs.total

        // Utilization
        self.totalHoursUsed = 0.0
        self.hoursUsedThisYear = 0.0
        self.lastUsedDate = nil
        self.utilizationRate = 0.0

        // Maintenance
        self.lastMaintenanceDate = nil
        self.nextMaintenanceDue = nil
        self.maintenanceIntervalHours = nil
        self.maintenanceHistory = []

        // Performance
        self.pointsCompletedPerHour = nil
        self.averageJobRevenue = nil
        self.totalRevenueGenerated = 0.0
        self.profitabilityScore = nil

        // Status
        self.equipmentStatus = "Active"
        self.isAvailable = true
        self.currentJobID = nil
        self.assignedToEmployeeID = nil

        // Replacement
        self.shouldConsiderReplacement = false
        self.replacementTriggerNotes = nil
    }

    // MARK: - COST CALCULATIONS

    static func calculateCosts(
        purchasePrice: Double,
        annualHours: Double,
        fuelGPH: Double,
        fuelPrice: Double,
        depreciationYears: Int,
        maintenancePercentage: Double,
        insuranceAnnual: Double,
        registrationAnnual: Double,
        storageAnnual: Double
    ) -> (fuel: Double, depreciation: Double, maintenance: Double, insuranceFixed: Double, total: Double) {

        let fuelCost = fuelGPH * fuelPrice
        let depreciationCost = purchasePrice / (Double(depreciationYears) * annualHours)
        let maintenanceCost = (purchasePrice * maintenancePercentage) / annualHours
        let insuranceFixedCost = (insuranceAnnual + registrationAnnual + storageAnnual) / annualHours
        let total = fuelCost + depreciationCost + maintenanceCost + insuranceFixedCost

        return (fuelCost, depreciationCost, maintenanceCost, insuranceFixedCost, total)
    }

    func recalculateCosts() {
        let costs = EQUIPMENT.calculateCosts(
            purchasePrice: purchasePrice,
            annualHours: annualUsageHours,
            fuelGPH: fuelConsumptionGPH,
            fuelPrice: currentFuelPricePerGallon,
            depreciationYears: depreciationYears,
            maintenancePercentage: annualMaintenancePercentage,
            insuranceAnnual: annualInsuranceCost,
            registrationAnnual: annualRegistrationCost,
            storageAnnual: annualStorageCost
        )

        fuelCostPerHour = costs.fuel
        depreciationCostPerHour = costs.depreciation
        maintenanceCostPerHour = costs.maintenance
        insuranceFixedCostPerHour = costs.insuranceFixed
        totalHourlyCost = costs.total
        minimumBillingRate = costs.total
        lastModifiedDate = Date()

        // Check replacement triggers
        checkReplacementTriggers()
    }

    func logUsage(hours: Double, jobDate: Date, revenue: Double) {
        totalHoursUsed += hours
        hoursUsedThisYear += hours
        lastUsedDate = jobDate
        totalRevenueGenerated += revenue

        // Update utilization rate
        utilizationRate = hoursUsedThisYear / annualUsageHours

        lastModifiedDate = Date()
    }

    func addMaintenance(date: Date, cost: Double, description: String, nextDueHours: Double? = nil) {
        let record = MAINTENANCE_RECORD(
            maintenanceDate: date,
            cost: cost,
            description: description,
            performedBy: nil
        )

        maintenanceHistory.append(record)
        lastMaintenanceDate = date

        if let intervalHours = nextDueHours {
            maintenanceIntervalHours = intervalHours
            // Calculate next due based on current hours + interval
        }

        lastModifiedDate = Date()
    }

    private func checkReplacementTriggers() {
        // Trigger 1: Maintenance cost exceeds threshold
        if maintenanceCostPerHour > 12.0 {
            shouldConsiderReplacement = true
            replacementTriggerNotes = "Maintenance cost exceeds $12/hour threshold"
        }

        // Trigger 2: Utilization below minimum
        if hoursUsedThisYear > 0 && hoursUsedThisYear < 1000 {
            shouldConsiderReplacement = true
            replacementTriggerNotes = "Utilization below 1,000 hours minimum"
        }

        // Trigger 3: Age exceeds depreciation period
        let yearsSincePurchase = Calendar.current.dateComponents([.year], from: purchaseDate, to: Date()).year ?? 0
        if yearsSincePurchase > depreciationYears {
            shouldConsiderReplacement = true
            replacementTriggerNotes = "Equipment age exceeds depreciation period"
        }
    }

    // MARK: - COMPUTED PROPERTIES

    var dailyRevenueRequirement: Double {
        let averageDailyHours = annualUsageHours / 200.0 // 200 work days
        return minimumBillingRate * averageDailyHours
    }

    var annualRevenueTarget: Double {
        minimumBillingRate * annualUsageHours
    }

    var equipmentTypeEnum: EQUIPMENT_TYPE {
        EQUIPMENT_TYPE(rawValue: equipmentType) ?? .OTHER
    }

    var yearsSincePurchase: Int {
        Calendar.current.dateComponents([.year], from: purchaseDate, to: Date()).year ?? 0
    }

    var isUnderutilized: Bool {
        hoursUsedThisYear < (annualUsageHours * 0.75) // Below 75% target
    }
}

// MARK: - MAINTENANCE RECORD

struct MAINTENANCE_RECORD: Codable {
    var id: UUID
    var maintenanceDate: Date
    var cost: Double
    var description: String
    var performedBy: String?
    var nextDueDate: Date?
    var notes: String?

    init(maintenanceDate: Date, cost: Double, description: String, performedBy: String?) {
        self.id = UUID()
        self.maintenanceDate = maintenanceDate
        self.cost = cost
        self.description = description
        self.performedBy = performedBy
        self.nextDueDate = nil
        self.notes = nil
    }
}

// MARK: - EQUIPMENT TYPES

enum EQUIPMENT_TYPE: String, CaseIterable {
    case TRUCK = "Truck"
    case CHIPPER = "Chipper"
    case STUMP_GRINDER = "Stump Grinder"
    case CRANE = "Crane"
    case BUCKET_TRUCK = "Bucket Truck"
    case LOADER = "Loader"
    case SKID_STEER = "Skid Steer"
    case TRAILER = "Trailer"
    case CHAINSAW = "Chainsaw"
    case MULCHER = "Mulcher"
    case OTHER = "Other"

    var icon: String {
        switch self {
        case .TRUCK: return "truck.box.fill"
        case .CHIPPER: return "tornado"
        case .STUMP_GRINDER: return "circle.grid.cross.fill"
        case .CRANE: return "arrow.up.and.down.and.arrow.left.and.right"
        case .BUCKET_TRUCK: return "arrow.up.circle.fill"
        case .LOADER: return "shippingbox.fill"
        case .SKID_STEER: return "square.grid.3x3.fill"
        case .TRAILER: return "rectangle.connected.to.line.below"
        case .CHAINSAW: return "bolt.fill"
        case .MULCHER: return "leaf.fill"
        case .OTHER: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .TRUCK: return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .CHIPPER: return Color(red: 0.9, green: 0.5, blue: 0.1)
        case .STUMP_GRINDER: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .CRANE: return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .BUCKET_TRUCK: return Color(red: 0.2, green: 0.7, blue: 0.9)
        case .LOADER: return Color(red: 0.5, green: 0.5, blue: 0.1)
        case .SKID_STEER: return Color(red: 0.7, green: 0.3, blue: 0.5)
        case .TRAILER: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .CHAINSAW: return Color(red: 0.9, green: 0.7, blue: 0.1)
        case .MULCHER: return Color(red: 0.3, green: 0.7, blue: 0.3)
        case .OTHER: return Color(red: 0.6, green: 0.6, blue: 0.6)
        }
    }
}
