import SwiftUI
import SwiftData
import MapKit

@Model
final class LEAD {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - WORKFLOW STATUS
    var workflowStage: String // WORKFLOW_STAGE raw value
    var stageHistory: [STAGE_TRANSITION]

    // MARK: - CUSTOMER INFORMATION
    var customerID: UUID? // Link to existing CUSTOMER
    var customerName: String
    var customerPhone: String
    var customerEmail: String?
    var customerNotes: String?
    var isExistingCustomer: Bool
    var isRepeatCustomer: Bool

    // MARK: - PROPERTY LOCATION
    var propertyAddress: String
    var propertyCity: String
    var propertyState: String
    var propertyZip: String
    var latitude: Double
    var longitude: Double
    var propertyType: String? // Residential, Commercial, Municipal
    var propertyAcres: Double?

    // MARK: - SERVICE REQUEST
    var serviceTypes: [String] // SERVICE_TYPE raw values
    var urgencyLevel: String // Low, Medium, High, Emergency
    var preferredContactMethod: String // Phone, Email, Text
    var preferredSchedule: String? // ASAP, This Week, This Month, Flexible

    // MARK: - LEAD SOURCE
    var leadSource: String // Website, Referral, Drive-By, Repeat Customer, etc.
    var referralSource: String?
    var marketingCampaign: String?

    // MARK: - SITE VISIT
    var needsSiteVisit: Bool
    var siteVisitScheduled: Date?
    var siteVisitScheduledJobID: UUID? // Link to SCHEDULED_JOB
    var siteVisitCompleted: Date?
    var siteVisitNotes: String?
    var siteVisitAssignedTo: UUID? // Employee ID

    // MARK: - PROJECT DETAILS
    var projectDescription: String
    var estimatedTreeCount: Int?
    var hazardsIdentified: String?
    var accessConcerns: String?
    var equipmentNeeded: [String]?

    // MARK: - PHOTOS & MEDIA
    var photoURLs: [String]
    var documentURLs: [String]

    // MARK: - ASSIGNMENT
    var assignedTo: String? // User ID or employee code
    var assignedDate: Date?

    // MARK: - FINANCIAL
    var estimatedValue: Double?
    var quotedAmount: Double?
    var budgetRange: String? // Under $1k, $1k-$5k, $5k-$10k, $10k+

    // MARK: - FOLLOW UP
    var lastContactDate: Date?
    var nextFollowUpDate: Date?
    var followUpNotes: String?
    var attemptCount: Int

    // MARK: - STATUS FLAGS
    var isActive: Bool
    var isConverted: Bool
    var isArchived: Bool
    var lostReason: String?

    // MARK: - INITIALIZER
    init(
        customerName: String,
        customerPhone: String,
        customerEmail: String? = nil,
        propertyAddress: String,
        propertyCity: String,
        propertyState: String,
        propertyZip: String,
        latitude: Double,
        longitude: Double,
        serviceTypes: [SERVICE_TYPE],
        urgencyLevel: URGENCY_LEVEL = .MEDIUM,
        leadSource: LEAD_SOURCE,
        projectDescription: String,
        needsSiteVisit: Bool = true
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Workflow
        self.workflowStage = WORKFLOW_STAGE.LEAD.rawValue
        self.stageHistory = [STAGE_TRANSITION(
            fromStage: nil,
            toStage: WORKFLOW_STAGE.LEAD,
            timestamp: Date()
        )]

        // Customer
        self.customerID = nil
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.customerEmail = customerEmail
        self.customerNotes = nil
        self.isExistingCustomer = false
        self.isRepeatCustomer = false

        // Property
        self.propertyAddress = propertyAddress
        self.propertyCity = propertyCity
        self.propertyState = propertyState
        self.propertyZip = propertyZip
        self.latitude = latitude
        self.longitude = longitude
        self.propertyType = nil
        self.propertyAcres = nil

        // Service
        self.serviceTypes = serviceTypes.map { $0.rawValue }
        self.urgencyLevel = urgencyLevel.rawValue
        self.preferredContactMethod = CONTACT_METHOD.PHONE.rawValue
        self.preferredSchedule = nil

        // Lead source
        self.leadSource = leadSource.rawValue
        self.referralSource = nil
        self.marketingCampaign = nil

        // Site visit
        self.needsSiteVisit = needsSiteVisit
        self.siteVisitScheduled = nil
        self.siteVisitScheduledJobID = nil
        self.siteVisitCompleted = nil
        self.siteVisitNotes = nil
        self.siteVisitAssignedTo = nil

        // Project
        self.projectDescription = projectDescription
        self.estimatedTreeCount = nil
        self.hazardsIdentified = nil
        self.accessConcerns = nil
        self.equipmentNeeded = nil

        // Media
        self.photoURLs = []
        self.documentURLs = []

        // Assignment
        self.assignedTo = nil
        self.assignedDate = nil

        // Financial
        self.estimatedValue = nil
        self.quotedAmount = nil
        self.budgetRange = nil

        // Follow up
        self.lastContactDate = nil
        self.nextFollowUpDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        self.followUpNotes = nil
        self.attemptCount = 0

        // Status
        self.isActive = true
        self.isConverted = false
        self.isArchived = false
        self.lostReason = nil
    }

