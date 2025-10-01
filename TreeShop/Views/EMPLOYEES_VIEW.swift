import SwiftUI
import SwiftData

struct EMPLOYEES_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EMPLOYEE.lastName) private var employees: [EMPLOYEE]

    @State private var showingAddEmployee = false
    @State private var searchText = ""
    @State private var selectedTrackFilter: CAREER_TRACK?

    var filteredEmployees: [EMPLOYEE] {
        var result = employees

        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.lowercased().contains(searchText.lowercased()) ||
                $0.employeeCode.lowercased().contains(searchText.lowercased())
            }
        }

        if let track = selectedTrackFilter {
            result = result.filter { $0.primaryTrack == track.rawValue }
        }

        return result.filter { $0.employmentStatus == "Active" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Career track filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: APP_THEME.SPACING_SM) {
                            Button(action: { selectedTrackFilter = nil }) {
                                Text("All")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedTrackFilter == nil ? .white : APP_THEME.TEXT_SECONDARY)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTrackFilter == nil ? APP_THEME.PRIMARY : APP_THEME.BG_SECONDARY)
                                    .cornerRadius(16)
                            }

                            ForEach(CAREER_TRACK.allCases, id: \.self) { track in
                                Button(action: { selectedTrackFilter = track }) {
                                    Text(track.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedTrackFilter == track ? .white : APP_THEME.TEXT_SECONDARY)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedTrackFilter == track ? track.color : APP_THEME.BG_SECONDARY)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                    }
                    .background(APP_THEME.BG_SECONDARY)

                    if filteredEmployees.isEmpty {
                        EMPTY_STATE(
                            icon: "person.3.fill",
                            title: "No Employees",
                            message: searchText.isEmpty ?
                                "Add your first team member to get started" :
                                "No employees found matching '\(searchText)'",
                            actionTitle: searchText.isEmpty ? "Add Employee" : nil,
                            action: searchText.isEmpty ? { showingAddEmployee = true } : nil
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                ForEach(filteredEmployees) { employee in
                                    NavigationLink(destination: EMPLOYEE_DETAIL_VIEW(employee: employee)) {
                                        EMPLOYEE_CARD(employee: employee)
                                    }
                                }
                            }
                            .padding(APP_THEME.SPACING_MD)
                        }
                    }
                }
            }
            .navigationTitle("Employees")
            .searchable(text: $searchText, prompt: "Search employees...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEmployee = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddEmployee) {
                ADD_EMPLOYEE_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - EMPLOYEE CARD

struct EMPLOYEE_CARD: View {
    let employee: EMPLOYEE

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(employee.careerTrack.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(employee.firstName.prefix(1) + employee.lastName.prefix(1))
                        .font(.headline)
                        .foregroundColor(employee.careerTrack.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(employee.fullName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text(employee.careerTrack.displayName)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(employee.employeeCode)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(employee.careerTrack.color)

                    Text("Tier \(employee.tier)")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                }
            }

            Divider()
                .background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_LG) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wage")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("$\(String(format: "%.2f", employee.totalHourlyWage))/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(APP_THEME.SUCCESS)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("True Cost")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("$\(String(format: "%.2f", employee.trueBusinessCost))/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(APP_THEME.WARNING)
                }

                if employee.averagePpH > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg PpH")
                            .font(.caption)
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        Text("\(Int(employee.averagePpH))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(APP_THEME.INFO)
                    }
                }

                Spacer()

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

// MARK: - EMPLOYEE DETAIL VIEW

struct EMPLOYEE_DETAIL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    let employee: EMPLOYEE

    @State private var showingEdit = false

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Header
                    VStack(spacing: APP_THEME.SPACING_MD) {
                        ZStack {
                            Circle()
                                .fill(employee.careerTrack.color.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Text(employee.firstName.prefix(1) + employee.lastName.prefix(1))
                                .font(.system(size: 40))
                                .fontWeight(.bold)
                                .foregroundColor(employee.careerTrack.color)
                        }

                        Text(employee.fullName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        Text(employee.employeeCode)
                            .font(.headline)
                            .foregroundColor(employee.careerTrack.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(APP_THEME.SPACING_LG)

                    // Career Track
                    FORM_SECTION(title: "Career Track", icon: "star.fill", color: employee.careerTrack.color) {
                        DETAIL_ROW(icon: "briefcase.fill", label: "Track", value: employee.careerTrack.displayName, color: employee.careerTrack.color)
                        DETAIL_ROW(icon: "chart.bar.fill", label: "Tier", value: "Tier \(employee.tier)")
                        DETAIL_ROW(icon: "building.2.fill", label: "Category", value: employee.careerTrack.category)
                    }

                    // Compensation
                    FORM_SECTION(title: "Compensation", icon: "dollarsign.circle.fill", color: APP_THEME.SUCCESS) {
                        DETAIL_ROW(icon: "banknote.fill", label: "Base Rate", value: "$\(String(format: "%.2f", employee.baseHourlyRate))/hr")
                        DETAIL_ROW(icon: "arrow.up.circle.fill", label: "Total Wage", value: "$\(String(format: "%.2f", employee.totalHourlyWage))/hr", color: APP_THEME.SUCCESS)
                        DETAIL_ROW(icon: "building.columns.fill", label: "Burden Multiplier", value: "\(String(format: "%.1f", employee.laborBurdenMultiplier))x")
                        DETAIL_ROW(icon: "exclamationmark.triangle.fill", label: "True Business Cost", value: "$\(String(format: "%.2f", employee.trueBusinessCost))/hr", color: APP_THEME.WARNING)
                    }

                    // Premiums & Certifications
                    if employee.hasTeamLeader || employee.hasSupervisor || employee.equipmentLevel > 1 ||
                       employee.driverClass > 1 || employee.hasCraneCert || employee.hasISACert ||
                       employee.hasOSHACert || employee.hasHazmatCert {
                        FORM_SECTION(title: "Premiums & Certifications", icon: "medal.fill", color: APP_THEME.WARNING) {
                            if employee.hasSupervisor {
                                DETAIL_ROW(icon: "person.2.fill", label: "Supervisor", value: "+$7.00/hr")
                            }
                            if employee.hasTeamLeader {
                                DETAIL_ROW(icon: "person.fill", label: "Team Leader", value: "+$3.00/hr")
                            }
                            if employee.equipmentLevel > 1 {
                                DETAIL_ROW(icon: "wrench.fill", label: "Equipment Level", value: "E\(employee.equipmentLevel)")
                            }
                            if employee.driverClass > 1 {
                                DETAIL_ROW(icon: "car.fill", label: "Driver Class", value: "D\(employee.driverClass)")
                            }
                            if employee.hasCraneCert {
                                DETAIL_ROW(icon: "arrow.up.and.down.and.arrow.left.and.right", label: "Crane Certified", value: "+$4.00/hr")
                            }
                            if employee.hasISACert {
                                DETAIL_ROW(icon: "tree.fill", label: "ISA Certified", value: "+$2.50/hr")
                            }
                            if employee.hasOSHACert {
                                DETAIL_ROW(icon: "shield.fill", label: "OSHA Trainer", value: "+$2.00/hr")
                            }
                            if employee.hasHazmatCert {
                                DETAIL_ROW(icon: "exclamationmark.triangle.fill", label: "Hazmat Certified", value: "+$1.50/hr")
                            }
                        }
                    }

                    // Contact
                    FORM_SECTION(title: "Contact", icon: "phone.fill", color: APP_THEME.INFO) {
                        DETAIL_ROW(icon: "phone.fill", label: "Phone", value: employee.phoneNumber)
                        if let email = employee.email {
                            DETAIL_ROW(icon: "envelope.fill", label: "Email", value: email)
                        }
                    }

                    // Performance
                    if employee.jobsCompleted > 0 {
                        FORM_SECTION(title: "Performance", icon: "chart.line.uptrend.xyaxis.fill", color: APP_THEME.PRIMARY) {
                            DETAIL_ROW(icon: "checkmark.circle.fill", label: "Jobs Completed", value: "\(employee.jobsCompleted)")
                            DETAIL_ROW(icon: "clock.fill", label: "Hours Worked", value: String(format: "%.1f", employee.totalHoursWorked))
                            if employee.averagePpH > 0 {
                                DETAIL_ROW(icon: "bolt.fill", label: "Average PpH", value: "\(Int(employee.averagePpH))")
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(employee.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
                .foregroundColor(APP_THEME.PRIMARY)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EDIT_EMPLOYEE_VIEW(employee: employee)
        }
    }
}

// MARK: - ADD EMPLOYEE VIEW

struct ADD_EMPLOYEE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var selectedTrack: CAREER_TRACK = .TRS
    @State private var tier = 1
    @State private var baseHourlyRate = "15.00"

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Personal Information", icon: "person.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "First Name", text: $firstName, placeholder: "John")
                            TEXT_FIELD_ROW(title: "Last Name", text: $lastName, placeholder: "Doe")
                            TEXT_FIELD_ROW(title: "Phone", text: $phoneNumber, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                            TEXT_FIELD_ROW(title: "Email (Optional)", text: $email, placeholder: "john@company.com", keyboardType: .emailAddress)
                        }

                        FORM_SECTION(title: "Career Track", icon: "star.fill", color: APP_THEME.PRIMARY) {
                            Picker("Track", selection: $selectedTrack) {
                                ForEach(CAREER_TRACK.allCases, id: \.self) { track in
                                    Text(track.displayName).tag(track)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)

                            Picker("Tier", selection: $tier) {
                                ForEach(1...5, id: \.self) { tier in
                                    Text("Tier \(tier)").tag(tier)
                                }
                            }
                            .pickerStyle(.segmented)

                            TEXT_FIELD_ROW(title: "Base Hourly Rate", text: $baseHourlyRate, placeholder: "15.00", keyboardType: .decimalPad)
                        }

                        ACTION_BUTTON(
                            title: "Add Employee",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            addEmployee()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.large)
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

    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !phoneNumber.isEmpty &&
        Double(baseHourlyRate) != nil
    }

    func addEmployee() {
        guard let rate = Double(baseHourlyRate) else { return }

        let newEmployee = EMPLOYEE(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            hireDate: Date(),
            primaryTrack: selectedTrack,
            tier: tier,
            baseHourlyRate: rate
        )

        if !email.isEmpty {
            newEmployee.email = email
        }

        modelContext.insert(newEmployee)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding employee: \(error)")
        }
    }
}

// MARK: - EDIT EMPLOYEE VIEW (Simplified for now)

struct EDIT_EMPLOYEE_VIEW: View {
    @Environment(\.dismiss) private var dismiss
    let employee: EMPLOYEE

    var body: some View {
        Text("Edit Employee - Coming Soon")
            .foregroundColor(APP_THEME.TEXT_PRIMARY)
    }
}
