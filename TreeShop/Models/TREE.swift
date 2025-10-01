import SwiftUI
import SwiftData
import MapKit

@Model
final class TREE {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - LOCATION
    var latitude: Double
    var longitude: Double
    var propertyID: UUID? // Link to PROPERTY

    // MARK: - TREE IDENTIFICATION
    var species: String // "Red Oak", "Sugar Maple", etc.
    var commonName: String?
    var scientificName: String?

    // MARK: - MEASUREMENTS (Professional Standards)
    var dbh: Double // Diameter at Breast Height (inches, measured at 4.5')
    var height: Double // Height in feet
    var canopyRadius: Double // Canopy radius in feet (half-spread)
    var crownSpread: Double // Full canopy diameter (calculated: canopyRadius × 2)

    // MARK: - TREE SCORES (Formulas)
    var treeScore: Double // H × DBH² × CR² (removal work volume)
    var trimScore: Double // H × DBH × CR² × % Removed (trimming work volume)
    var percentToTrim: Double? // Percentage of canopy to be trimmed (0-100)

    // MARK: - CONDITION ASSESSMENT
    var conditionRating: Int // 1-5 stars
    var healthStatus: String // "Healthy", "Needs Attention", "Declining", "Hazard"
    var structuralIssues: [String] // "Dead Branches", "Decay", "Lean", etc.
    var diseaseOrPest: [String]
    var rootIssues: [String]

    // MARK: - RISK ASSESSMENT
    var riskLevel: String // "Low", "Medium", "High", "Extreme"
    var targetRating: String // What could be damaged if tree fails
    var failurePotential: String // Likelihood of failure
    var hazardNotes: String?

    // MARK: - SERVICE RECOMMENDATIONS
    var recommendedServices: [String] // SERVICE_TYPE raw values
    var priorityLevel: String // "Low", "Medium", "High", "Urgent"
    var estimatedCost: Double?

    // MARK: - ASSESSMENT DATA
    var assessmentDate: Date?
    var assessorName: String?
    var assessorID: UUID? // Link to EMPLOYEE
    var lastInspectionDate: Date?

    // MARK: - PHOTOS
    var photoURLs: [String]
    var photoTimestamps: [Date]
    var beforePhotoURLs: [String]
    var afterPhotoURLs: [String]

    // MARK: - WORK HISTORY
    var workHistory: [TREE_WORK_RECORD]
    var hasBeenWorked: Bool
    var lastWorkDate: Date?
    var totalRevenueFromTree: Double

    // MARK: - NOTES
    var notes: String?
    var customerRequests: String?
    var accessNotes: String?

    // MARK: - STATUS
    var status: String // "Active", "Removed", "Planned for Removal", "Monitored"
    var isRemoved: Bool
    var removalDate: Date?

    // MARK: - INITIALIZER
    init(
        latitude: Double,
        longitude: Double,
        species: String,
        dbh: Double,
        height: Double,
        canopyRadius: Double,
        propertyID: UUID? = nil
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Location
        self.latitude = latitude
        self.longitude = longitude
        self.propertyID = propertyID

        // Identification
        self.species = species
        self.commonName = nil
        self.scientificName = nil

        // Measurements
        self.dbh = dbh
        self.height = height
        self.canopyRadius = canopyRadius
        self.crownSpread = canopyRadius * 2

        // Calculate scores
        self.treeScore = TREE.calculateTreeScore(height: height, dbh: dbh, canopyRadius: canopyRadius)
        self.trimScore = 0.0 // Will be calculated when percentToTrim is set
        self.percentToTrim = nil

        // Condition
        self.conditionRating = 3
        self.healthStatus = "Healthy"
        self.structuralIssues = []
        self.diseaseOrPest = []
        self.rootIssues = []

        // Risk
        self.riskLevel = "Low"
        self.targetRating = "None"
        self.failurePotential = "Low"
        self.hazardNotes = nil

        // Service recommendations
        self.recommendedServices = []
        self.priorityLevel = "Low"
        self.estimatedCost = nil

        // Assessment
        self.assessmentDate = Date()
        self.assessorName = nil
        self.assessorID = nil
        self.lastInspectionDate = nil

        // Photos
        self.photoURLs = []
        self.photoTimestamps = []
        self.beforePhotoURLs = []
        self.afterPhotoURLs = []

        // Work history
        self.workHistory = []
        self.hasBeenWorked = false
        self.lastWorkDate = nil
        self.totalRevenueFromTree = 0.0

        // Notes
        self.notes = nil
        self.customerRequests = nil
        self.accessNotes = nil

        // Status
        self.status = "Active"
        self.isRemoved = false
        self.removalDate = nil
    }

