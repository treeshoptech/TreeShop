import SwiftUI
import SwiftData

@Model
final class EMPLOYEE {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - BASIC INFORMATION
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var dateOfBirth: Date?
    var socialSecurityNumber: String? // Encrypted
    var emergencyContactName: String?
    var emergencyContactPhone: String?

    // MARK: - EMPLOYMENT
    var hireDate: Date
    var employmentStatus: String // "Active", "Inactive", "On Leave", "Terminated"
    var terminationDate: Date?
    var terminationReason: String?

    // MARK: - CAREER TRACK (16 Tracks)
    var primaryTrack: String // ATC, TRS, FOR, LCL, MUL, STG, ESR, LSC, EQO, MNT, SAL, PMC, ADM, FIN, SAF, TEC
    var tier: Int // 1-5

    // MARK: - BASE COMPENSATION
    var baseHourlyRate: Double // Based on tier

    // MARK: - LEADERSHIP PREMIUMS
    var hasTeamLeader: Bool // +L: +$3.00/hour
    var hasSupervisor: Bool // +S: +$7.00/hour
    var isManager: Bool // +M: Salary-based
    var isDirector: Bool // +D: Executive

    // MARK: - EQUIPMENT CERTIFICATIONS
    var equipmentLevel: Int // 1-4 (E1=base, E2=+$1.50, E3=+$4.00, E4=+$7.00)

    // MARK: - DRIVER CLASSIFICATIONS
    var driverClass: Int // 1-3 (D1=base, D2=+$2.00, D3=+$3.00 for CDL)

    // MARK: - PROFESSIONAL CERTIFICATIONS
    var hasCraneCert: Bool // +CRA: +$4.00/hour
    var hasISACert: Bool // +ISA: +$2.50/hour
    var hasOSHACert: Bool // +OSH: +$2.00/hour
    var hasHazmatCert: Bool // +HAZ: +$1.50/hour

    // MARK: - CROSS-TRAINING
    var crossTrainingTracks: [String] // ["ESR3", "TRS2"] format

    // MARK: - CALCULATED COMPENSATION
    var totalHourlyWage: Double // Auto-calculated
    var laborBurdenMultiplier: Double // 1.6-2.2x based on tier
    var trueBusinessCost: Double // wage × burden

    // MARK: - PERFORMANCE
    var averagePpH: Double // Points per hour average
    var pphByService: [String: Double] // PpH broken down by service type
    var jobsCompleted: Int
    var totalHoursWorked: Double
    var performanceRating: Double // 1-5 stars

    // MARK: - SCHEDULE & AVAILABILITY
    var regularSchedule: String? // "Mon-Fri 8am-5pm"
    var availableHoursPerWeek: Double
    var preferredDaysOff: [String]
    var currentAvailabilityStatus: String // "Available", "On Job", "Off Duty", "Vacation"

    // MARK: - INITIALIZER
    init(
        firstName: String,
        lastName: String,
        phoneNumber: String,
        hireDate: Date,
        primaryTrack: CAREER_TRACK,
        tier: Int = 1,
        baseHourlyRate: Double
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Basic info
        self.firstName = firstName
        self.lastName = lastName
        self.email = nil
        self.phoneNumber = phoneNumber
        self.address = nil
        self.city = nil
        self.state = nil
        self.zipCode = nil
        self.dateOfBirth = nil
        self.socialSecurityNumber = nil
        self.emergencyContactName = nil
        self.emergencyContactPhone = nil

        // Employment
        self.hireDate = hireDate
        self.employmentStatus = "Active"
        self.terminationDate = nil
        self.terminationReason = nil

        // Career track
        self.primaryTrack = primaryTrack.rawValue
        self.tier = tier

        // Base compensation
        self.baseHourlyRate = baseHourlyRate

        // Leadership (none by default)
        self.hasTeamLeader = false
        self.hasSupervisor = false
        self.isManager = false
        self.isDirector = false

        // Equipment (base level)
        self.equipmentLevel = 1

        // Driver (base level)
        self.driverClass = 1

        // Certifications (none by default)
        self.hasCraneCert = false
        self.hasISACert = false
        self.hasOSHACert = false
        self.hasHazmatCert = false

        // Cross-training
        self.crossTrainingTracks = []

        // Calculate compensation
        let calculatedWage = EMPLOYEE.calculateWage(
            base: baseHourlyRate,
            tier: tier,
            hasTeamLeader: false,
            hasSupervisor: false,
            equipmentLevel: 1,
            driverClass: 1,
            hasCraneCert: false,
            hasISACert: false,
            hasOSHACert: false,
            hasHazmatCert: false
        )
        let calculatedBurden = EMPLOYEE.getBurdenMultiplier(for: tier)

        self.totalHourlyWage = calculatedWage
        self.laborBurdenMultiplier = calculatedBurden
        self.trueBusinessCost = calculatedWage * calculatedBurden

        // Performance
        self.averagePpH = 0.0
        self.pphByService = [:]
        self.jobsCompleted = 0
        self.totalHoursWorked = 0.0
        self.performanceRating = 0.0

        // Schedule
        self.regularSchedule = "Mon-Fri 8:00 AM - 5:00 PM"
        self.availableHoursPerWeek = 40.0
        self.preferredDaysOff = ["Saturday", "Sunday"]
        self.currentAvailabilityStatus = "Available"
    }

