import SwiftUI
import SwiftData

@Model
final class SCHEDULED_JOB {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - JOB REFERENCE
    var workOrderID: UUID? // Link to work order
    var proposalID: UUID? // Link to proposal
    var leadID: UUID? // Link to lead (for site visits)

    // MARK: - SCHEDULE
    var scheduledDate: Date
    var scheduledStartTime: Date
    var scheduledEndTime: Date
    var estimatedDuration: Double // Hours

    // MARK: - ACTUAL TIMING
    var actualStartTime: Date?
    var actualEndTime: Date?
    var actualDuration: Double?

    // MARK: - CUSTOMER & LOCATION
    var customerID: UUID?
    var customerName: String
    var propertyID: UUID?
    var propertyAddress: String
    var latitude: Double
    var longitude: Double

    // MARK: - SERVICE DETAILS
    var serviceTypes: [String] // SERVICE_TYPE raw values
    var jobDescription: String
    var estimatedTreeScore: Double?

    // MARK: - CREW ASSIGNMENT
    var assignedEmployeeIDs: [String] // Employee UUIDs
    var crewLeadID: UUID?
    var totalCrewCost: Double // Sum of all crew hourly costs

    // MARK: - EQUIPMENT ASSIGNMENT
    var assignedEquipmentIDs: [String] // Equipment UUIDs
    var totalEquipmentCost: Double // Sum of all equipment hourly costs

    // MARK: - STATUS
    var jobStatus: String // "Scheduled", "In Progress", "Completed", "Cancelled", "Rescheduled"
    var priority: String // "Low", "Medium", "High", "Emergency"

    // MARK: - NOTES
    var specialInstructions: String?
    var accessNotes: String?
    var hazardNotes: String?

    // MARK: - INITIALIZER
    init(
        scheduledDate: Date,
        scheduledStartTime: Date,
        scheduledEndTime: Date,
        customerName: String,
        propertyAddress: String,
        latitude: Double,
        longitude: Double,
        serviceTypes: [SERVICE_TYPE],
        jobDescription: String
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // References
        self.workOrderID = nil
        self.proposalID = nil
        self.leadID = nil

        // Schedule
        self.scheduledDate = scheduledDate
        self.scheduledStartTime = scheduledStartTime
        self.scheduledEndTime = scheduledEndTime
        self.estimatedDuration = scheduledEndTime.timeIntervalSince(scheduledStartTime) / 3600.0

        // Actual timing
        self.actualStartTime = nil
        self.actualEndTime = nil
        self.actualDuration = nil

        // Customer & location
        self.customerID = nil
        self.customerName = customerName
        self.propertyID = nil
        self.propertyAddress = propertyAddress
        self.latitude = latitude
        self.longitude = longitude

        // Service
        self.serviceTypes = serviceTypes.map { $0.rawValue }
        self.jobDescription = jobDescription
        self.estimatedTreeScore = nil

        // Crew
        self.assignedEmployeeIDs = []
        self.crewLeadID = nil
        self.totalCrewCost = 0.0

        // Equipment
        self.assignedEquipmentIDs = []
        self.totalEquipmentCost = 0.0

        // Status
        self.jobStatus = "Scheduled"
        self.priority = "Medium"

        // Notes
        self.specialInstructions = nil
        self.accessNotes = nil
        self.hazardNotes = nil
    }

    // MARK: - COMPUTED PROPERTIES
    var isToday: Bool {
        Calendar.current.isDateInToday(scheduledDate)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(scheduledDate)
    }

    var isPast: Bool {
        scheduledDate < Date()
    }

    var isInProgress: Bool {
        jobStatus == "In Progress"
    }

    var isCompleted: Bool {
        jobStatus == "Completed"
    }

    var totalEstimatedCost: Double {
        (totalCrewCost + totalEquipmentCost) * estimatedDuration
    }

    var totalActualCost: Double? {
        guard let duration = actualDuration else { return nil }
        return (totalCrewCost + totalEquipmentCost) * duration
    }

    var crewCount: Int {
        assignedEmployeeIDs.count
    }

    var equipmentCount: Int {
        assignedEquipmentIDs.count
    }

    // MARK: - METHODS
    func startJob() {
        actualStartTime = Date()
        jobStatus = "In Progress"
        lastModifiedDate = Date()
    }

    func completeJob() {
        actualEndTime = Date()
        if let start = actualStartTime {
            actualDuration = Date().timeIntervalSince(start) / 3600.0
        }
        jobStatus = "Completed"
        lastModifiedDate = Date()
    }

    func cancelJob(reason: String?) {
        jobStatus = "Cancelled"
        specialInstructions = reason
        lastModifiedDate = Date()
    }

    func reschedule(newDate: Date, newStart: Date, newEnd: Date) {
        scheduledDate = newDate
        scheduledStartTime = newStart
        scheduledEndTime = newEnd
        estimatedDuration = newEnd.timeIntervalSince(newStart) / 3600.0
        jobStatus = "Rescheduled"
        lastModifiedDate = Date()
    }
}
