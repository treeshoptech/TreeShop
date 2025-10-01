import SwiftUI
import SwiftData
import CoreLocation

@Model
final class TIME_ENTRY {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date

    // MARK: - JOB ASSOCIATION
    var jobID: UUID? // Link to SCHEDULED_JOB or work order
    var proposalLineItemID: UUID? // Link to specific line item if billable

    // MARK: - TASK INFORMATION
    var taskType: String // "Support" or "Line Item"
    var taskCategory: String // For support: "Fuel Up", "Transport", etc. For line item: service type
    var taskDescription: String

    // MARK: - TIME TRACKING
    var startTime: Date
    var endTime: Date?
    var duration: Double // Hours (calculated when ended)
    var isPaused: Bool
    var pausedAt: Date?
    var totalPausedTime: Double // Subtract from duration

    // MARK: - LOCATION TRACKING
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?

    // MARK: - CREW ASSIGNMENT
    var assignedEmployeeIDs: [String] // Crew members working on this task
    var crewLeadID: UUID?

    // MARK: - PERFORMANCE TRACKING
    var pointsCompleted: Double? // TreeScore/TrimScore/StumpScore points
    var pphAchieved: Double? // Points per hour for this task

    // MARK: - BILLABILITY
    var isBillable: Bool
    var laborCost: Double // Crew cost for this task
    var equipmentCost: Double // Equipment cost for this task
    var totalCost: Double // Labor + Equipment

    // MARK: - PROJECT JOURNAL
    var notes: String?
    var challengesEncountered: String?
    var solutionsImplemented: String?
    var lessonsLearned: String?
    var voiceNoteURL: String?

    // MARK: - PHOTOS
    var photoURLs: [String]

    // MARK: - STATUS
    var isComplete: Bool
    var requiresReview: Bool

    // MARK: - INITIALIZER
    init(
        taskType: TASK_TYPE,
        taskCategory: String,
        taskDescription: String,
        isBillable: Bool = false
    ) {
        self.id = UUID()
        self.createdDate = Date()

        // Job association
        self.jobID = nil
        self.proposalLineItemID = nil

        // Task info
        self.taskType = taskType.rawValue
        self.taskCategory = taskCategory
        self.taskDescription = taskDescription

        // Time tracking
        self.startTime = Date()
        self.endTime = nil
        self.duration = 0.0
        self.isPaused = false
        self.pausedAt = nil
        self.totalPausedTime = 0.0

        // Location (will be set with GPS)
        self.startLatitude = nil
        self.startLongitude = nil
        self.endLatitude = nil
        self.endLongitude = nil

        // Crew
        self.assignedEmployeeIDs = []
        self.crewLeadID = nil

        // Performance
        self.pointsCompleted = nil
        self.pphAchieved = nil

        // Billability
        self.isBillable = isBillable
        self.laborCost = 0.0
        self.equipmentCost = 0.0
        self.totalCost = 0.0

        // Journal
        self.notes = nil
        self.challengesEncountered = nil
        self.solutionsImplemented = nil
        self.lessonsLearned = nil
        self.voiceNoteURL = nil

        // Photos
        self.photoURLs = []

        // Status
        self.isComplete = false
        self.requiresReview = false
    }

    // MARK: - METHODS
    func pause() {
        isPaused = true
        pausedAt = Date()
    }

    func resume() {
        if let pausedTime = pausedAt {
            totalPausedTime += Date().timeIntervalSince(pausedTime) / 3600.0
        }
        isPaused = false
        pausedAt = nil
    }

    func complete(location: CLLocationCoordinate2D? = nil) {
        if isPaused {
            resume()
        }

        endTime = Date()
        let elapsed = Date().timeIntervalSince(startTime) / 3600.0
        duration = elapsed - totalPausedTime

        if let coord = location {
            endLatitude = coord.latitude
            endLongitude = coord.longitude
        }

        // Calculate PpH if points were tracked
        if let points = pointsCompleted, duration > 0 {
            pphAchieved = points / duration
        }

        isComplete = true
    }

    func setLocation(start: CLLocationCoordinate2D) {
        startLatitude = start.latitude
        startLongitude = start.longitude
    }
}

// MARK: - TASK TYPE

enum TASK_TYPE: String, CaseIterable {
    case SUPPORT = "Support"
    case LINE_ITEM = "Line Item"

    var isBillable: Bool {
        self == .LINE_ITEM
    }
}

// MARK: - SUPPORT TASK CATEGORIES

enum SUPPORT_TASK: String, CaseIterable {
    case FUEL_UP = "Fuel Up"
    case TRANSPORT = "Transport"
    case MAINTENANCE = "Maintenance"
    case SAFETY_MEETING = "Safety Meeting"
    case SITE_WALKTHROUGH = "Site Walkthrough"
    case TRAINING = "Training"
    case STOP_WORK_PLAN = "Stop Work and Plan"

    var icon: String {
        switch self {
        case .FUEL_UP: return "fuelpump.fill"
        case .TRANSPORT: return "car.fill"
        case .MAINTENANCE: return "wrench.fill"
        case .SAFETY_MEETING: return "shield.fill"
        case .SITE_WALKTHROUGH: return "figure.walk"
        case .TRAINING: return "book.fill"
        case .STOP_WORK_PLAN: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .FUEL_UP: return Color(red: 0.9, green: 0.6, blue: 0.1)
        case .TRANSPORT: return APP_THEME.INFO
        case .MAINTENANCE: return APP_THEME.WARNING
        case .SAFETY_MEETING: return APP_THEME.ERROR
        case .SITE_WALKTHROUGH: return APP_THEME.PRIMARY
        case .TRAINING: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .STOP_WORK_PLAN: return APP_THEME.ERROR
        }
    }
}