    // MARK: - COMPUTED PROPERTIES
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var employeeCode: String {
        var code = "\(primaryTrack)\(tier)"

        if hasSupervisor { code += "+S" }
        else if hasTeamLeader { code += "+L" }
        if isManager { code += "+M" }
        if isDirector { code += "+D" }

        if equipmentLevel > 1 { code += "+E\(equipmentLevel)" }
        if driverClass > 1 { code += "+D\(driverClass)" }

        if hasCraneCert { code += "+CRA" }
        if hasISACert { code += "+ISA" }
        if hasOSHACert { code += "+OSH" }
        if hasHazmatCert { code += "+HAZ" }

        if !crossTrainingTracks.isEmpty {
            code += " / " + crossTrainingTracks.map { "X-\($0)" }.joined(separator: "+")
        }

        return code
    }

    var careerTrack: CAREER_TRACK {
        CAREER_TRACK(rawValue: primaryTrack) ?? .TRS
    }

    // MARK: - WAGE CALCULATION
    func recalculateCompensation() {
        totalHourlyWage = EMPLOYEE.calculateWage(
            base: baseHourlyRate,
            tier: tier,
            hasTeamLeader: hasTeamLeader,
            hasSupervisor: hasSupervisor,
            equipmentLevel: equipmentLevel,
            driverClass: driverClass,
            hasCraneCert: hasCraneCert,
            hasISACert: hasISACert,
            hasOSHACert: hasOSHACert,
            hasHazmatCert: hasHazmatCert
        )

        laborBurdenMultiplier = EMPLOYEE.getBurdenMultiplier(for: tier)
        trueBusinessCost = totalHourlyWage * laborBurdenMultiplier
        lastModifiedDate = Date()
    }

    static func calculateWage(
        base: Double,
        tier: Int,
        hasTeamLeader: Bool,
        hasSupervisor: Bool,
        equipmentLevel: Int,
        driverClass: Int,
        hasCraneCert: Bool,
        hasISACert: Bool,
        hasOSHACert: Bool,
        hasHazmatCert: Bool
    ) -> Double {
        var wage = base

        // Tier multiplier
        let tierMultiplier = getTierMultiplier(for: tier)
        wage *= tierMultiplier

        // Leadership premiums
        if hasSupervisor { wage += 7.00 }
        else if hasTeamLeader { wage += 3.00 }

        // Equipment premiums
        switch equipmentLevel {
        case 2: wage += 1.50
        case 3: wage += 4.00
        case 4: wage += 7.00
        default: break
        }

        // Driver premiums
        switch driverClass {
        case 2: wage += 2.00
        case 3: wage += 3.00
        default: break
        }

        // Certification premiums
        if hasCraneCert { wage += 4.00 }
        if hasISACert { wage += 2.50 }
        if hasOSHACert { wage += 2.00 }
        if hasHazmatCert { wage += 1.50 }

        return wage
    }

    static func getTierMultiplier(for tier: Int) -> Double {
        switch tier {
        case 1: return 1.6
        case 2: return 1.7
        case 3: return 1.8
        case 4: return 2.0
        case 5: return 2.2
        default: return 1.6
        }
    }

    static func getBurdenMultiplier(for tier: Int) -> Double {
        switch tier {
        case 1: return 1.6
        case 2: return 1.7
        case 3: return 1.8
        case 4: return 2.0
        case 5: return 2.2
        default: return 1.7
        }
    }
}

// MARK: - CAREER TRACKS (16 Tracks)

enum CAREER_TRACK: String, CaseIterable {
    // Field Operations
    case ATC = "ATC" // Arboriculture & Tree Care
    case TRS = "TRS" // Tree Removal & Rigging
    case FOR = "FOR" // Forestry & Land Management
    case LCL = "LCL" // Land Clearing & Excavation
    case MUL = "MUL" // Mulching & Material Processing
    case STG = "STG" // Stump Grinding & Site Restoration
    case ESR = "ESR" // Emergency & Storm Response
    case LSC = "LSC" // Landscaping & Grounds

    // Equipment & Maintenance
    case EQO = "EQO" // Equipment Operations
    case MNT = "MNT" // Maintenance & Repair

    // Business Operations
    case SAL = "SAL" // Sales & Business Development
    case PMC = "PMC" // Project Management & Coordination
    case ADM = "ADM" // Administrative & Office Operations
    case FIN = "FIN" // Financial & Accounting
    case SAF = "SAF" // Safety & Compliance
    case TEC = "TEC" // Technology & Systems

    var displayName: String {
        switch self {
        case .ATC: return "Arboriculture & Tree Care"
        case .TRS: return "Tree Removal & Rigging"
        case .FOR: return "Forestry & Land Management"
        case .LCL: return "Land Clearing & Excavation"
        case .MUL: return "Mulching & Material Processing"
        case .STG: return "Stump Grinding & Site Restoration"
        case .ESR: return "Emergency & Storm Response"
        case .LSC: return "Landscaping & Grounds"
        case .EQO: return "Equipment Operations"
        case .MNT: return "Maintenance & Repair"
        case .SAL: return "Sales & Business Development"
        case .PMC: return "Project Management & Coordination"
        case .ADM: return "Administrative & Office Operations"
        case .FIN: return "Financial & Accounting"
        case .SAF: return "Safety & Compliance"
        case .TEC: return "Technology & Systems"
        }
    }

    var category: String {
        switch self {
        case .ATC, .TRS, .FOR, .LCL, .MUL, .STG, .ESR, .LSC:
            return "Field Operations"
        case .EQO, .MNT:
            return "Equipment & Maintenance"
        case .SAL, .PMC, .ADM, .FIN, .SAF, .TEC:
            return "Business Operations"
        }
    }

    var color: Color {
        switch self {
        case .ATC, .TRS, .FOR, .LCL, .MUL, .STG, .ESR, .LSC:
            return APP_THEME.SUCCESS
        case .EQO, .MNT:
            return APP_THEME.WARNING
        case .SAL, .PMC, .ADM, .FIN, .SAF, .TEC:
            return APP_THEME.INFO
        }
    }
}
