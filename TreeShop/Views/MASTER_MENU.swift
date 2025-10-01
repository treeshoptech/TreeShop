import SwiftUI

// MARK: - MENU LEVEL

enum MENU_LEVEL: Int {
    case LEVEL_1 = 1
    case LEVEL_2 = 2
    case LEVEL_3 = 3
}

// MARK: - MENU ITEM

struct MENU_ITEM: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: MENU_ACTION
    let badge: Int?
    let subItems: [MENU_ITEM]?

    init(
        title: String,
        icon: String,
        color: Color = APP_THEME.TEXT_PRIMARY,
        action: MENU_ACTION,
        badge: Int? = nil,
        subItems: [MENU_ITEM]? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.badge = badge
        self.subItems = subItems
    }
}

enum MENU_ACTION {
    case LEADS
    case PROPOSALS
    case WORK_ORDERS
    case INVOICES
    case CUSTOMERS
    case PROPERTIES
    case TREES
    case EMPLOYEES
    case EQUIPMENT
    case REPORTS
    case SETTINGS
    case PROFILE
    case COMPANY_SETTINGS
    case ADD_LEAD
    case ADD_CUSTOMER
    case QUICK_MEASUREMENT
    case TREE_ASSESSMENT
    case SEARCH
    case CALENDAR
    case NOTIFICATIONS
    case CUSTOM(String)
}

// MARK: - MASTER MENU

struct MASTER_MENU: View {
    @Binding var isOpen: Bool
    @Binding var showingEmployees: Bool
    @Binding var showingProfile: Bool
    @Binding var showingCompany: Bool
    @Binding var showingCustomers: Bool
    @Binding var showingProperties: Bool
    @Binding var showingTrees: Bool

    @State private var currentLevel: MENU_LEVEL = .LEVEL_1
    @State private var selectedItem: MENU_ITEM?
    @State private var navigationStack: [MENU_ITEM] = []

    let menuWidth: CGFloat = 320

    var body: some View {
        ZStack(alignment: .trailing) {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
                    .transition(.opacity)
            }

            // Menu container
            if isOpen {
                HStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        // Level 1 - Main Menu
                        if currentLevel == .LEVEL_1 {
                            MENU_LEVEL_1(
                                onItemSelected: { item in
                                    handleLevel1Selection(item)
                                },
                                onClose: { closeMenu() }
                            )
                            .transition(.move(edge: .trailing))
                        }

                        // Level 2 - Submenu
                        if currentLevel == .LEVEL_2, let item = selectedItem {
                            MENU_LEVEL_2(
                                parentItem: item,
                                onBack: { goBack() },
                                onItemSelected: { subItem in
                                    handleLevel2Selection(subItem)
                                }
                            )
                            .transition(.move(edge: .trailing))
                        }

                        // Level 3 - Detail Menu
                        if currentLevel == .LEVEL_3, let item = selectedItem {
                            MENU_LEVEL_3(
                                item: item,
                                onBack: { goBack() }
                            )
                            .transition(.move(edge: .trailing))
                        }
                    }
                    .frame(width: menuWidth)
                    .background(APP_THEME.BG_PRIMARY)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOpen)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: currentLevel)
    }

    private func handleLevel1Selection(_ item: MENU_ITEM) {
        if let subItems = item.subItems, !subItems.isEmpty {
            navigationStack.append(item)
            selectedItem = item
            currentLevel = .LEVEL_2
        } else {
            executeAction(item.action)
            closeMenu()
        }
    }

    private func handleLevel2Selection(_ item: MENU_ITEM) {
        if let subItems = item.subItems, !subItems.isEmpty {
            navigationStack.append(item)
            selectedItem = item
            currentLevel = .LEVEL_3
        } else {
            executeAction(item.action)
            closeMenu()
        }
    }

    private func goBack() {
        navigationStack.removeLast()

        if navigationStack.isEmpty {
            currentLevel = .LEVEL_1
            selectedItem = nil
        } else {
            currentLevel = MENU_LEVEL(rawValue: navigationStack.count) ?? .LEVEL_1
            selectedItem = navigationStack.last
        }
    }

    private func closeMenu() {
        isOpen = false
        currentLevel = .LEVEL_1
        selectedItem = nil
        navigationStack = []
    }

    private func executeAction(_ action: MENU_ACTION) {
        switch action {
        case .EMPLOYEES:
            showingEmployees = true
        case .PROFILE:
            showingProfile = true
        case .COMPANY_SETTINGS, .SETTINGS:
            showingCompany = true
        case .CUSTOMERS:
            showingCustomers = true
        case .PROPERTIES:
            showingProperties = true
        case .TREES:
            showingTrees = true
        default:
            print("Action not yet implemented: \(action)")
        }
    }
}

// MARK: - LEVEL 1 MENU

struct MENU_LEVEL_1: View {
    let onItemSelected: (MENU_ITEM) -> Void
    let onClose: () -> Void

