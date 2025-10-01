import SwiftUI
import SwiftData

struct ENHANCED_LEAD_DETAIL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var customers: [CUSTOMER]
    @Query private var employees: [EMPLOYEE]
    @State private var workflowManager = WORKFLOW_MANAGER()

    let lead: LEAD

    @State private var showingConvertToCustomer = false
    @State private var showingScheduleSiteVisit = false
    @State private var showingAssignEmployee = false
    @State private var showingCreateProposal = false

    var existingCustomer: CUSTOMER? {
        if let customerID = lead.customerID {
            return customers.first { $0.id == customerID }
        }
        // Try to match by phone
        return customers.first { $0.phoneNumber == lead.customerPhone }
    }

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Workflow progress
                    WORKFLOW_STAGE_INDICATOR(currentStage: lead.currentStage)

                    // Customer Intelligence
                    if let customer = existingCustomer {
                        FORM_SECTION(title: "Existing Customer", icon: "star.fill", color: APP_THEME.SUCCESS) {
                            NavigationLink(destination: CUSTOMER_DETAIL_VIEW(customer: customer)) {
                                VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(customer.customerName)
                                                .font(.headline)
                                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                            if customer.isRepeatCustomer {
                                                STATUS_BADGE(text: "Repeat Customer", color: APP_THEME.SUCCESS, size: .SMALL)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                    }

                                    Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

                                    HStack(spacing: APP_THEME.SPACING_LG) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Properties")
                                                .font(.caption)
                                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                            Text("\(customer.propertyCount)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(APP_THEME.INFO)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Jobs")
                                                .font(.caption)
                                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                            Text("\(customer.totalJobsCompleted)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(APP_THEME.PRIMARY)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Revenue")
                                                .font(.caption)
                                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                            Text("$\(Int(customer.totalRevenue))")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(APP_THEME.SUCCESS)
                                        }
                                    }
                                }
                                .padding(APP_THEME.SPACING_MD)
                            }
                        }
                    } else {
                        // New customer - offer to convert
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(APP_THEME.INFO)
                                Text("New Customer")
                                    .font(.headline)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)
                            }

                            Button(action: { showingConvertToCustomer = true }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Convert to Customer")
                                }
                                .foregroundColor(APP_THEME.PRIMARY)
                                .frame(maxWidth: .infinity)
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.PRIMARY.opacity(0.1))
                                .cornerRadius(APP_THEME.RADIUS_MD)
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                        .background(APP_THEME.BG_SECONDARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)
                    }

                    // Customer info
                    FORM_SECTION(title: "Contact Information", icon: "person.fill", color: WORKFLOW_COLORS.LEAD) {
                        DETAIL_ROW(icon: "person.fill", label: "Name", value: lead.customerName)
                        DETAIL_ROW(icon: "phone.fill", label: "Phone", value: lead.customerPhone)
                        if let email = lead.customerEmail {
                            DETAIL_ROW(icon: "envelope.fill", label: "Email", value: email)
                        }
                        DETAIL_ROW(icon: "bell.fill", label: "Preferred Contact", value: lead.preferredContactMethod)
                    }

                    // Property info
                    FORM_SECTION(title: "Property Location", icon: "map.fill", color: APP_THEME.PRIMARY) {
                        DETAIL_ROW(icon: "location.fill", label: "Address", value: lead.fullAddress)
                    }

                    // Project details
                    FORM_SECTION(title: "Project Details", icon: "tree.fill", color: APP_THEME.SUCCESS) {
                        if !lead.serviceTypes.isEmpty {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                                Text("Services Requested:")
                                    .font(.caption)
                                    .foregroundColor(APP_THEME.TEXT_TERTIARY)

                                ForEach(lead.serviceTypes, id: \.self) { serviceType in
                                    if let service = SERVICE_TYPE(rawValue: serviceType) {
                                        HStack {
                                            Image(systemName: service.icon)
                                                .foregroundColor(APP_THEME.PRIMARY)
                                            Text(service.displayName)
                                                .foregroundColor(APP_THEME.TEXT_PRIMARY)
                                        }
                                        .font(.subheadline)
                                    }
                                }
                            }
                            .padding(APP_THEME.SPACING_SM)
                        }

                        Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

                        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                            Text("Description:")
                                .font(.caption)
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)

                            Text(lead.projectDescription)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        }
                        .padding(APP_THEME.SPACING_SM)
                    }

                    // Site Visit
                    if lead.needsSiteVisit {
                        FORM_SECTION(title: "Site Visit", icon: "car.fill", color: APP_THEME.INFO) {
                            if let scheduledDate = lead.siteVisitScheduled {
                                DETAIL_ROW(
                                    icon: "calendar.badge.checkmark",
                                    label: "Scheduled",
                                    value: scheduledDate.formatted(date: .abbreviated, time: .shortened),
                                    color: APP_THEME.SUCCESS
                                )

                                if let completed = lead.siteVisitCompleted {
                                    DETAIL_ROW(
                                        icon: "checkmark.circle.fill",
                                        label: "Completed",
                                        value: completed.formatted(date: .abbreviated, time: .shortened),
                                        color: APP_THEME.SUCCESS
                                    )
                                } else {
                                    Button(action: { showingScheduleSiteVisit = true }) {
                                        HStack {
                                            Image(systemName: "calendar.badge.plus")
                                            Text("Reschedule")
                                        }
                                        .foregroundColor(APP_THEME.WARNING)
                                        .frame(maxWidth: .infinity)
                                        .padding(APP_THEME.SPACING_SM)
                                    }
                                }
                            } else {
                                VStack(spacing: APP_THEME.SPACING_SM) {
                                    Text("Site visit not scheduled")
                                        .font(.subheadline)
                                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                    Button(action: { showingScheduleSiteVisit = true }) {
                                        HStack {
                                            Image(systemName: "calendar.badge.plus")
                                            Text("Schedule Site Visit")
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(APP_THEME.SPACING_MD)
                                        .background(APP_THEME.INFO)
                                        .cornerRadius(APP_THEME.RADIUS_MD)
                                    }
                                }
                            }
                        }
                    }

                    // Assignment
                    if let assignedID = lead.assignedTo {
                        if let employee = employees.first(where: { $0.id.uuidString == assignedID }) {
                            FORM_SECTION(title: "Assigned To", icon: "person.crop.circle.fill", color: APP_THEME.WARNING) {
                                DETAIL_ROW(
                                    icon: "person.fill",
                                    label: "Sales Rep",
                                    value: employee.fullName,
                                    color: employee.careerTrack.color
                                )
                            }
                        }
                    } else {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Text("Not assigned")
                                .font(.subheadline)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)

                            Button(action: { showingAssignEmployee = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Assign to Employee")
                                }
                                .foregroundColor(APP_THEME.PRIMARY)
                                .frame(maxWidth: .infinity)
                                .padding(APP_THEME.SPACING_SM)
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                        .background(APP_THEME.BG_SECONDARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)
                    }

                    // Actions
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        if lead.currentStage == .LEAD {
                            ACTION_BUTTON(
                                title: "Create Proposal",
                                icon: "doc.badge.plus",
                                color: WORKFLOW_COLORS.PROPOSAL
                            ) {
                                showingCreateProposal = true
                            }
                        } else if lead.currentStage.nextStage != nil {
                            ACTION_BUTTON(
                                title: "Advance to \(lead.currentStage.nextStage!.displayName)",
                                icon: "arrow.right.circle.fill",
                                color: lead.currentStage.nextStage!.color
                            ) {
                                workflowManager.advanceStage(lead)
                            }
                        }

                        HStack(spacing: APP_THEME.SPACING_SM) {
                            ACTION_BUTTON(
                                title: "Call",
                                icon: "phone.fill",
                                color: APP_THEME.INFO,
                                style: .OUTLINED
                            ) {
                                // Handle call
                            }

                            ACTION_BUTTON(
                                title: "Email",
                                icon: "envelope.fill",
                                color: APP_THEME.INFO,
                                style: .OUTLINED
                            ) {
                                // Handle email
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(lead.customerName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConvertToCustomer) {
            CONVERT_LEAD_TO_CUSTOMER_VIEW(lead: lead)
        }
        .sheet(isPresented: $showingScheduleSiteVisit) {
            SCHEDULE_SITE_VISIT_VIEW(lead: lead)
        }
        .sheet(isPresented: $showingAssignEmployee) {
            ASSIGN_EMPLOYEE_VIEW(lead: lead)
        }
        .sheet(isPresented: $showingCreateProposal) {
            CREATE_PROPOSAL_VIEW(lead: lead)
        }
        .onAppear {
            workflowManager.setContext(modelContext)
        }
    }
}

// MARK: - CONVERT LEAD TO CUSTOMER

struct CONVERT_LEAD_TO_CUSTOMER_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let lead: LEAD

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(APP_THEME.SUCCESS)

                            Text("Convert to Customer")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                            Text("This will create a customer profile and link this lead")
                                .font(.subheadline)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                .multilineTextAlignment(.center)
                        }
                        .padding(APP_THEME.SPACING_LG)

                        FORM_SECTION(title: "Customer to Create", icon: "person.fill", color: APP_THEME.INFO) {
                            DETAIL_ROW(icon: "person.fill", label: "Name", value: lead.customerName)
                            DETAIL_ROW(icon: "phone.fill", label: "Phone", value: lead.customerPhone)
                            if let email = lead.customerEmail {
                                DETAIL_ROW(icon: "envelope.fill", label: "Email", value: email)
                            }
                        }

                        ACTION_BUTTON(
                            title: "Create Customer & Link Lead",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.SUCCESS
                        ) {
                            convertToCustomer()
                        }

                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Convert to Customer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    func convertToCustomer() {
        // Create new customer from lead
        let newCustomer = CUSTOMER(
            customerName: lead.customerName,
            phoneNumber: lead.customerPhone,
            email: lead.customerEmail,
            customerType: .RESIDENTIAL
        )

        // Link lead to customer
        lead.customerID = newCustomer.id
        lead.isExistingCustomer = true
        lead.lastModifiedDate = Date()

        // Add lead to customer's records
        newCustomer.linkedLeadIDs.append(lead.id.uuidString)

        modelContext.insert(newCustomer)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error converting to customer: \(error)")
        }
    }
}

