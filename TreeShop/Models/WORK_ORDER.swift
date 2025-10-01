import SwiftUI
import SwiftData

@Model
final class WORK_ORDER {
    // MARK: - IDENTIFICATION
    var id: UUID
    var workOrderNumber: String // e.g., "WO-2025-001"
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - REFERENCES
    var proposalID: UUID
    var leadID: UUID?
    var customerID: UUID?
    var propertyID: UUID?

    // MARK: - CUSTOMER INFO
    var customerName: String
    var customerPhone: String
    var propertyAddress: String

    // MARK: - JOB DETAILS
    var jobDescription: String
    var serviceTypes: [String] // SERVICE_TYPE raw values
    var lineItems: [WORK_ORDER_LINE_ITEM]

    // MARK: - SCHEDULING
    var scheduledDate: Date?
    var scheduledJobID: UUID? // Link to SCHEDULED_JOB
    var actualStartDate: Date?
    var actualEndDate: Date?
    var estimatedDuration: Double // Hours from proposal
    var actualDuration: Double? // Calculated from time entries

    // MARK: - CREW ASSIGNMENT
    var assignedEmployeeIDs: [String] // Employee UUIDs
    var crewLeadID: UUID?
    var crewSize: Int

    // MARK: - EQUIPMENT ASSIGNMENT
    var assignedEquipmentIDs: [String] // Equipment UUIDs

    // MARK: - TIME TRACKING
    var timeEntryIDs: [String] // TIME_ENTRY UUIDs
    var totalHoursTracked: Double
    var totalLaborCost: Double
    var totalEquipmentCost: Double

    // MARK: - STATUS
    var workOrderStatus: String // "Scheduled", "In Progress", "Completed", "On Hold", "Cancelled"
    var priority: String // "Low", "Medium", "High", "Emergency"
    var completionPercentage: Int // 0-100

    // MARK: - SAFETY & HAZARDS
    var hazardsIdentified: [String]
    var safetyProtocols: [String]
    var requiredPPE: [String]

    // MARK: - PROJECT JOURNAL
    var journalEntries: [PROJECT_JOURNAL_ENTRY]
    var challengesEncountered: String?
    var solutionsImplemented: String?
    var lessonsLearned: String?

    // MARK: - PHOTOS
    var beforePhotoURLs: [String]
    var duringPhotoURLs: [String]
    var afterPhotoURLs: [String]

    // MARK: - PERFORMANCE
    var estimatedTotalCost: Double // From proposal
    var actualTotalCost: Double? // From time tracking
    var estimatedPpH: Double? // Expected points per hour
    var actualPpH: Double? // Achieved points per hour
    var performanceVariance: Double? // Actual vs. Estimated

    // MARK: - CONVERSION
    var convertedToInvoice: Bool
    var invoiceID: UUID?
    var invoiceCreatedDate: Date?

    // MARK: - INITIALIZER
    init(
        proposalID: UUID,
        customerName: String,
        customerPhone: String,
        propertyAddress: String,
        jobDescription: String,
        serviceTypes: [SERVICE_TYPE],
        lineItems: [WORK_ORDER_LINE_ITEM],
        estimatedDuration: Double
    ) {
        self.id = UUID()

        // Generate work order number
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        self.workOrderNumber = "WO-\(dateString)-\(UUID().uuidString.prefix(4))"

        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // References
        self.proposalID = proposalID
        self.leadID = nil
        self.customerID = nil
        self.propertyID = nil

        // Customer
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.propertyAddress = propertyAddress

        // Job details
        self.jobDescription = jobDescription
        self.serviceTypes = serviceTypes.map { $0.rawValue }
        self.lineItems = lineItems

        // Scheduling
        self.scheduledDate = nil
        self.scheduledJobID = nil
        self.actualStartDate = nil
        self.actualEndDate = nil
        self.estimatedDuration = estimatedDuration
        self.actualDuration = nil

        // Crew
        self.assignedEmployeeIDs = []
        self.crewLeadID = nil
        self.crewSize = 0

        // Equipment
        self.assignedEquipmentIDs = []

        // Time tracking
        self.timeEntryIDs = []
        self.totalHoursTracked = 0.0
        self.totalLaborCost = 0.0
        self.totalEquipmentCost = 0.0

        // Status
        self.workOrderStatus = "Scheduled"
        self.priority = "Medium"
        self.completionPercentage = 0

        // Safety
        self.hazardsIdentified = []
        self.safetyProtocols = []
        self.requiredPPE = []

        // Journal
        self.journalEntries = []
        self.challengesEncountered = nil
        self.solutionsImplemented = nil
        self.lessonsLearned = nil

        // Photos
        self.beforePhotoURLs = []
        self.duringPhotoURLs = []
        self.afterPhotoURLs = []

        // Performance
        self.estimatedTotalCost = lineItems.reduce(0.0) { $0 + $1.estimatedCost }
        self.actualTotalCost = nil
        self.estimatedPpH = nil
        self.actualPpH = nil
        self.performanceVariance = nil

        // Conversion
        self.convertedToInvoice = false
        self.invoiceID = nil
        self.invoiceCreatedDate = nil
    }

