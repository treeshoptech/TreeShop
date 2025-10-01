import SwiftUI
import SwiftData

@Model
final class USER_PROFILE {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - BASIC INFORMATION
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var profilePhotoURL: String?

    // MARK: - COMPANY ASSOCIATION
    var companyID: UUID? // Link to COMPANY
    var companyName: String? // Denormalized for quick access

    // MARK: - ROLE & PERMISSIONS
    var role: String // "Owner", "Admin", "Supervisor", "Crew Member", "Office Staff"
    var permissionLevel: Int // 1-5, higher = more access

    // MARK: - EMPLOYEE LINK
    var employeeID: UUID? // Link to EMPLOYEE if this user is crew
    var isCrewMember: Bool

    // MARK: - ACCOUNT STATUS
    var accountStatus: String // "Active", "Inactive", "Suspended"
    var lastLoginDate: Date?
    var loginCount: Int

    // MARK: - SUBSCRIPTION
    var subscriptionTier: String // Copied from company or individual
    var isTrialUser: Bool
    var trialEndDate: Date?

    // MARK: - PREFERENCES
    var preferredTheme: String // "dark", "light", "auto"
    var useMetricUnits: Bool
    var defaultMapType: String // "standard", "satellite", "hybrid"
    var notificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var pushNotificationsEnabled: Bool

    // MARK: - NOTIFICATION PREFERENCES
    var notifyOnNewLead: Bool
    var notifyOnProposalAccepted: Bool
    var notifyOnJobScheduled: Bool
    var notifyOnPaymentReceived: Bool
    var notifyOnTeamMessage: Bool

    // MARK: - PRIVACY & SECURITY
    var useBiometricAuth: Bool
    var requirePINOnLaunch: Bool
    var dataEncryptionEnabled: Bool
    var locationTrackingEnabled: Bool

    // MARK: - PERFORMANCE (if crew member)
    var averagePpH: Double? // Points per hour across all jobs
    var jobsCompleted: Int
    var totalHoursWorked: Double
    var customerSatisfactionScore: Double? // Average rating

    // MARK: - INITIALIZER
    init(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String,
        role: USER_ROLE = .CREW_MEMBER,
        companyID: UUID? = nil
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Basic info
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.profilePhotoURL = nil

        // Company
        self.companyID = companyID
        self.companyName = nil

        // Role & permissions
        self.role = role.rawValue
        self.permissionLevel = role.permissionLevel

        // Employee link
        self.employeeID = nil
        self.isCrewMember = false

        // Account status
        self.accountStatus = "Active"
        self.lastLoginDate = nil
        self.loginCount = 0

        // Subscription
        self.subscriptionTier = "Free"
        self.isTrialUser = false
        self.trialEndDate = nil

        // Preferences
        self.preferredTheme = "dark"
        self.useMetricUnits = false
        self.defaultMapType = "standard"
        self.notificationsEnabled = true
        self.emailNotificationsEnabled = true
        self.pushNotificationsEnabled = true

        // Notification preferences
        self.notifyOnNewLead = true
        self.notifyOnProposalAccepted = true
        self.notifyOnJobScheduled = true
        self.notifyOnPaymentReceived = true
        self.notifyOnTeamMessage = true

        // Privacy & security
        self.useBiometricAuth = false
        self.requirePINOnLaunch = false
        self.dataEncryptionEnabled = true
        self.locationTrackingEnabled = true

        // Performance
        self.averagePpH = nil
        self.jobsCompleted = 0
        self.totalHoursWorked = 0.0
        self.customerSatisfactionScore = nil
    }

    // MARK: - COMPUTED PROPERTIES
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var userRole: USER_ROLE {
        USER_ROLE(rawValue: role) ?? .CREW_MEMBER
    }

    var canManageCompany: Bool {
        permissionLevel >= 5
    }

    var canManageEmployees: Bool {
        permissionLevel >= 4
    }

    var canManageFinances: Bool {
        permissionLevel >= 4
    }

    var canViewReports: Bool {
        permissionLevel >= 3
    }

    var canCreateProposals: Bool {
        permissionLevel >= 2
    }

    var canEditJobs: Bool {
        permissionLevel >= 2
    }

    // MARK: - METHODS
    func recordLogin() {
        lastLoginDate = Date()
        loginCount += 1
        lastModifiedDate = Date()
    }

    func updatePerformance(pph: Double, hoursWorked: Double) {
        if let currentAvg = averagePpH {
            let totalPoints = currentAvg * totalHoursWorked
            let newPoints = pph * hoursWorked
            let newTotalHours = totalHoursWorked + hoursWorked
            averagePpH = (totalPoints + newPoints) / newTotalHours
        } else {
            averagePpH = pph
        }
        totalHoursWorked += hoursWorked
        lastModifiedDate = Date()
    }
}

// MARK: - USER ROLES

enum USER_ROLE: String, CaseIterable {
    case OWNER = "Owner"
    case ADMIN = "Admin"
    case SUPERVISOR = "Supervisor"
    case CREW_MEMBER = "Crew Member"
    case OFFICE_STAFF = "Office Staff"

    var permissionLevel: Int {
        switch self {
        case .OWNER: return 5
        case .ADMIN: return 4
        case .SUPERVISOR: return 3
        case .OFFICE_STAFF: return 2
        case .CREW_MEMBER: return 1
        }
    }

    var description: String {
        switch self {
        case .OWNER: return "Full access to all features and settings"
        case .ADMIN: return "Manage employees, finances, and operations"
        case .SUPERVISOR: return "Manage jobs, crews, and assignments"
        case .OFFICE_STAFF: return "Manage leads, proposals, and customer communications"
        case .CREW_MEMBER: return "View assigned jobs and track time"
        }
    }

    var color: Color {
        switch self {
        case .OWNER: return Color(red: 0.9, green: 0.7, blue: 0.1) // Gold
        case .ADMIN: return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
        case .SUPERVISOR: return Color(red: 0.2, green: 0.6, blue: 0.8) // Blue
        case .OFFICE_STAFF: return Color(red: 0.6, green: 0.4, blue: 0.8) // Purple
        case .CREW_MEMBER: return Color(red: 0.4, green: 0.8, blue: 0.4) // Green
        }
    }
}
