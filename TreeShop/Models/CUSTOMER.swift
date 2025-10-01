import SwiftUI
import SwiftData

@Model
final class CUSTOMER {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - BASIC INFORMATION
    var customerName: String
    var customerType: String // "Residential", "Commercial", "Municipal", "HOA"
    var isPrimaryContact: Bool

    // MARK: - CONTACT INFORMATION
    var phoneNumber: String
    var phoneNumberAlt: String?
    var email: String?
    var emailAlt: String?
    var preferredContactMethod: String // "Phone", "Email", "Text"
    var preferredContactTime: String? // "Morning", "Afternoon", "Evening"

    // MARK: - ADDRESS
    var mailingAddress: String?
    var mailingCity: String?
    var mailingState: String?
    var mailingZip: String?

    // MARK: - RELATIONSHIPS
    var propertyIDs: [String] // UUIDs of properties owned
    var linkedLeadIDs: [String] // UUIDs of leads
    var linkedProposalIDs: [String] // UUIDs of proposals
    var linkedWorkOrderIDs: [String] // UUIDs of work orders
    var linkedInvoiceIDs: [String] // UUIDs of invoices

    // MARK: - BUSINESS INTELLIGENCE
    var totalJobsCompleted: Int
    var totalRevenue: Double
    var averageJobValue: Double
    var lifetimeValue: Double // CLV - Total profit from customer
    var firstJobDate: Date?
    var lastJobDate: Date?

    // MARK: - CUSTOMER STATUS
    var customerStatus: String // "Active", "Inactive", "VIP", "Archived"
    var isRepeatCustomer: Bool
    var customerSince: Date

    // MARK: - REFERRAL TRACKING
    var referredBy: String? // Customer ID or source name
    var hasReferredOthers: Bool
    var referralCount: Int
    var referralIDs: [String] // Customer IDs of people they referred

    // MARK: - PAYMENT & BILLING
    var paymentHistory: [String] // Payment record IDs
    var outstandingBalance: Double
    var creditStatus: String // "Good", "Warning", "Collections"
    var paymentTerms: String? // Custom terms if different from company default
    var requiresDepositUpfront: Bool

    // MARK: - COMMUNICATION LOG
    var lastContactDate: Date?
    var lastContactMethod: String?
    var lastContactNotes: String?
    var communicationLogIDs: [String] // Communication record IDs

    // MARK: - SATISFACTION & QUALITY
    var satisfactionScore: Double? // 1-5 stars average
    var reviewCount: Int
    var npsScore: Int? // Net Promoter Score (-100 to 100)
    var hasLeftReview: Bool
    var reviewURL: String?

    // MARK: - TAGS & CATEGORIZATION
    var tags: [String] // "VIP", "Price Sensitive", "Quality Focused", etc.
    var notes: String?

    // MARK: - MARKETING
    var marketingOptIn: Bool
    var emailMarketingOptIn: Bool
    var textMarketingOptIn: Bool
    var doNotContact: Bool

    // MARK: - INITIALIZER
    init(
        customerName: String,
        phoneNumber: String,
        email: String? = nil,
        customerType: CUSTOMER_TYPE = .RESIDENTIAL
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Basic info
        self.customerName = customerName
        self.customerType = customerType.rawValue
        self.isPrimaryContact = true

        // Contact
        self.phoneNumber = phoneNumber
        self.phoneNumberAlt = nil
        self.email = email
        self.emailAlt = nil
        self.preferredContactMethod = "Phone"
        self.preferredContactTime = nil

        // Mailing address
        self.mailingAddress = nil
        self.mailingCity = nil
        self.mailingState = nil
        self.mailingZip = nil

        // Relationships
        self.propertyIDs = []
        self.linkedLeadIDs = []
        self.linkedProposalIDs = []
        self.linkedWorkOrderIDs = []
        self.linkedInvoiceIDs = []

        // Business intelligence
        self.totalJobsCompleted = 0
        self.totalRevenue = 0.0
        self.averageJobValue = 0.0
        self.lifetimeValue = 0.0
        self.firstJobDate = nil
        self.lastJobDate = nil

        // Status
        self.customerStatus = "Active"
        self.isRepeatCustomer = false
        self.customerSince = Date()

        // Referrals
        self.referredBy = nil
        self.hasReferredOthers = false
        self.referralCount = 0
        self.referralIDs = []

        // Payment
        self.paymentHistory = []
        self.outstandingBalance = 0.0
        self.creditStatus = "Good"
        self.paymentTerms = nil
        self.requiresDepositUpfront = false

        // Communication
        self.lastContactDate = nil
        self.lastContactMethod = nil
        self.lastContactNotes = nil
        self.communicationLogIDs = []

        // Satisfaction
        self.satisfactionScore = nil
        self.reviewCount = 0
        self.npsScore = nil
        self.hasLeftReview = false
        self.reviewURL = nil

        // Tags
        self.tags = []
        self.notes = nil

        // Marketing
        self.marketingOptIn = true
        self.emailMarketingOptIn = true
        self.textMarketingOptIn = true
        self.doNotContact = false
    }

    // MARK: - COMPUTED PROPERTIES
    var propertyCount: Int {
        propertyIDs.count
    }

    var fullMailingAddress: String? {
        guard let address = mailingAddress,
              let city = mailingCity,
              let state = mailingState,
              let zip = mailingZip else {
            return nil
        }
        return "\(address), \(city), \(state) \(zip)"
    }

    var customerTypeEnum: CUSTOMER_TYPE {
        CUSTOMER_TYPE(rawValue: customerType) ?? .RESIDENTIAL
    }

    var isVIP: Bool {
        tags.contains("VIP") || lifetimeValue > 10000
    }

    // MARK: - METHODS
    func addJob(value: Double, date: Date) {
        totalJobsCompleted += 1
        totalRevenue += value

        if totalJobsCompleted > 0 {
            averageJobValue = totalRevenue / Double(totalJobsCompleted)
        }

        if firstJobDate == nil {
            firstJobDate = date
        }
        lastJobDate = date

        if totalJobsCompleted > 1 {
            isRepeatCustomer = true
        }

        lastModifiedDate = Date()
    }

    func addProperty(propertyID: UUID) {
        if !propertyIDs.contains(propertyID.uuidString) {
            propertyIDs.append(propertyID.uuidString)
            lastModifiedDate = Date()
        }
    }

    func logContact(method: String, notes: String?) {
        lastContactDate = Date()
        lastContactMethod = method
        lastContactNotes = notes
        lastModifiedDate = Date()
    }
}

// MARK: - CUSTOMER TYPE

enum CUSTOMER_TYPE: String, CaseIterable {
    case RESIDENTIAL = "Residential"
    case COMMERCIAL = "Commercial"
    case MUNICIPAL = "Municipal"
    case HOA = "HOA"
    case PROPERTY_MANAGEMENT = "Property Management"

    var displayName: String {
        self.rawValue
    }

    var icon: String {
        switch self {
        case .RESIDENTIAL: return "house.fill"
        case .COMMERCIAL: return "building.2.fill"
        case .MUNICIPAL: return "building.columns.fill"
        case .HOA: return "building.fill"
        case .PROPERTY_MANAGEMENT: return "building.2.crop.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .RESIDENTIAL: return APP_THEME.PRIMARY
        case .COMMERCIAL: return APP_THEME.INFO
        case .MUNICIPAL: return APP_THEME.WARNING
        case .HOA: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .PROPERTY_MANAGEMENT: return Color(red: 0.8, green: 0.5, blue: 0.2)
        }
    }
}
