import SwiftUI

// MARK: - WORKFLOW STAGES

enum WORKFLOW_STAGE: String, Codable, CaseIterable {
    case LEAD = "LEAD"
    case PROPOSAL = "PROPOSAL"
    case WORK_ORDER = "WORK_ORDER"
    case INVOICE = "INVOICE"
    case COMPLETED = "COMPLETED"

    var displayName: String {
        switch self {
        case .LEAD: return "Lead"
        case .PROPOSAL: return "Proposal"
        case .WORK_ORDER: return "Work Order"
        case .INVOICE: return "Invoice"
        case .COMPLETED: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .LEAD: return WORKFLOW_COLORS.LEAD
        case .PROPOSAL: return WORKFLOW_COLORS.PROPOSAL
        case .WORK_ORDER: return WORKFLOW_COLORS.WORK_ORDER
        case .INVOICE: return WORKFLOW_COLORS.INVOICE
        case .COMPLETED: return WORKFLOW_COLORS.COMPLETED
        }
    }

    var nextStage: WORKFLOW_STAGE? {
        switch self {
        case .LEAD: return .PROPOSAL
        case .PROPOSAL: return .WORK_ORDER
        case .WORK_ORDER: return .INVOICE
        case .INVOICE: return .COMPLETED
        case .COMPLETED: return nil
        }
    }
}

// MARK: - WORKFLOW COLORS

struct WORKFLOW_COLORS {
    // Distinct, professional colors for each workflow stage
    static let LEAD = Color(red: 0.2, green: 0.6, blue: 1.0)           // Bright Blue
    static let PROPOSAL = Color(red: 1.0, green: 0.6, blue: 0.0)       // Orange
    static let WORK_ORDER = Color(red: 0.4, green: 0.8, blue: 0.2)     // Green
    static let INVOICE = Color(red: 0.9, green: 0.2, blue: 0.4)        // Red/Pink
    static let COMPLETED = Color(red: 0.5, green: 0.5, blue: 0.5)      // Gray
}

// MARK: - APP THEME

struct APP_THEME {
    // Primary brand colors
    static let PRIMARY = Color(red: 0.1, green: 0.7, blue: 0.3)        // Tree Green
    static let SECONDARY = Color(red: 0.2, green: 0.2, blue: 0.2)      // Dark Gray
    static let ACCENT = Color(red: 0.9, green: 0.7, blue: 0.1)         // Gold

    // Background colors (Dark Mode Default)
    static let BG_PRIMARY = Color(red: 0.05, green: 0.05, blue: 0.05)  // Almost Black
    static let BG_SECONDARY = Color(red: 0.1, green: 0.1, blue: 0.1)   // Dark Gray
    static let BG_TERTIARY = Color(red: 0.15, green: 0.15, blue: 0.15) // Medium Dark

    // Text colors
    static let TEXT_PRIMARY = Color.white
    static let TEXT_SECONDARY = Color(white: 0.7)
    static let TEXT_TERTIARY = Color(white: 0.5)

    // Functional colors
    static let SUCCESS = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let WARNING = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let ERROR = Color(red: 1.0, green: 0.2, blue: 0.2)
    static let INFO = Color(red: 0.3, green: 0.6, blue: 1.0)

    // Spacing
    static let SPACING_XS: CGFloat = 4
    static let SPACING_SM: CGFloat = 8
    static let SPACING_MD: CGFloat = 16
    static let SPACING_LG: CGFloat = 24
    static let SPACING_XL: CGFloat = 32

    // Corner radius
    static let RADIUS_SM: CGFloat = 6
    static let RADIUS_MD: CGFloat = 12
    static let RADIUS_LG: CGFloat = 20

    // Shadows
    static let SHADOW_SM = Color.black.opacity(0.1)
    static let SHADOW_MD = Color.black.opacity(0.2)
    static let SHADOW_LG = Color.black.opacity(0.3)
}

// MARK: - SERVICE TYPES

enum SERVICE_TYPE: String, Codable, CaseIterable {
    case TREE_REMOVAL = "TREE_REMOVAL"
    case TREE_TRIMMING = "TREE_TRIMMING"
    case STUMP_GRINDING = "STUMP_GRINDING"
    case FORESTRY_MULCHING = "FORESTRY_MULCHING"
    case TREE_ASSESSMENT = "TREE_ASSESSMENT"
    case EMERGENCY_SERVICE = "EMERGENCY_SERVICE"

    var displayName: String {
        switch self {
        case .TREE_REMOVAL: return "Tree Removal"
        case .TREE_TRIMMING: return "Tree Trimming"
        case .STUMP_GRINDING: return "Stump Grinding"
        case .FORESTRY_MULCHING: return "Forestry Mulching"
        case .TREE_ASSESSMENT: return "Tree Assessment"
        case .EMERGENCY_SERVICE: return "Emergency Service"
        }
    }

    var icon: String {
        switch self {
        case .TREE_REMOVAL: return "tree.fill"
        case .TREE_TRIMMING: return "scissors"
        case .STUMP_GRINDING: return "circle.grid.cross.fill"
        case .FORESTRY_MULCHING: return "leaf.fill"
        case .TREE_ASSESSMENT: return "doc.text.magnifyingglass"
        case .EMERGENCY_SERVICE: return "exclamationmark.triangle.fill"
        }
    }
}
