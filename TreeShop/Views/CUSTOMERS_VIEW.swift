import SwiftUI
import SwiftData

struct CUSTOMERS_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CUSTOMER.customerName) private var customers: [CUSTOMER]

    @State private var showingAddCustomer = false
    @State private var searchText = ""
    @State private var selectedTypeFilter: CUSTOMER_TYPE?

    var filteredCustomers: [CUSTOMER] {
        var result = customers.filter { $0.customerStatus == "Active" }

        if !searchText.isEmpty {
            result = result.filter {
                $0.customerName.lowercased().contains(searchText.lowercased()) ||
                $0.phoneNumber.contains(searchText) ||
                ($0.email?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        if let type = selectedTypeFilter {
            result = result.filter { $0.customerType == type.rawValue }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Type filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: APP_THEME.SPACING_SM) {
                            Button(action: { selectedTypeFilter = nil }) {
                                Text("All")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedTypeFilter == nil ? .white : APP_THEME.TEXT_SECONDARY)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTypeFilter == nil ? APP_THEME.PRIMARY : APP_THEME.BG_SECONDARY)
                                    .cornerRadius(16)
                            }

                            ForEach(CUSTOMER_TYPE.allCases, id: \.self) { type in
                                Button(action: { selectedTypeFilter = type }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                        Text(type.displayName)
                                    }
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedTypeFilter == type ? .white : APP_THEME.TEXT_SECONDARY)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTypeFilter == type ? type.color : APP_THEME.BG_SECONDARY)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                    }
                    .background(APP_THEME.BG_SECONDARY)

                    if filteredCustomers.isEmpty {
                        EMPTY_STATE(
                            icon: "person.2.fill",
                            title: "No Customers",
                            message: searchText.isEmpty ?
                                "Add your first customer to get started" :
                                "No customers found matching '\(searchText)'",
                            actionTitle: searchText.isEmpty ? "Add Customer" : nil,
                            action: searchText.isEmpty ? { showingAddCustomer = true } : nil
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                ForEach(filteredCustomers) { customer in
                                    NavigationLink(destination: CUSTOMER_DETAIL_VIEW(customer: customer)) {
                                        CUSTOMER_CARD(customer: customer)
                                    }
                                }
                            }
                            .padding(APP_THEME.SPACING_MD)
                        }
                    }
                }
            }
            .navigationTitle("Customers")
            .searchable(text: $searchText, prompt: "Search customers...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                ADD_CUSTOMER_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - CUSTOMER CARD

struct CUSTOMER_CARD: View {
    let customer: CUSTOMER

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.customerName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    HStack(spacing: 4) {
                        Image(systemName: customer.customerTypeEnum.icon)
                            .font(.caption)
                        Text(customer.customerTypeEnum.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                if customer.isVIP {
                    STATUS_BADGE(text: "VIP", color: APP_THEME.WARNING, size: .SMALL)
                }
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

// MARK: - ADD CUSTOMER VIEW

struct ADD_CUSTOMER_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var customerName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var customerType: CUSTOMER_TYPE = .RESIDENTIAL

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Customer Information", icon: "person.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "Name", text: $customerName, placeholder: "John Doe")
                            TEXT_FIELD_ROW(title: "Phone", text: $phoneNumber, placeholder: "(555) 123-4567", keyboardType: .phonePad)
                            TEXT_FIELD_ROW(title: "Email (Optional)", text: $email, placeholder: "john@example.com", keyboardType: .emailAddress)
                        }

                        FORM_SECTION(title: "Customer Type", icon: "tag.fill", color: APP_THEME.PRIMARY) {
                            Picker("Type", selection: $customerType) {
                                ForEach(CUSTOMER_TYPE.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.displayName)
                                    }.tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)
                        }

                        ACTION_BUTTON(
                            title: "Add Customer",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            addCustomer()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Add Customer")
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
        !customerName.isEmpty && !phoneNumber.isEmpty
    }

    func addCustomer() {
        let newCustomer = CUSTOMER(
            customerName: customerName,
            phoneNumber: phoneNumber,
            email: email.isEmpty ? nil : email,
            customerType: customerType
        )

        modelContext.insert(newCustomer)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding customer: \(error)")
        }
    }
}

