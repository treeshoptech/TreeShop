import SwiftUI
import SwiftData
import MapKit

struct MAIN_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()
    @State private var isMenuOpen = false
    @State private var showingSearch = false
    @State private var showingEmployees = false
    @State private var showingProfile = false
    @State private var showingCompany = false
    @State private var showingCustomers = false
    @State private var showingProperties = false
    @State private var showingTrees = false
    @State private var showingEquipment = false
    @State private var showingCalendar = false
    @State private var showingTimeTracker = false
    @State private var showingReports = false
    @State private var showingSettings = false
    @State private var showingLeads = false
    @State private var showingAddLead = false
    @State private var showingProposals = false

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
            MASTER_MENU(
                isOpen: $isMenuOpen,
                showingEmployees: $showingEmployees,
                showingProfile: $showingProfile,
                showingCompany: $showingCompany,
                showingCustomers: $showingCustomers,
                showingProperties: $showingProperties,
                showingTrees: $showingTrees,
                showingEquipment: $showingEquipment,
                showingCalendar: $showingCalendar,
                showingTimeTracker: $showingTimeTracker,
                showingReports: $showingReports,
                showingSettings: $showingSettings,
                showingLeads: $showingLeads,
                showingAddLead: $showingAddLead,
                showingProposals: $showingProposals
            )

            // Address search overlay
            if showingSearch {
                ADDRESS_SEARCH_VIEW(isPresented: $showingSearch)
            }
        }
        .sheet(isPresented: $showingEmployees) {
            EMPLOYEES_VIEW()
        }
        .sheet(isPresented: $showingProfile) {
            USER_PROFILE_VIEW()
        }
        .sheet(isPresented: $showingCompany) {
            COMPANY_SETTINGS_VIEW()
        }
        .sheet(isPresented: $showingCustomers) {
            CUSTOMERS_VIEW()
        }
        .sheet(isPresented: $showingProperties) {
            PROPERTIES_VIEW()
        }
        .sheet(isPresented: $showingTrees) {
            TREES_VIEW()
        }
        .sheet(isPresented: $showingEquipment) {
            EQUIPMENT_VIEW()
        }
        .sheet(isPresented: $showingCalendar) {
            CALENDAR_VIEW()
        }
        .sheet(isPresented: $showingTimeTracker) {
            TIME_TRACKER_VIEW()
        }
        .sheet(isPresented: $showingReports) {
            REPORTS_VIEW()
        }
        .sheet(isPresented: $showingSettings) {
            SETTINGS_VIEW()
        }
        .sheet(isPresented: $showingLeads) {
            LEADS_LIST_VIEW()
        }
        .sheet(isPresented: $showingAddLead) {
            ADD_LEAD_FORM()
        }
        .sheet(isPresented: $showingProposals) {
            PROPOSALS_VIEW()
        }
        .onAppear {
            workflowManager.setContext(modelContext)
        }
        .onChange(of: showingEmployees) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingProfile) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingCompany) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingCustomers) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingProperties) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingTrees) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingEquipment) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingCalendar) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingTimeTracker) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingReports) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingSettings) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingLeads) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingAddLead) { _, newValue in
            if newValue { isMenuOpen = false }
        }
        .onChange(of: showingProposals) { _, newValue in
            if newValue { isMenuOpen = false }
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

// MARK: - LEAD DETAIL VIEW (Use Enhanced Version)

struct LEAD_DETAIL_VIEW: View {
    let lead: LEAD

    var body: some View {
        ENHANCED_LEAD_DETAIL_VIEW(lead: lead)
    }
}