// MARK: - SCHEDULE SITE VISIT

struct SCHEDULE_SITE_VISIT_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let lead: LEAD

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Site Visit Details", icon: "calendar", color: APP_THEME.INFO) {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(APP_THEME.PRIMARY)

                            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .tint(APP_THEME.PRIMARY)
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.BG_TERTIARY)
                                .cornerRadius(APP_THEME.RADIUS_SM)
                        }

                        ACTION_BUTTON(
                            title: "Schedule Site Visit",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.INFO
                        ) {
                            scheduleSiteVisit()
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Schedule Site Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func scheduleSiteVisit() {
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        if let scheduledDateTime = calendar.date(from: combined) {
            // Create scheduled job for site visit
            let siteVisitJob = SCHEDULED_JOB(
                scheduledDate: scheduledDateTime,
                scheduledStartTime: scheduledDateTime,
                scheduledEndTime: calendar.date(byAdding: .hour, value: 1, to: scheduledDateTime) ?? scheduledDateTime,
                customerName: lead.customerName,
                propertyAddress: lead.propertyAddress,
                latitude: lead.latitude,
                longitude: lead.longitude,
                serviceTypes: [],
                jobDescription: "Site Visit - \(lead.projectDescription)"
            )
            siteVisitJob.leadID = lead.id
            siteVisitJob.priority = lead.urgencyLevel

            // Update lead
            lead.siteVisitScheduled = scheduledDateTime
            lead.siteVisitScheduledJobID = siteVisitJob.id
            lead.lastModifiedDate = Date()

            modelContext.insert(siteVisitJob)

            do {
                try modelContext.save()
                dismiss()
            } catch {
                print("Error scheduling site visit: \(error)")
            }
        }
    }
}

