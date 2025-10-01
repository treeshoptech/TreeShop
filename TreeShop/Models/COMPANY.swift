import SwiftUI
import SwiftData

@Model
final class COMPANY {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - BASIC INFORMATION
    var companyName: String
    var businessAddress: String
    var city: String
    var state: String
    var zipCode: String
    var phoneNumber: String
    var email: String
    var website: String?

    // MARK: - BUSINESS DETAILS
    var licenseNumber: String?
    var insuranceProvider: String?
    var insurancePolicyNumber: String?
    var taxID: String? // EIN

    // MARK: - BRANDING
    var logoURL: String?
    var primaryColor: String // Hex color
    var secondaryColor: String // Hex color

    // MARK: - SERVICE AREAS
    var serviceAreas: [String] // ZIP codes or city names
    var serviceRadius: Double // Miles from business address

    // MARK: - BUSINESS HOURS
    var mondayHours: String?
    var tuesdayHours: String?
    var wednesdayHours: String?
    var thursdayHours: String?
    var fridayHours: String?
    var saturdayHours: String?
    var sundayHours: String?

    // MARK: - FINANCIAL SETTINGS
    var defaultProfitMarginRemoval: Double
    var defaultProfitMarginTrimming: Double
    var defaultProfitMarginStumpGrinding: Double
    var defaultProfitMarginForestryMulching: Double
    var defaultProfitMarginAssessment: Double
    var defaultProfitMarginEmergency: Double

    var taxRate: Double
    var paymentTerms: String // e.g., "Net 30", "Due on receipt"
    var latePaymentFeePercentage: Double

    // MARK: - LABOR SETTINGS
    var defaultLaborBurdenMultiplier: Double // 1.6 to 2.2
    var minimumWage: Double
    var overtimeThreshold: Double // Hours before overtime kicks in
    var overtimeMultiplier: Double // 1.5x typical

    // MARK: - EQUIPMENT SETTINGS
    var currentFuelPricePerGallon: Double
    var materialMarkupPercentage: Double

    // MARK: - SUBSCRIPTION
    var subscriptionTier: String // "Free", "Pro", "Team", "Enterprise"
    var subscriptionStatus: String // "Active", "Trial", "Expired", "Cancelled"
    var subscriptionStartDate: Date?
    var subscriptionEndDate: Date?
    var maxUsers: Int
    var currentUserCount: Int

    // MARK: - COMPANY PREFERENCES
    var useMetricUnits: Bool
    var defaultMapType: String // "standard", "satellite", "hybrid"
    var enableAFISSSystem: Bool
    var enablePpHTracking: Bool
    var enableTimeTracking: Bool
    var autoBackupEnabled: Bool
    var cloudSyncEnabled: Bool

