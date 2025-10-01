import SwiftUI
import MapKit

struct ADD_LEAD_FORM: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()

    // Customer Info
    @State private var customerName = ""
    @State private var customerPhone = ""
    @State private var customerEmail = ""
    @State private var preferredContact: CONTACT_METHOD = .PHONE

    // Property Info
    @State private var propertyAddress = ""
    @State private var propertyCity = ""
    @State private var propertyState = ""
    @State private var propertyZip = ""
    @State private var propertyType = "Residential"
    @State private var propertyAcres = ""

    // Location
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingMapPicker = false

    // Service Details
    @State private var selectedServices: Set<SERVICE_TYPE> = []
    @State private var urgency: URGENCY_LEVEL = .MEDIUM
    @State private var projectDescription = ""
    @State private var needsSiteVisit = true

    // Lead Source
    @State private var leadSource: LEAD_SOURCE = .WEBSITE

    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Customer Section
                        FORM_SECTION(title: "Customer Information", icon: "person.fill", color: WORKFLOW_COLORS.LEAD) {
                            TEXT_FIELD_ROW(
                                title: "Name",
                                text: $customerName,
                                placeholder: "John Doe"
                            )

                            TEXT_FIELD_ROW(
                                title: "Phone",
                                text: $customerPhone,
                                placeholder: "(555) 123-4567",
                                keyboardType: .phonePad
                            )

                            TEXT_FIELD_ROW(
                                title: "Email",
                                text: $customerEmail,
                                placeholder: "john@example.com",
                                keyboardType: .emailAddress
                            )

                            PICKER_ROW(
                                title: "Preferred Contact",
                                selection: $preferredContact,
                                options: CONTACT_METHOD.allCases
                            )
                        }

                        // Property Section
                        FORM_SECTION(title: "Property Location", icon: "map.fill", color: APP_THEME.PRIMARY) {
                            TEXT_FIELD_ROW(
                                title: "Address",
                                text: $propertyAddress,
                                placeholder: "123 Main St"
                            )

                            HStack(spacing: APP_THEME.SPACING_SM) {
                                TEXT_FIELD_ROW(
                                    title: "City",
                                    text: $propertyCity,
                                    placeholder: "City"
                                )

                                TEXT_FIELD_ROW(
                                    title: "State",
                                    text: $propertyState,
                                    placeholder: "ST"
                                )
                                .frame(width: 80)

                                TEXT_FIELD_ROW(
                                    title: "Zip",
                                    text: $propertyZip,
                                    placeholder: "12345",
                                    keyboardType: .numberPad
                                )
                                .frame(width: 100)
                            }

                            Button(action: { showingMapPicker = true }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(APP_THEME.PRIMARY)

                                    Text(selectedCoordinate == nil ? "Select on Map" : "Location Selected")
                                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                    Spacer()

                                    if selectedCoordinate != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(APP_THEME.SUCCESS)
                                    }
                                }
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.BG_SECONDARY)
                                .cornerRadius(APP_THEME.RADIUS_MD)
                            }

                            TEXT_FIELD_ROW(
                                title: "Acres (optional)",
                                text: $propertyAcres,
                                placeholder: "0.5",
                                keyboardType: .decimalPad
                            )
                        }

                        // Service Section
                        FORM_SECTION(title: "Service Request", icon: "tree.fill", color: APP_THEME.SUCCESS) {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                                Text("Services Needed")
                                    .font(.subheadline)
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                SERVICE_SELECTOR(selectedServices: $selectedServices)
                            }

                            PICKER_ROW(
                                title: "Urgency",
                                selection: $urgency,
                                options: URGENCY_LEVEL.allCases
                            )

                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                                Text("Project Description")
                                    .font(.subheadline)
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                TextEditor(text: $projectDescription)
                                    .frame(height: 120)
                                    .padding(APP_THEME.SPACING_SM)
                                    .background(APP_THEME.BG_SECONDARY)
                                    .cornerRadius(APP_THEME.RADIUS_SM)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)
                            }

                            Toggle(isOn: $needsSiteVisit) {
                                HStack {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(APP_THEME.INFO)
                                    Text("Needs Site Visit")
                                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                                }
                            }
                            .tint(APP_THEME.PRIMARY)
                        }

                        // Lead Source Section
                        FORM_SECTION(title: "Lead Source", icon: "chart.line.uptrend.xyaxis.circle.fill", color: APP_THEME.INFO) {
                            PICKER_ROW(
                                title: "Source",
                                selection: $leadSource,
                                options: LEAD_SOURCE.allCases
                            )
                        }

                        // Submit Button
                        Button(action: submitLead) {
                            Text("Create Lead")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(APP_THEME.SPACING_MD)
                                .background(WORKFLOW_COLORS.LEAD)
                                .cornerRadius(APP_THEME.RADIUS_MD)
                        }
                        .padding(.top, APP_THEME.SPACING_MD)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("New Lead")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MAP_LOCATION_PICKER(selectedCoordinate: $selectedCoordinate)
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                workflowManager.setContext(modelContext)
            }
        }
    }

    private func submitLead() {
        // Validate required fields
        guard !customerName.isEmpty else {
            validationMessage = "Customer name is required"
            showingValidationAlert = true
            return
        }

        guard !customerPhone.isEmpty else {
            validationMessage = "Customer phone is required"
            showingValidationAlert = true
            return
        }

        guard !propertyAddress.isEmpty else {
            validationMessage = "Property address is required"
            showingValidationAlert = true
            return
        }

        guard !propertyCity.isEmpty else {
            validationMessage = "City is required"
            showingValidationAlert = true
            return
        }

        guard !propertyState.isEmpty else {
            validationMessage = "State is required"
            showingValidationAlert = true
            return
        }

        guard !propertyZip.isEmpty else {
            validationMessage = "Zip code is required"
            showingValidationAlert = true
            return
        }

        guard !selectedServices.isEmpty else {
            validationMessage = "Please select at least one service"
            showingValidationAlert = true
            return
        }

        guard !projectDescription.isEmpty else {
            validationMessage = "Project description is required"
            showingValidationAlert = true
            return
        }

        // Use selected coordinate or geocode address
        let coordinate = selectedCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)

        // Create lead
        let lead = LEAD(
            customerName: customerName,
            customerPhone: customerPhone,
            customerEmail: customerEmail.isEmpty ? nil : customerEmail,
            propertyAddress: propertyAddress,
            propertyCity: propertyCity,
            propertyState: propertyState,
            propertyZip: propertyZip,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            serviceTypes: Array(selectedServices),
            urgencyLevel: urgency,
            leadSource: leadSource,
            projectDescription: projectDescription,
            needsSiteVisit: needsSiteVisit
        )

        // Set optional fields
        if !propertyAcres.isEmpty, let acres = Double(propertyAcres) {
            lead.propertyAcres = acres
        }
        lead.propertyType = propertyType
        lead.preferredContactMethod = preferredContact.rawValue

        // Save lead
        workflowManager.createLead(lead)

        dismiss()
    }
}