// MARK: - ASSIGN EMPLOYEE

struct ASSIGN_EMPLOYEE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var employees: [EMPLOYEE]

    let lead: LEAD

    @State private var selectedEmployee: EMPLOYEE?

    var salesEmployees: [EMPLOYEE] {
        employees.filter {
            $0.employmentStatus == "Active" &&
            ($0.primaryTrack == CAREER_TRACK.SAL.rawValue || $0.primaryTrack == CAREER_TRACK.PMC.rawValue)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Assign Lead To", icon: "person.crop.circle.fill", color: APP_THEME.PRIMARY) {
                            if salesEmployees.isEmpty {
                                Text("No sales employees available")
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                    .padding(APP_THEME.SPACING_MD)
                            } else {
                                ForEach(salesEmployees) { employee in
                                    Button(action: {
                                        selectedEmployee = employee
                                    }) {
                                        HStack {
                                            Image(systemName: selectedEmployee?.id == employee.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedEmployee?.id == employee.id ? APP_THEME.PRIMARY : APP_THEME.TEXT_TERTIARY)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(employee.fullName)
                                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                                Text(employee.careerTrack.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                            }

                                            Spacer()
                                        }
                                        .padding(APP_THEME.SPACING_MD)
                                        .background(
                                            selectedEmployee?.id == employee.id ?
                                            APP_THEME.PRIMARY.opacity(0.1) :
                                            APP_THEME.BG_TERTIARY
                                        )
                                        .cornerRadius(APP_THEME.RADIUS_MD)
                                    }
                                }
                            }
                        }

                        ACTION_BUTTON(
                            title: "Assign Lead",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            assignEmployee()
                        }
                        .disabled(selectedEmployee == nil)
                        .opacity(selectedEmployee == nil ? 0.5 : 1.0)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Assign Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func assignEmployee() {
        guard let employee = selectedEmployee else { return }

        lead.assignedTo = employee.id.uuidString
        lead.assignedDate = Date()
        lead.lastModifiedDate = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error assigning employee: \(error)")
        }
    }
}