    // MARK: - METHODS
    func startWork() {
        workOrderStatus = "In Progress"
        actualStartDate = Date()
        lastModifiedDate = Date()
    }

    func completeWork() {
        workOrderStatus = "Completed"
        actualEndDate = Date()
        completionPercentage = 100

        if let start = actualStartDate {
            actualDuration = Date().timeIntervalSince(start) / 3600.0
        }

        lastModifiedDate = Date()
    }

    func assignCrew(employeeIDs: [UUID], leadID: UUID?) {
        self.assignedEmployeeIDs = employeeIDs.map { $0.uuidString }
        self.crewLeadID = leadID
        self.crewSize = employeeIDs.count
        lastModifiedDate = Date()
    }

    func assignEquipment(equipmentIDs: [UUID]) {
        self.assignedEquipmentIDs = equipmentIDs.map { $0.uuidString }
        lastModifiedDate = Date()
    }

    func addTimeEntry(timeEntryID: UUID, hours: Double, laborCost: Double, equipmentCost: Double) {
        timeEntryIDs.append(timeEntryID.uuidString)
        totalHoursTracked += hours
        totalLaborCost += laborCost
        totalEquipmentCost += equipmentCost
        actualTotalCost = totalLaborCost + totalEquipmentCost

        // Update completion percentage based on hours
        if estimatedDuration > 0 {
            completionPercentage = min(100, Int((totalHoursTracked / estimatedDuration) * 100))
        }

        lastModifiedDate = Date()
    }

    func addJournalEntry(entry: PROJECT_JOURNAL_ENTRY) {
        journalEntries.append(entry)
        lastModifiedDate = Date()
    }
}

// MARK: - WORK ORDER LINE ITEM

struct WORK_ORDER_LINE_ITEM: Codable, Identifiable {
    var id: UUID
    var proposalLineItemID: UUID // Link back to proposal
    var serviceType: String
    var description: String
    var estimatedHours: Double
    var estimatedCost: Double

    // Performance tracking
    var actualHours: Double?
    var actualCost: Double?
    var status: String // "Pending", "In Progress", "Completed"
    var assignedToEmployeeIDs: [String]

    // TreeScore tracking
    var treeScorePoints: Double?
    var treeIDs: [String]

    init(from proposalItem: PROPOSAL_LINE_ITEM) {
        self.id = UUID()
        self.proposalLineItemID = proposalItem.id
        self.serviceType = proposalItem.serviceType
        self.description = proposalItem.description
        self.estimatedHours = proposalItem.estimatedHours
        self.estimatedCost = proposalItem.totalPrice
        self.actualHours = nil
        self.actualCost = nil
        self.status = "Pending"
        self.assignedToEmployeeIDs = []
        self.treeScorePoints = proposalItem.treeScorePoints
        self.treeIDs = proposalItem.treeIDs
    }
}

// MARK: - PROJECT JOURNAL ENTRY

struct PROJECT_JOURNAL_ENTRY: Codable, Identifiable {
    var id: UUID
    var timestamp: Date
    var entryType: String // "Challenge", "Solution", "Lesson", "Note", "Incident"
    var title: String
    var description: String
    var authorID: UUID? // Employee who made entry
    var photoURLs: [String]
    var voiceNoteURL: String?

    init(entryType: String, title: String, description: String, authorID: UUID? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.entryType = entryType
        self.title = title
        self.description = description
        self.authorID = authorID
        self.photoURLs = []
        self.voiceNoteURL = nil
    }
}