    // MARK: - INITIALIZER
    init(
        companyName: String,
        businessAddress: String,
        city: String,
        state: String,
        zipCode: String,
        phoneNumber: String,
        email: String
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Basic info
        self.companyName = companyName
        self.businessAddress = businessAddress
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.phoneNumber = phoneNumber
        self.email = email
        self.website = nil

        // Business details
        self.licenseNumber = nil
        self.insuranceProvider = nil
        self.insurancePolicyNumber = nil
        self.taxID = nil

        // Branding defaults
        self.logoURL = nil
        self.primaryColor = "#1ABC9C" // TreeShop green
        self.secondaryColor = "#34495E" // Dark gray

        // Service areas
        self.serviceAreas = [zipCode]
        self.serviceRadius = 50.0

        // Business hours (default to standard)
        self.mondayHours = "8:00 AM - 5:00 PM"
        self.tuesdayHours = "8:00 AM - 5:00 PM"
        self.wednesdayHours = "8:00 AM - 5:00 PM"
        self.thursdayHours = "8:00 AM - 5:00 PM"
        self.fridayHours = "8:00 AM - 5:00 PM"
        self.saturdayHours = "8:00 AM - 12:00 PM"
        self.sundayHours = "Closed"

        // Financial defaults (40% profit margin standard)
        self.defaultProfitMarginRemoval = 0.40
        self.defaultProfitMarginTrimming = 0.40
        self.defaultProfitMarginStumpGrinding = 0.40
        self.defaultProfitMarginForestryMulching = 0.40
        self.defaultProfitMarginAssessment = 0.50
        self.defaultProfitMarginEmergency = 0.50

        self.taxRate = 0.0 // Set based on location
        self.paymentTerms = "Due on receipt"
        self.latePaymentFeePercentage = 0.015 // 1.5% per month

        // Labor defaults
        self.defaultLaborBurdenMultiplier = 1.7
        self.minimumWage = 15.00
        self.overtimeThreshold = 40.0
        self.overtimeMultiplier = 1.5

        // Equipment defaults
        self.currentFuelPricePerGallon = 3.50
        self.materialMarkupPercentage = 0.15 // 15%

        // Subscription defaults (Free tier)
        self.subscriptionTier = "Free"
        self.subscriptionStatus = "Active"
        self.subscriptionStartDate = Date()
        self.subscriptionEndDate = nil
        self.maxUsers = 1
        self.currentUserCount = 1

        // Preferences defaults
        self.useMetricUnits = false
        self.defaultMapType = "standard"
        self.enableAFISSSystem = true
        self.enablePpHTracking = true
        self.enableTimeTracking = true
        self.autoBackupEnabled = true
        self.cloudSyncEnabled = true
    }

    // MARK: - COMPUTED PROPERTIES
    var fullAddress: String {
        "\(businessAddress), \(city), \(state) \(zipCode)"
    }

    var isSubscriptionActive: Bool {
        subscriptionStatus == "Active" || subscriptionStatus == "Trial"
    }

    var canAddMoreUsers: Bool {
        currentUserCount < maxUsers
    }

    var subscriptionDisplayName: String {
        switch subscriptionTier {
        case "Free": return "Free Tier"
        case "Pro": return "Pro ($29/month)"
        case "Team": return "Team ($99/month)"
        case "Enterprise": return "Enterprise (Custom)"
        default: return subscriptionTier
        }
    }
}

// MARK: - SUBSCRIPTION TIERS

enum SUBSCRIPTION_TIER: String, CaseIterable {
    case FREE = "Free"
    case PRO = "Pro"
    case TEAM = "Team"
    case ENTERPRISE = "Enterprise"

    var displayName: String {
        switch self {
        case .FREE: return "Free"
        case .PRO: return "Pro"
        case .TEAM: return "Team"
        case .ENTERPRISE: return "Enterprise"
        }
    }

    var price: String {
        switch self {
        case .FREE: return "$0"
        case .PRO: return "$29/month"
        case .TEAM: return "$99/month"
        case .ENTERPRISE: return "Custom"
        }
    }

    var maxUsers: Int {
        switch self {
        case .FREE: return 1
        case .PRO: return 1
        case .TEAM: return 5
        case .ENTERPRISE: return 999
        }
    }

    var features: [String] {
        switch self {
        case .FREE:
            return [
                "Up to 10 trees scored",
                "Up to 3 properties tracked",
                "Basic map tools",
                "No proposal generation",
                "No time tracking"
            ]
        case .PRO:
            return [
                "Unlimited trees and properties",
                "Full formula-based pricing",
                "Proposal and invoice generation",
                "Time tracking",
                "Priority support",
                "No watermarks",
                "Cloud sync"
            ]
        case .TEAM:
            return [
                "Everything in Pro",
                "Up to 5 crew member accounts",
                "Shared job calendar",
                "Team time tracking",
                "Admin dashboard",
                "Crew productivity reports"
            ]
        case .ENTERPRISE:
            return [
                "Everything in Team",
                "Unlimited users",
                "Custom integrations",
                "Dedicated support",
                "On-premise option",
                "White-label branding"
            ]
        }
    }
}
