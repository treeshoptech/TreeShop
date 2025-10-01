import SwiftUI
import SwiftData
import MapKit

struct PROPERTIES_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PROPERTY.propertyAddress) private var properties: [PROPERTY]

    @State private var showingAddProperty = false
    @State private var searchText = ""
    @State private var showMapView = true

    var filteredProperties: [PROPERTY] {
        if searchText.isEmpty {
            return properties.filter { $0.isActive }
        }
        return properties.filter { property in
            property.propertyAddress.lowercased().contains(searchText.lowercased()) ||
            property.city.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                VStack(spacing: 0) {
                    // View toggle
                    Picker("View", selection: $showMapView) {
                        Label("Map", systemImage: "map.fill").tag(true)
                        Label("List", systemImage: "list.bullet").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(APP_THEME.SPACING_MD)
                    .background(APP_THEME.BG_SECONDARY)

                    if showMapView {
                        PROPERTIES_MAP_VIEW(properties: filteredProperties)
                    } else {
                        if filteredProperties.isEmpty {
                            EMPTY_STATE(
                                icon: "map.fill",
                                title: "No Properties",
                                message: "Add your first property to get started",
                                actionTitle: "Add Property",
                                action: { showingAddProperty = true }
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                    ForEach(filteredProperties) { property in
                                        NavigationLink(destination: PROPERTY_DETAIL_VIEW(property: property)) {
                                            PROPERTY_CARD(property: property)
                                        }
                                    }
                                }
                                .padding(APP_THEME.SPACING_MD)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Properties")
            .searchable(text: $searchText, prompt: "Search properties...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProperty = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                ADD_PROPERTY_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - PROPERTY CARD

struct PROPERTY_CARD: View {
    @Query private var customers: [CUSTOMER]
    let property: PROPERTY

    var propertyCustomer: CUSTOMER? {
        guard let customerID = property.customerID else { return nil }
        return customers.first { $0.id == customerID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let customer = propertyCustomer {
                        Text(customer.customerName)
                            .font(.caption)
                            .foregroundColor(customer.customerTypeEnum.color)
                    }

                    Text(property.propertyAddress)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text("\(property.city), \(property.state)")
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                if let acres = property.acreage {
                    STATUS_BADGE(text: "\(String(format: "%.1f", acres)) ac", color: APP_THEME.PRIMARY, size: .SMALL)
                }
            }

            Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_LG) {
                Label("\(property.treeCount) trees", systemImage: "tree.fill")
                    .font(.caption)
                    .foregroundColor(APP_THEME.SUCCESS)

                Label("\(property.jobsCompleted) jobs", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(APP_THEME.INFO)

                if property.totalRevenueFromProperty > 0 {
                    Label("$\(Int(property.totalRevenueFromProperty))", systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(APP_THEME.WARNING)
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

// MARK: - PROPERTIES MAP VIEW

struct PROPERTIES_MAP_VIEW: View {
    let properties: [PROPERTY]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(properties) { property in
                Annotation(property.propertyAddress, coordinate: property.coordinate) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(APP_THEME.PRIMARY)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 30, height: 30)
                        )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

// MARK: - ADD PROPERTY VIEW

struct ADD_PROPERTY_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CUSTOMER.customerName) private var customers: [CUSTOMER]

    var preselectedCustomer: CUSTOMER?

    @State private var selectedCustomer: CUSTOMER?
    @State private var propertyAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var propertyType: CUSTOMER_TYPE = .RESIDENTIAL
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    init(preselectedCustomer: CUSTOMER? = nil) {
        self.preselectedCustomer = preselectedCustomer
        _selectedCustomer = State(initialValue: preselectedCustomer)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Customer Selection
                        FORM_SECTION(title: "Customer", icon: "person.fill", color: APP_THEME.INFO) {
                            if preselectedCustomer != nil {
                                DETAIL_ROW(icon: "person.fill", label: "Customer", value: selectedCustomer?.customerName ?? "Unknown")
                            } else {
                                Picker("Select Customer", selection: $selectedCustomer) {
                                    Text("Select Customer").tag(nil as CUSTOMER?)
                                    ForEach(customers) { customer in
                                        Text(customer.customerName).tag(customer as CUSTOMER?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.BG_TERTIARY)
                                .cornerRadius(APP_THEME.RADIUS_SM)
                            }
                        }

                        FORM_SECTION(title: "Property Address", icon: "map.fill", color: APP_THEME.PRIMARY) {
                            ADDRESS_INPUT_FIELD(
                                address: $propertyAddress,
                                city: $city,
                                state: $state,
                                zipCode: $zipCode,
                                coordinate: $selectedCoordinate
                            )
                        }

                        FORM_SECTION(title: "Property Type", icon: "building.fill", color: APP_THEME.PRIMARY) {
                            Picker("Type", selection: $propertyType) {
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
                            title: "Add Property",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            addProperty()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Add Property")
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
        !propertyAddress.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }

    func addProperty() {
        // Use selected coordinate or default to 0,0 (geocoding will be added later)
        let coord = selectedCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let newProperty = PROPERTY(
            propertyAddress: propertyAddress,
            city: city,
            state: state,
            zipCode: zipCode,
            latitude: coord.latitude,
            longitude: coord.longitude,
            propertyType: propertyType,
            customerID: selectedCustomer?.id
        )

        // Link property to customer
        if let customer = selectedCustomer {
            customer.addProperty(propertyID: newProperty.id)
        }

        modelContext.insert(newProperty)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding property: \(error)")
        }
    }
}

// MARK: - PROPERTY DETAIL VIEW

struct PROPERTY_DETAIL_VIEW: View {
    @Query private var customers: [CUSTOMER]
    let property: PROPERTY

    var propertyCustomer: CUSTOMER? {
        guard let customerID = property.customerID else { return nil }
        return customers.first { $0.id == customerID }
    }

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Map preview
                    Map(initialPosition: .region(
                        MKCoordinateRegion(
                            center: property.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        )
                    )) {
                        Annotation("Property", coordinate: property.coordinate) {
                            Image(systemName: "house.fill")
                                .font(.title)
                                .foregroundColor(APP_THEME.PRIMARY)
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(APP_THEME.RADIUS_MD)

                    // Customer
                    if let customer = propertyCustomer {
                        FORM_SECTION(title: "Customer", icon: "person.fill", color: customer.customerTypeEnum.color) {
                            NavigationLink(destination: CUSTOMER_DETAIL_VIEW(customer: customer)) {
                                HStack {
                                    Image(systemName: customer.customerTypeEnum.icon)
                                        .foregroundColor(customer.customerTypeEnum.color)

                                    Text(customer.customerName)
                                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                }
                                .padding(APP_THEME.SPACING_MD)
                            }
                        }
                    }

                    // Address
                    FORM_SECTION(title: "Location", icon: "map.fill", color: APP_THEME.INFO) {
                        DETAIL_ROW(icon: "location.fill", label: "Address", value: property.fullAddress)
                        if let acres = property.acreage {
                            DETAIL_ROW(icon: "ruler.fill", label: "Acreage", value: String(format: "%.2f acres", acres))
                        }
                    }

                    // Stats
                    FORM_SECTION(title: "Property Stats", icon: "chart.bar.fill", color: APP_THEME.PRIMARY) {
                        DETAIL_ROW(icon: "tree.fill", label: "Trees", value: "\(property.treeCount)")
                        DETAIL_ROW(icon: "checkmark.circle.fill", label: "Jobs Completed", value: "\(property.jobsCompleted)")
                        DETAIL_ROW(icon: "dollarsign.circle.fill", label: "Total Revenue", value: "$\(String(format: "%.0f", property.totalRevenueFromProperty))", color: APP_THEME.SUCCESS)
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle("Property Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