// MARK: - SERVICE SELECTOR

struct SERVICE_SELECTOR: View {
    @Binding var selectedServices: Set<SERVICE_TYPE>

    var body: some View {
        VStack(spacing: APP_THEME.SPACING_SM) {
            ForEach(SERVICE_TYPE.allCases, id: \.self) { service in
                Button(action: {
                    if selectedServices.contains(service) {
                        selectedServices.remove(service)
                    } else {
                        selectedServices.insert(service)
                    }
                }) {
                    HStack {
                        Image(systemName: service.icon)
                            .foregroundColor(selectedServices.contains(service) ? APP_THEME.PRIMARY : APP_THEME.TEXT_TERTIARY)

                        Text(service.displayName)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        Spacer()

                        if selectedServices.contains(service) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(APP_THEME.PRIMARY)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                    .background(
                        selectedServices.contains(service) ?
                        APP_THEME.PRIMARY.opacity(0.1) :
                        APP_THEME.BG_SECONDARY
                    )
                    .cornerRadius(APP_THEME.RADIUS_MD)
                }
            }
        }
    }
}

// MARK: - MAP LOCATION PICKER

struct MAP_LOCATION_PICKER: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var tempCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    if let coordinate = tempCoordinate {
                        Annotation("Selected Location", coordinate: coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(APP_THEME.PRIMARY)
                        }
                    }
                }
                .onTapGesture { location in
                    // Note: This is simplified - actual implementation would need proper coordinate conversion
                    tempCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                }

                VStack {
                    Spacer()

                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .padding()
                        .background(APP_THEME.BG_SECONDARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)

                        Spacer()

                        Button("Select") {
                            selectedCoordinate = tempCoordinate
                            dismiss()
                        }
                        .disabled(tempCoordinate == nil)
                        .padding()
                        .background(tempCoordinate == nil ? APP_THEME.TEXT_TERTIARY : APP_THEME.PRIMARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)
                        .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