    // MARK: - COMPUTED PROPERTIES
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var pinColor: Color {
        switch healthStatus {
        case "Healthy": return APP_THEME.SUCCESS
        case "Needs Attention": return APP_THEME.WARNING
        case "Declining": return Color.orange
        case "Hazard": return APP_THEME.ERROR
        default: return Color.gray
        }
    }

    var displayName: String {
        if let name = commonName, !name.isEmpty {
            return name
        }
        return species
    }

    // MARK: - TREE SCORE FORMULAS

    static func calculateTreeScore(height: Double, dbh: Double, canopyRadius: Double) -> Double {
        // TreeScore = H × DBH² + CR²
        return (height * (dbh * dbh)) + (canopyRadius * canopyRadius)
    }

    static func calculateTrimScore(height: Double, dbh: Double, canopyRadius: Double, percentToTrim: Double) -> Double {
        // TrimScore = H × DBH × CR² × (% Removed ÷ 100)
        return height * dbh * (canopyRadius * canopyRadius) * (percentToTrim / 100.0)
    }

    func updateMeasurements(dbh: Double, height: Double, canopyRadius: Double) {
        self.dbh = dbh
        self.height = height
        self.canopyRadius = canopyRadius
        self.crownSpread = canopyRadius * 2

        // Recalculate scores
        self.treeScore = TREE.calculateTreeScore(height: height, dbh: dbh, canopyRadius: canopyRadius)

        if let percent = percentToTrim {
            self.trimScore = TREE.calculateTrimScore(height: height, dbh: dbh, canopyRadius: canopyRadius, percentToTrim: percent)
        }

        lastModifiedDate = Date()
    }

    func setTrimPercentage(_ percent: Double) {
        self.percentToTrim = percent
        self.trimScore = TREE.calculateTrimScore(height: height, dbh: dbh, canopyRadius: canopyRadius, percentToTrim: percent)
        lastModifiedDate = Date()
    }

    func addWorkRecord(service: SERVICE_TYPE, date: Date, revenue: Double, notes: String?) {
        let record = TREE_WORK_RECORD(
            serviceType: service.rawValue,
            workDate: date,
            revenue: revenue,
            notes: notes
        )

        workHistory.append(record)
        hasBeenWorked = true
        lastWorkDate = date
        totalRevenueFromTree += revenue
        lastModifiedDate = Date()
    }

    func markAsRemoved(date: Date) {
        status = "Removed"
        isRemoved = true
        removalDate = date
        healthStatus = "Removed"
        lastModifiedDate = Date()
    }
}

// MARK: - TREE WORK RECORD

struct TREE_WORK_RECORD: Codable {
    var id: UUID
    var serviceType: String // SERVICE_TYPE raw value
    var workDate: Date
    var revenue: Double
    var notes: String?
    var beforePhotoURLs: [String]
    var afterPhotoURLs: [String]

    init(serviceType: String, workDate: Date, revenue: Double, notes: String? = nil) {
        self.id = UUID()
        self.serviceType = serviceType
        self.workDate = workDate
        self.revenue = revenue
        self.notes = notes
        self.beforePhotoURLs = []
        self.afterPhotoURLs = []
    }
}

// MARK: - TREE HEALTH STATUS

enum TREE_HEALTH_STATUS: String, CaseIterable {
    case HEALTHY = "Healthy"
    case NEEDS_ATTENTION = "Needs Attention"
    case DECLINING = "Declining"
    case HAZARD = "Hazard"
    case REMOVED = "Removed"

    var color: Color {
        switch self {
        case .HEALTHY: return APP_THEME.SUCCESS
        case .NEEDS_ATTENTION: return APP_THEME.WARNING
        case .DECLINING: return Color.orange
        case .HAZARD: return APP_THEME.ERROR
        case .REMOVED: return Color.gray
        }
    }

    var icon: String {
        switch self {
        case .HEALTHY: return "checkmark.circle.fill"
        case .NEEDS_ATTENTION: return "exclamationmark.circle.fill"
        case .DECLINING: return "arrow.down.circle.fill"
        case .HAZARD: return "exclamationmark.triangle.fill"
        case .REMOVED: return "xmark.circle.fill"
        }
    }
}