    private let menuItems: [MENU_ITEM] = [
        MENU_ITEM(
            title: "Profile",
            icon: "person.crop.circle.fill",
            color: APP_THEME.WARNING,
            action: .PROFILE,
            subItems: []
        ),
        MENU_ITEM(
            title: "Leads",
            icon: "person.crop.circle.badge.plus",
            color: WORKFLOW_COLORS.LEAD,
            action: .LEADS,
            badge: 12,
            subItems: [
                MENU_ITEM(title: "Active Leads", icon: "circle.fill", action: .LEADS),
                MENU_ITEM(title: "Add New Lead", icon: "plus.circle.fill", action: .ADD_LEAD),
                MENU_ITEM(title: "Overdue Follow-ups", icon: "exclamationmark.triangle.fill", action: .LEADS),
                MENU_ITEM(title: "Site Visits Needed", icon: "car.fill", action: .LEADS)
            ]
        ),
        MENU_ITEM(
            title: "Proposals",
            icon: "doc.text",
            color: WORKFLOW_COLORS.PROPOSAL,
            action: .PROPOSALS,
            badge: 5,
            subItems: []
        ),
        MENU_ITEM(
            title: "Work Orders",
            icon: "checklist",
            color: WORKFLOW_COLORS.WORK_ORDER,
            action: .WORK_ORDERS,
            badge: 3,
            subItems: []
        ),
        MENU_ITEM(
            title: "Invoices",
            icon: "dollarsign.circle",
            color: WORKFLOW_COLORS.INVOICE,
            action: .INVOICES,
            subItems: []
        ),
        MENU_ITEM(
            title: "Customers",
            icon: "person.2.fill",
            action: .CUSTOMERS,
            subItems: []
        ),
        MENU_ITEM(
            title: "Properties",
            icon: "map",
            action: .PROPERTIES,
            subItems: []
        ),
        MENU_ITEM(
            title: "Trees",
            icon: "tree.fill",
            color: APP_THEME.PRIMARY,
            action: .TREES,
            subItems: []
        ),
        MENU_ITEM(
            title: "Employees",
            icon: "person.3.fill",
            action: .EMPLOYEES,
            subItems: []
        ),
        MENU_ITEM(
            title: "Equipment",
            icon: "wrench.and.screwdriver.fill",
            action: .EQUIPMENT,
            subItems: []
        ),
        MENU_ITEM(
            title: "Reports",
            icon: "chart.bar.fill",
            action: .REPORTS,
            subItems: []
        ),
        MENU_ITEM(
            title: "Settings",
            icon: "gearshape.fill",
            action: .SETTINGS,
            subItems: [
                MENU_ITEM(title: "Company Settings", icon: "building.2.fill", action: .COMPANY_SETTINGS),
                MENU_ITEM(title: "User Profile", icon: "person.circle.fill", action: .PROFILE)
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            MENU_HEADER(title: "TreeShop", onClose: onClose)

            // Quick actions
            QUICK_ACTIONS_BAR()

            // Menu items
            ScrollView {
                VStack(spacing: APP_THEME.SPACING_SM) {
                    ForEach(menuItems) { item in
                        MENU_ITEM_ROW(item: item) {
                            onItemSelected(item)
                        }
                    }
                }
                .padding(APP_THEME.SPACING_MD)
            }

            Spacer()
        }
    }
}

// MARK: - LEVEL 2 MENU

struct MENU_LEVEL_2: View {
    let parentItem: MENU_ITEM
    let onBack: () -> Void
    let onItemSelected: (MENU_ITEM) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            MENU_HEADER_WITH_BACK(title: parentItem.title, onBack: onBack)

            // Submenu items
            ScrollView {
                VStack(spacing: APP_THEME.SPACING_SM) {
                    if let subItems = parentItem.subItems {
                        ForEach(subItems) { item in
                            MENU_ITEM_ROW(item: item) {
                                onItemSelected(item)
                            }
                        }
                    }
                }
                .padding(APP_THEME.SPACING_MD)
            }

            Spacer()
        }
    }
}

// MARK: - LEVEL 3 MENU

struct MENU_LEVEL_3: View {
    let item: MENU_ITEM
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MENU_HEADER_WITH_BACK(title: item.title, onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                    Text("Level 3 Content")
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
                .padding(APP_THEME.SPACING_MD)
            }

            Spacer()
        }
    }
}

// MARK: - MENU COMPONENTS

struct MENU_HEADER: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
    }
}

struct MENU_HEADER_WITH_BACK: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(APP_THEME.PRIMARY)
            }

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            Spacer()
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
    }
}

struct MENU_ITEM_ROW: View {
    let item: MENU_ITEM
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: APP_THEME.SPACING_MD) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(item.color)
                    .frame(width: 28)

                Text(item.title)
                    .font(.body)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                Spacer()

                if let badge = item.badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.color)
                        .cornerRadius(12)
                }

                if item.subItems != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                }
            }
            .padding(APP_THEME.SPACING_MD)
            .background(APP_THEME.BG_SECONDARY)
            .cornerRadius(APP_THEME.RADIUS_MD)
        }
    }
}

struct QUICK_ACTIONS_BAR: View {
    var body: some View {
        HStack(spacing: APP_THEME.SPACING_MD) {
            QUICK_ACTION_BUTTON(icon: "plus.circle.fill", color: WORKFLOW_COLORS.LEAD) {
                print("Quick add lead")
            }

            QUICK_ACTION_BUTTON(icon: "magnifyingglass", color: APP_THEME.INFO) {
                print("Search")
            }

            QUICK_ACTION_BUTTON(icon: "calendar", color: APP_THEME.WARNING) {
                print("Calendar")
            }

            QUICK_ACTION_BUTTON(icon: "bell.fill", color: APP_THEME.ERROR, badge: 3) {
                print("Notifications")
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
    }
}

struct QUICK_ACTION_BUTTON: View {
    let icon: String
    let color: Color
    var badge: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(APP_THEME.RADIUS_MD)

                if let badge = badge, badge > 0 {
                    Circle()
                        .fill(APP_THEME.ERROR)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Text("\(badge)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}
