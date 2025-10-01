import SwiftUI
import SwiftData

struct COMPANY_SETTINGS_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var companies: [COMPANY]

    @State private var showingAddCompany = false

    var company: COMPANY? {
        companies.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                if let company = company {
                    COMPANY_DETAIL_VIEW(company: company)
                } else {
                    EMPTY_STATE(
                        icon: "building.2.fill",
                        title: "No Company Set Up",
                        message: "Create your company profile to get started with TreeShop",
                        actionTitle: "Set Up Company",
                        action: { showingAddCompany = true }
                    )
                }
            }
            .navigationTitle("Company Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if company != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            showingAddCompany = true
                        }
                        .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddCompany) {
                if let company = company {
                    EDIT_COMPANY_VIEW(company: company)
                } else {
                    CREATE_COMPANY_VIEW()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - COMPANY DETAIL VIEW

struct COMPANY_DETAIL_VIEW: View {
    let company: COMPANY

    var body: some View {
        ScrollView {
            VStack(spacing: APP_THEME.SPACING_LG) {
                // Company header
                VStack(spacing: APP_THEME.SPACING_MD) {
                    if let logoURL = company.logoURL {
                        AsyncImage(url: URL(string: logoURL)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                        } placeholder: {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(APP_THEME.PRIMARY)
                        }
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(APP_THEME.PRIMARY)
                    }

                    Text(company.companyName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    STATUS_BADGE(text: company.subscriptionDisplayName, color: APP_THEME.PRIMARY)
                }
                .padding(APP_THEME.SPACING_LG)

                // Basic Information
                FORM_SECTION(title: "Basic Information", icon: "info.circle.fill", color: APP_THEME.INFO) {
                    DETAIL_ROW(icon: "location.fill", label: "Address", value: company.fullAddress)
                    DETAIL_ROW(icon: "phone.fill", label: "Phone", value: company.phoneNumber)
                    DETAIL_ROW(icon: "envelope.fill", label: "Email", value: company.email)
                    if let website = company.website {
                        DETAIL_ROW(icon: "globe", label: "Website", value: website)
                    }
                }

                // Business Details
                FORM_SECTION(title: "Business Details", icon: "doc.text.fill", color: APP_THEME.PRIMARY) {
                    if let license = company.licenseNumber {
                        DETAIL_ROW(icon: "checkmark.seal.fill", label: "License", value: license)
                    }
                    if let insurance = company.insuranceProvider {
                        DETAIL_ROW(icon: "shield.fill", label: "Insurance", value: insurance)
                    }
                    if let taxID = company.taxID {
                        DETAIL_ROW(icon: "number", label: "Tax ID", value: taxID)
                    }
                }

                // Financial Settings
                FORM_SECTION(title: "Default Profit Margins", icon: "dollarsign.circle.fill", color: APP_THEME.SUCCESS) {
                    DETAIL_ROW(icon: "tree.fill", label: "Tree Removal", value: "\(Int(company.defaultProfitMarginRemoval * 100))%")
                    DETAIL_ROW(icon: "scissors", label: "Tree Trimming", value: "\(Int(company.defaultProfitMarginTrimming * 100))%")
                    DETAIL_ROW(icon: "circle.grid.cross.fill", label: "Stump Grinding", value: "\(Int(company.defaultProfitMarginStumpGrinding * 100))%")
                    DETAIL_ROW(icon: "leaf.fill", label: "Forestry Mulching", value: "\(Int(company.defaultProfitMarginForestryMulching * 100))%")
                }

                // Subscription
                FORM_SECTION(title: "Subscription", icon: "star.fill", color: APP_THEME.WARNING) {
                    DETAIL_ROW(icon: "crown.fill", label: "Plan", value: company.subscriptionTier)
                    DETAIL_ROW(icon: "person.2.fill", label: "Users", value: "\(company.currentUserCount) / \(company.maxUsers)")
                    DETAIL_ROW(icon: "checkmark.circle.fill", label: "Status", value: company.subscriptionStatus, color: company.isSubscriptionActive ? APP_THEME.SUCCESS : APP_THEME.ERROR)
                }

                Spacer(minLength: 100)
            }
            .padding(APP_THEME.SPACING_MD)
        }
    }
}

// MARK: - CREATE COMPANY VIEW

struct CREATE_COMPANY_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var businessAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phoneNumber = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Company Information", icon: "building.2.fill", color: APP_THEME.PRIMARY) {
                            TEXT_FIELD_ROW(title: "Company Name", text: $companyName, placeholder: "ABC Tree Service")
                            TEXT_FIELD_ROW(title: "Phone Number", text: $phoneNumber, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                            TEXT_FIELD_ROW(title: "Email", text: $email, placeholder: "contact@company.com", keyboardType: .emailAddress)
                        }

                        FORM_SECTION(title: "Business Address", icon: "location.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "Street Address", text: $businessAddress, placeholder: "123 Main St")
                            TEXT_FIELD_ROW(title: "City", text: $city, placeholder: "City")
                            HStack(spacing: APP_THEME.SPACING_SM) {
                                TEXT_FIELD_ROW(title: "State", text: $state, placeholder: "ST")
                                    .frame(width: 80)
                                TEXT_FIELD_ROW(title: "ZIP", text: $zipCode, placeholder: "12345", keyboardType: .numberPad)
                            }
                        }

                        ACTION_BUTTON(
                            title: "Create Company",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            createCompany()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Set Up Company")
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
        !companyName.isEmpty &&
        !businessAddress.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty &&
        !phoneNumber.isEmpty &&
        !email.isEmpty
    }

    func createCompany() {
        let newCompany = COMPANY(
            companyName: companyName,
            businessAddress: businessAddress,
            city: city,
            state: state,
            zipCode: zipCode,
            phoneNumber: phoneNumber,
            email: email
        )

        modelContext.insert(newCompany)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating company: \(error)")
        }
    }
}

// MARK: - EDIT COMPANY VIEW

struct EDIT_COMPANY_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let company: COMPANY

    @State private var companyName: String
    @State private var phoneNumber: String
    @State private var email: String

    init(company: COMPANY) {
        self.company = company
        _companyName = State(initialValue: company.companyName)
        _phoneNumber = State(initialValue: company.phoneNumber)
        _email = State(initialValue: company.email)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Company Information", icon: "building.2.fill", color: APP_THEME.PRIMARY) {
                            TEXT_FIELD_ROW(title: "Company Name", text: $companyName, placeholder: "Company Name")
                            TEXT_FIELD_ROW(title: "Phone", text: $phoneNumber, placeholder: "Phone", keyboardType: .phonePad)
                            TEXT_FIELD_ROW(title: "Email", text: $email, placeholder: "Email", keyboardType: .emailAddress)
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
            .navigationTitle("Edit Company")
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
        company.companyName = companyName
        company.phoneNumber = phoneNumber
        company.email = email
        company.lastModifiedDate = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving company: \(error)")
        }
    }
}
