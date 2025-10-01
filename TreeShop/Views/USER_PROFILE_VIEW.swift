import SwiftUI
import SwiftData

struct USER_PROFILE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [USER_PROFILE]
    @Query private var companies: [COMPANY]

    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingCreateProfile = false

    var currentUser: USER_PROFILE? {
        users.first // For now, single user. Will add multi-user later
    }

    var userCompany: COMPANY? {
        companies.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                if let user = currentUser {
                    ScrollView {
                        VStack(spacing: APP_THEME.SPACING_LG) {
                            // Profile Header
                            VStack(spacing: APP_THEME.SPACING_MD) {
                                ZStack {
                                    Circle()
                                        .fill(user.userRole.color.opacity(0.2))
                                        .frame(width: 100, height: 100)

                                    Text(user.initials)
                                        .font(.system(size: 40))
                                        .fontWeight(.bold)
                                        .foregroundColor(user.userRole.color)
                                }

                                Text(user.fullName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                STATUS_BADGE(text: user.userRole.rawValue, color: user.userRole.color)

                                if let company = userCompany {
                                    Text(company.companyName)
                                        .font(.subheadline)
                                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(APP_THEME.SPACING_LG)

                            // Contact Information
                            FORM_SECTION(title: "Contact", icon: "phone.fill", color: APP_THEME.INFO) {
                                DETAIL_ROW(icon: "envelope.fill", label: "Email", value: user.email)
                                DETAIL_ROW(icon: "phone.fill", label: "Phone", value: user.phoneNumber)
                            }

                            // Account Information
                            FORM_SECTION(title: "Account", icon: "person.crop.circle.fill", color: APP_THEME.PRIMARY) {
                                DETAIL_ROW(icon: "crown.fill", label: "Subscription", value: user.subscriptionTier)
                                DETAIL_ROW(icon: "checkmark.circle.fill", label: "Status", value: user.accountStatus, color: user.accountStatus == "Active" ? APP_THEME.SUCCESS : APP_THEME.ERROR)
                                DETAIL_ROW(icon: "calendar.badge.clock", label: "Member Since", value: user.createdDate.formatted(date: .abbreviated, time: .omitted))
                                if let lastLogin = user.lastLoginDate {
                                    DETAIL_ROW(icon: "clock.fill", label: "Last Login", value: lastLogin.formatted(date: .abbreviated, time: .shortened))
                                }
                            }

                            // Performance (if crew member)
                            if user.isCrewMember && user.jobsCompleted > 0 {
                                FORM_SECTION(title: "Performance", icon: "chart.bar.fill", color: APP_THEME.SUCCESS) {
                                    DETAIL_ROW(icon: "checkmark.circle.fill", label: "Jobs Completed", value: "\(user.jobsCompleted)")
                                    DETAIL_ROW(icon: "clock.fill", label: "Hours Worked", value: String(format: "%.1f", user.totalHoursWorked))
                                    if let pph = user.averagePpH {
                                        DETAIL_ROW(icon: "bolt.fill", label: "Average PpH", value: "\(Int(pph))")
                                    }
                                    if let satisfaction = user.customerSatisfactionScore {
                                        DETAIL_ROW(icon: "star.fill", label: "Satisfaction", value: String(format: "%.1f/5.0", satisfaction))
                                    }
                                }
                            }

                            // Actions
                            VStack(spacing: APP_THEME.SPACING_SM) {
                                ACTION_BUTTON(
                                    title: "Edit Profile",
                                    icon: "pencil.circle.fill",
                                    color: APP_THEME.PRIMARY
                                ) {
                                    showingEditProfile = true
                                }

                                ACTION_BUTTON(
                                    title: "App Settings",
                                    icon: "gearshape.fill",
                                    color: APP_THEME.INFO,
                                    style: .OUTLINED
                                ) {
                                    showingSettings = true
                                }

                                if userCompany != nil {
                                    NavigationLink(destination: COMPANY_SETTINGS_VIEW()) {
                                        HStack(spacing: APP_THEME.SPACING_SM) {
                                            Image(systemName: "building.2.fill")
                                            Text("Company Settings")
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(APP_THEME.WARNING)
                                        .frame(maxWidth: .infinity)
                                        .padding(APP_THEME.SPACING_MD)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: APP_THEME.RADIUS_MD)
                                                .stroke(APP_THEME.WARNING, lineWidth: 2)
                                        )
                                        .cornerRadius(APP_THEME.RADIUS_MD)
                                    }
                                }
                            }
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                } else {
                    EMPTY_STATE(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "No User Profile",
                        message: "Please create a user profile to continue",
                        actionTitle: "Create Profile",
                        action: { showingCreateProfile = true }
                    )
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if let user = currentUser {
                    EDIT_USER_PROFILE_VIEW(user: user)
                }
            }
            .sheet(isPresented: $showingSettings) {
                APP_SETTINGS_VIEW()
            }
            .sheet(isPresented: $showingCreateProfile) {
                CREATE_USER_PROFILE_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - EDIT USER PROFILE VIEW

struct EDIT_USER_PROFILE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let user: USER_PROFILE

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phoneNumber: String

    init(user: USER_PROFILE) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _email = State(initialValue: user.email)
        _phoneNumber = State(initialValue: user.phoneNumber)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Personal Information", icon: "person.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "First Name", text: $firstName, placeholder: "First Name")
                            TEXT_FIELD_ROW(title: "Last Name", text: $lastName, placeholder: "Last Name")
                            TEXT_FIELD_ROW(title: "Email", text: $email, placeholder: "Email", keyboardType: .emailAddress)
                            TEXT_FIELD_ROW(title: "Phone", text: $phoneNumber, placeholder: "Phone", keyboardType: .phonePad)
                        }

                        ACTION_BUTTON(
                            title: "Save Changes",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            saveChanges()
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Edit Profile")
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

    func saveChanges() {
        user.firstName = firstName
        user.lastName = lastName
        user.email = email
        user.phoneNumber = phoneNumber
        user.lastModifiedDate = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving user: \(error)")
        }
    }
}

// MARK: - CREATE USER PROFILE VIEW

struct CREATE_USER_PROFILE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var companies: [COMPANY]

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var selectedRole: USER_ROLE = .OWNER

    var userCompany: COMPANY? {
        companies.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Welcome message
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(APP_THEME.PRIMARY)

                            Text("Create Your Profile")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                            Text("Let's get you set up to use TreeShop")
                                .font(.subheadline)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                        }
                        .padding(.vertical, APP_THEME.SPACING_LG)

                        FORM_SECTION(title: "Personal Information", icon: "person.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "First Name", text: $firstName, placeholder: "John")
                            TEXT_FIELD_ROW(title: "Last Name", text: $lastName, placeholder: "Doe")
                            TEXT_FIELD_ROW(title: "Email", text: $email, placeholder: "john@company.com", keyboardType: .emailAddress)
                            TEXT_FIELD_ROW(title: "Phone", text: $phoneNumber, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                        }

                        FORM_SECTION(title: "Role", icon: "star.fill", color: APP_THEME.PRIMARY) {
                            Picker("Role", selection: $selectedRole) {
                                ForEach(USER_ROLE.allCases, id: \.self) { role in
                                    Text(role.rawValue).tag(role)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)

                            Text(selectedRole.description)
                                .font(.caption)
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        }

                        ACTION_BUTTON(
                            title: "Create Profile",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            createProfile()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }

    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty
    }

    func createProfile() {
        let newUser = USER_PROFILE(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            role: selectedRole,
            companyID: userCompany?.id
        )

        if let company = userCompany {
            newUser.companyName = company.companyName
            newUser.subscriptionTier = company.subscriptionTier
        }

        modelContext.insert(newUser)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
}

// MARK: - APP SETTINGS VIEW (Placeholder)

struct APP_SETTINGS_VIEW: View {
    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                        Text("App Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        Text("Full settings interface coming soon")
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(.dark)
    }
}