// MARK: - CUSTOMER DETAIL VIEW

struct CUSTOMER_DETAIL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProperties: [PROPERTY]

    let customer: CUSTOMER

    @State private var showingAddProperty = false

    var customerProperties: [PROPERTY] {
        allProperties.filter { property in
            customer.propertyIDs.contains(property.id.uuidString)
        }
    }

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Header
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        HStack {
                            Image(systemName: customer.customerTypeEnum.icon)
                                .font(.system(size: 40))
                                .foregroundColor(customer.customerTypeEnum.color)

                            Spacer()

                            if customer.isVIP {
                                STATUS_BADGE(text: "VIP", color: APP_THEME.WARNING)
                            }
                        }

                        HStack {
                            Text(customer.customerName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                            Spacer()
                        }

                        HStack {
                            STATUS_BADGE(text: customer.customerTypeEnum.displayName, color: customer.customerTypeEnum.color, size: .SMALL)
                            if customer.isRepeatCustomer {
                                STATUS_BADGE(text: "Repeat Customer", color: APP_THEME.SUCCESS, size: .SMALL)
                            }
                            Spacer()
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)

                    // Stats
                    HStack(spacing: APP_THEME.SPACING_MD) {
                        INFO_CARD(
                            icon: "map.fill",
                            title: "Properties",
                            value: "\(customer.propertyCount)",
                            color: APP_THEME.INFO
                        )

                        INFO_CARD(
                            icon: "checkmark.circle.fill",
                            title: "Jobs",
                            value: "\(customer.totalJobsCompleted)",
                            color: APP_THEME.PRIMARY
                        )
                    }

                    INFO_CARD(
                        icon: "dollarsign.circle.fill",
                        title: "Total Revenue",
                        value: "$\(String(format: "%.0f", customer.totalRevenue))",
                        color: APP_THEME.SUCCESS,
                        subtitle: customer.totalJobsCompleted > 0 ? "Avg: $\(Int(customer.averageJobValue)) per job" : nil
                    )

                    // Contact
                    FORM_SECTION(title: "Contact", icon: "phone.fill", color: APP_THEME.INFO) {
                        DETAIL_ROW(icon: "phone.fill", label: "Phone", value: customer.phoneNumber)
                        if let email = customer.email {
                            DETAIL_ROW(icon: "envelope.fill", label: "Email", value: email)
                        }
                    }

                    // Properties
                    FORM_SECTION(title: "Properties", icon: "map.fill", color: APP_THEME.PRIMARY) {
                        if customerProperties.isEmpty {
                            VStack(spacing: APP_THEME.SPACING_SM) {
                                Text("No properties yet")
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                Button(action: { showingAddProperty = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Property")
                                    }
                                    .foregroundColor(APP_THEME.PRIMARY)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(APP_THEME.SPACING_MD)
                        } else {
                            VStack(spacing: APP_THEME.SPACING_SM) {
                                ForEach(customerProperties) { property in
                                    NavigationLink(destination: PROPERTY_DETAIL_VIEW(property: property)) {
                                        HStack {
                                            Image(systemName: "house.fill")
                                                .foregroundColor(APP_THEME.PRIMARY)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(property.propertyAddress)
                                                    .font(.body)
                                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                                Text("\(property.city), \(property.state)")
                                                    .font(.caption)
                                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                        }
                                        .padding(APP_THEME.SPACING_SM)
                                        .background(APP_THEME.BG_TERTIARY)
                                        .cornerRadius(APP_THEME.RADIUS_SM)
                                    }
                                }

                                Button(action: { showingAddProperty = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Another Property")
                                    }
                                    .foregroundColor(APP_THEME.PRIMARY)
                                    .frame(maxWidth: .infinity)
                                    .padding(APP_THEME.SPACING_SM)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(customer.customerName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddProperty) {
            ADD_PROPERTY_VIEW(preselectedCustomer: customer)
        }
    }
}