    // MARK: - COMPUTED PROPERTIES
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var currentStage: WORKFLOW_STAGE {
        WORKFLOW_STAGE(rawValue: workflowStage) ?? .LEAD
    }

    var stageColor: Color {
        currentStage.color
    }

    var fullAddress: String {
        "\(propertyAddress), \(propertyCity), \(propertyState) \(propertyZip)"
    }

    var daysSinceCreated: Int {
        Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
    }

    var isOverdue: Bool {
        guard let nextDate = nextFollowUpDate else { return false }
        return nextDate < Date()
    }
}

// MARK: - SUPPORTING TYPES

struct STAGE_TRANSITION: Codable {
    let fromStage: String?
    let toStage: String
    let timestamp: Date
    let notes: String?

    init(fromStage: WORKFLOW_STAGE?, toStage: WORKFLOW_STAGE, timestamp: Date, notes: String? = nil) {
        self.fromStage = fromStage?.rawValue
        self.toStage = toStage.rawValue
        self.timestamp = timestamp
        self.notes = notes
    }
}

enum URGENCY_LEVEL: String, Codable, CaseIterable {
    case LOW = "LOW"
    case MEDIUM = "MEDIUM"
    case HIGH = "HIGH"
    case EMERGENCY = "EMERGENCY"

    var displayName: String {
        switch self {
        case .LOW: return "Low"
        case .MEDIUM: return "Medium"
        case .HIGH: return "High"
        case .EMERGENCY: return "Emergency"
        }
    }

    var color: Color {
        switch self {
        case .LOW: return .green
        case .MEDIUM: return .orange
        case .HIGH: return .red
        case .EMERGENCY: return Color(red: 0.8, green: 0.0, blue: 0.0)
        }
    }
}

enum LEAD_SOURCE: String, Codable, CaseIterable {
    case WEBSITE = "WEBSITE"
    case REFERRAL = "REFERRAL"
    case DRIVE_BY = "DRIVE_BY"
    case REPEAT_CUSTOMER = "REPEAT_CUSTOMER"
    case GOOGLE = "GOOGLE"
    case SOCIAL_MEDIA = "SOCIAL_MEDIA"
    case DIRECT_MAIL = "DIRECT_MAIL"
    case YARD_SIGN = "YARD_SIGN"
    case OTHER = "OTHER"

    var displayName: String {
        switch self {
        case .WEBSITE: return "Website"
        case .REFERRAL: return "Referral"
        case .DRIVE_BY: return "Drive-By"
        case .REPEAT_CUSTOMER: return "Repeat Customer"
        case .GOOGLE: return "Google Search"
        case .SOCIAL_MEDIA: return "Social Media"
        case .DIRECT_MAIL: return "Direct Mail"
        case .YARD_SIGN: return "Yard Sign"
        case .OTHER: return "Other"
        }
    }
}

enum CONTACT_METHOD: String, Codable, CaseIterable {
    case PHONE = "PHONE"
    case EMAIL = "EMAIL"
    case TEXT = "TEXT"
    case ANY = "ANY"

    var displayName: String {
        switch self {
        case .PHONE: return "Phone Call"
        case .EMAIL: return "Email"
        case .TEXT: return "Text Message"
        case .ANY: return "Any Method"
        }
    }
}
