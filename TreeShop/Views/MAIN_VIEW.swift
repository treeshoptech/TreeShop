import SwiftUI
import SwiftData
import MapKit

struct MAIN_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()
    @State private var isMenuOpen = false
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            // Main map view with workflow pins
            WORKFLOW_MAP_VIEW()
                .ignoresSafeArea()

            // Floating toolbar (top right)
            VStack {
                HStack {
                    Spacer()

                    VStack(spacing: APP_THEME.SPACING_SM) {
                        // Menu button
                        Button(action: {
                            isMenuOpen.toggle()
                        }) {
                            Image(systemName: isMenuOpen ? "xmark.circle.fill" : "line.3.horizontal.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(APP_THEME.PRIMARY)
                                .clipShape(Circle())
                                .shadow(color: APP_THEME.SHADOW_MD, radius: 8)
                        }

                        // Search button
                        Button(action: {
                            showingSearch = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(APP_THEME.INFO)
                                .clipShape(Circle())
                                .shadow(color: APP_THEME.SHADOW_MD, radius: 8)
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }

                Spacer()
            }

            // Master menu overlay
            MASTER_MENU(isOpen: $isMenuOpen)

            // Address search overlay
            if showingSearch {
                ADDRESS_SEARCH_VIEW(isPresented: $showingSearch)
            }
        }
        .onAppear {
            workflowManager.setContext(modelContext)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - LEADS LIST VIEW

struct LEADS_LIST_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()
    @State private var selectedStage: WORKFLOW_STAGE? = nil
    @State private var searchText = ""
    @State private var showingAddLead = false

    var filteredLeads: [LEAD] {
        var leads = workflowManager.getActiveLeads()

        if let stage = selectedStage {
            leads = leads.filter { $0.currentStage == stage }
        }

        if !searchText.isEmpty {
            leads = workflowManager.searchLeads(query: searchText)
        }

        return leads
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: APP_THEME.SPACING_MD) {
                            ForEach(WORKFLOW_STAGE.allCases, id: \.self) { stage in
                                STAT_CARD(
                                    label: stage.displayName,
                                    value: "\(workflowManager.getLeadsByStage(stage).count)",
                                    change: nil,
                                    color: stage.color
                                )
                                .frame(width: 120)
                                .onTapGesture {
                                    selectedStage = selectedStage == stage ? nil : stage
                                }
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                    }

                    // Leads list
                    if filteredLeads.isEmpty {
                        EMPTY_STATE(
                            icon: "person.crop.circle.badge.plus",
                            title: "No Leads",
                            message: selectedStage == nil ?
                            "Start by adding your first lead" :
                            "No leads in \(selectedStage!.displayName) stage",
                            actionTitle: "Add Lead",
                            action: { showingAddLead = true }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                ForEach(filteredLeads) { lead in
                                    LEAD_CARD(lead: lead)
                                }
                            }
                            .padding(APP_THEME.SPACING_MD)
                        }
                    }
                }
            }
            .navigationTitle("Leads")
            .searchable(text: $searchText, prompt: "Search leads...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddLead = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(WORKFLOW_COLORS.LEAD)
                    }
                }
            }
            .sheet(isPresented: $showingAddLead) {
                ADD_LEAD_FORM()
            }
            .onAppear {
                workflowManager.setContext(modelContext)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - LEAD CARD

struct LEAD_CARD: View {
    @Environment(\.modelContext) private var modelContext
    let lead: LEAD

    var body: some View {
        NavigationLink(destination: LEAD_DETAIL_VIEW(lead: lead)) {
            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lead.customerName)
                            .font(.headline)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        Text(lead.propertyAddress)
                            .font(.subheadline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }

                    Spacer()

                    STATUS_BADGE(text: lead.currentStage.displayName, color: lead.stageColor)
                }

                // Info row
                HStack(spacing: APP_THEME.SPACING_MD) {
                    // Urgency
                    if let urgency = URGENCY_LEVEL(rawValue: lead.urgencyLevel) {
                        Label(urgency.displayName, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(urgency.color)
                    }

                    // Days old
                    Label("\(lead.daysSinceCreated)d", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)

                    // Services count
                    Label("\(lead.serviceTypes.count) services", systemImage: "tree.fill")
                        .font(.caption)
                        .foregroundColor(APP_THEME.PRIMARY)

                    Spacer()
                }

                // Follow-up indicator
                if lead.isOverdue {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(APP_THEME.ERROR)
                        Text("Overdue Follow-up")
                            .font(.caption)
                            .foregroundColor(APP_THEME.ERROR)
                    }
                }
            }
            .padding(APP_THEME.SPACING_MD)
            .background(APP_THEME.BG_SECONDARY)
            .cornerRadius(APP_THEME.RADIUS_MD)
        }
    }
}

// MARK: - LEAD DETAIL VIEW

struct LEAD_DETAIL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()
    let lead: LEAD

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Workflow progress
                    WORKFLOW_STAGE_INDICATOR(currentStage: lead.currentStage)

                    // Customer info
                    FORM_SECTION(title: "Customer", icon: "person.fill", color: WORKFLOW_COLORS.LEAD) {
                        DETAIL_ROW(icon: "person.fill", label: "Name", value: lead.customerName)
                        DETAIL_ROW(icon: "phone.fill", label: "Phone", value: lead.customerPhone)
                        if let email = lead.customerEmail {
                            DETAIL_ROW(icon: "envelope.fill", label: "Email", value: email)
                        }
                    }

                    // Property info
                    FORM_SECTION(title: "Property", icon: "map.fill", color: APP_THEME.PRIMARY) {
                        DETAIL_ROW(icon: "location.fill", label: "Address", value: lead.fullAddress)
                        if let acres = lead.propertyAcres {
                            DETAIL_ROW(icon: "map", label: "Acres", value: String(format: "%.2f", acres))
                        }
                    }

                    // Project details
                    FORM_SECTION(title: "Project", icon: "tree.fill", color: APP_THEME.SUCCESS) {
                        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                            Text(lead.projectDescription)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        }
                        .padding(APP_THEME.SPACING_MD)
                    }

                    // Actions
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        ACTION_BUTTON(
                            title: "Advance to Proposal",
                            icon: "arrow.right.circle.fill",
                            color: WORKFLOW_COLORS.PROPOSAL
                        ) {
                            workflowManager.advanceStage(lead)
                        }

                        ACTION_BUTTON(
                            title: "Call Customer",
                            icon: "phone.fill",
                            color: APP_THEME.INFO,
                            style: .OUTLINED
                        ) {
                            // Handle call
                        }

                        ACTION_BUTTON(
                            title: "Schedule Site Visit",
                            icon: "calendar.badge.plus",
                            color: APP_THEME.PRIMARY,
                            style: .OUTLINED
                        ) {
                            // Handle scheduling
                        }
                    }
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(lead.customerName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            workflowManager.setContext(modelContext)
        }
    }
}
