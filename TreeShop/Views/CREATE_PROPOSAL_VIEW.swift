import SwiftUI
import SwiftData

struct CREATE_PROPOSAL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let lead: LEAD

    @State private var lineItems: [PROPOSAL_LINE_ITEM] = []
    @State private var showingAddLineItem = false
    @State private var taxRate: Double = 0.0
    @State private var paymentTerms = "Due on receipt"
    @State private var depositRequired: Double? = nil
    @State private var proposalNotes = ""

    var subtotal: Double {
        lineItems.reduce(0.0) { $0 + $1.totalPrice }
    }

    var taxAmount: Double {
        subtotal * taxRate
    }

    var total: Double {
        subtotal + taxAmount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Customer info
                        FORM_SECTION(title: "Customer", icon: "person.fill", color: WORKFLOW_COLORS.PROPOSAL) {
                            DETAIL_ROW(icon: "person.fill", label: "Name", value: lead.customerName)
                            DETAIL_ROW(icon: "location.fill", label: "Property", value: lead.propertyAddress)
                        }

                        // Line items
                        FORM_SECTION(title: "Proposal Line Items", icon: "list.bullet", color: APP_THEME.PRIMARY) {
                            if lineItems.isEmpty {
                                VStack(spacing: APP_THEME.SPACING_SM) {
                                    Text("No line items yet")
                                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                    Button(action: { showingAddLineItem = true }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Line Item")
                                        }
                                        .foregroundColor(APP_THEME.PRIMARY)
                                    }
                                }
                                .padding(APP_THEME.SPACING_MD)
                            } else {
                                VStack(spacing: APP_THEME.SPACING_SM) {
                                    ForEach(lineItems) { item in
                                        PROPOSAL_LINE_ITEM_ROW(item: item)
                                    }

                                    Button(action: { showingAddLineItem = true }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Another Line Item")
                                        }
                                        .foregroundColor(APP_THEME.PRIMARY)
                                        .frame(maxWidth: .infinity)
                                        .padding(APP_THEME.SPACING_SM)
                                    }
                                }
                            }
                        }

                        // Pricing summary
                        if !lineItems.isEmpty {
                            FORM_SECTION(title: "Pricing", icon: "dollarsign.circle.fill", color: APP_THEME.SUCCESS) {
                                DETAIL_ROW(icon: "list.bullet", label: "Subtotal", value: "$\(String(format: "%.2f", subtotal))")

                                HStack {
                                    Text("Tax Rate")
                                        .font(.subheadline)
                                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                    TextField("0.00", value: $taxRate, format: .percent)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .padding(APP_THEME.SPACING_SM)
                                        .background(APP_THEME.BG_TERTIARY)
                                        .cornerRadius(APP_THEME.RADIUS_SM)
                                }

                                if taxRate > 0 {
                                    DETAIL_ROW(icon: "percent", label: "Tax Amount", value: "$\(String(format: "%.2f", taxAmount))")
                                }

                                Divider().background(APP_THEME.TEXT_TERTIARY)

                                HStack {
                                    Text("TOTAL")
                                        .font(.headline)
                                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                    Spacer()

                                    Text("$\(String(format: "%.2f", total))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(APP_THEME.SUCCESS)
                                }
                                .padding(.vertical, APP_THEME.SPACING_SM)
                            }
                        }

                        // Payment terms
                        FORM_SECTION(title: "Payment Terms", icon: "banknote.fill", color: APP_THEME.WARNING) {
                            TEXT_FIELD_ROW(title: "Terms", text: $paymentTerms, placeholder: "Due on receipt")
                        }

                        // Create proposal button
                        ACTION_BUTTON(
                            title: "Create Proposal",
                            icon: "doc.badge.plus",
                            color: WORKFLOW_COLORS.PROPOSAL
                        ) {
                            createProposal()
                        }
                        .disabled(lineItems.isEmpty)
                        .opacity(lineItems.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Create Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
            .sheet(isPresented: $showingAddLineItem) {
                ADD_PROPOSAL_LINE_ITEM_VIEW(lineItems: $lineItems)
            }
        }
        .preferredColorScheme(.dark)
    }

    func createProposal() {
        let proposal = PROPOSAL(
            leadID: lead.id,
            customerName: lead.customerName,
            customerPhone: lead.customerPhone,
            customerEmail: lead.customerEmail,
            propertyAddress: lead.propertyAddress,
            propertyCity: lead.propertyCity,
            propertyState: lead.propertyState,
            propertyZip: lead.propertyZip,
            lineItems: lineItems,
            taxRate: taxRate
        )

        proposal.customerID = lead.customerID
        proposal.paymentTerms = paymentTerms
        proposal.proposalNotes = proposalNotes

        // Advance lead to proposal stage
        lead.workflowStage = WORKFLOW_STAGE.PROPOSAL.rawValue
        lead.lastModifiedDate = Date()

        modelContext.insert(proposal)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating proposal: \(error)")
        }
    }
}

// MARK: - PROPOSAL LINE ITEM ROW

struct PROPOSAL_LINE_ITEM_ROW: View {
    let item: PROPOSAL_LINE_ITEM

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            HStack {
                Text("#\(item.itemNumber)")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)

                Text(item.description)
                    .font(.body)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                Spacer()

                Text("$\(String(format: "%.2f", item.totalPrice))")
                    .font(.headline)
                    .foregroundColor(APP_THEME.SUCCESS)
            }

            HStack(spacing: APP_THEME.SPACING_MD) {
                Text("\(item.quantity) \(item.unitOfMeasure)")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                Text("@ $\(String(format: "%.2f", item.unitPrice))")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                if item.estimatedHours > 0 {
                    Text("• \(String(format: "%.1f", item.estimatedHours))h")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                }
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_TERTIARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - ADD LINE ITEM VIEW

struct ADD_PROPOSAL_LINE_ITEM_VIEW: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var lineItems: [PROPOSAL_LINE_ITEM]

    @State private var selectedService: SERVICE_TYPE = .TREE_REMOVAL
    @State private var description = ""
    @State private var quantity = "1"
    @State private var unitPrice = ""
    @State private var estimatedHours = ""

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Service", icon: "tree.fill", color: APP_THEME.PRIMARY) {
                            Picker("Service Type", selection: $selectedService) {
                                ForEach(SERVICE_TYPE.allCases, id: \.self) { service in
                                    HStack {
                                        Image(systemName: service.icon)
                                        Text(service.displayName)
                                    }.tag(service)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)

                            TEXT_FIELD_ROW(title: "Description", text: $description, placeholder: "Remove 30\" Red Oak")
                        }

                        FORM_SECTION(title: "Pricing", icon: "dollarsign.circle.fill", color: APP_THEME.SUCCESS) {
                            TEXT_FIELD_ROW(title: "Quantity", text: $quantity, placeholder: "1", keyboardType: .numberPad)
                            TEXT_FIELD_ROW(title: "Unit Price", text: $unitPrice, placeholder: "500.00", keyboardType: .decimalPad)
                            TEXT_FIELD_ROW(title: "Estimated Hours", text: $estimatedHours, placeholder: "3.0", keyboardType: .decimalPad)
                        }

                        ACTION_BUTTON(
                            title: "Add Line Item",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            addLineItem()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Add Line Item")
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

    var isValid: Bool {
        !description.isEmpty &&
        Int(quantity) != nil &&
        Double(unitPrice) != nil &&
        Double(estimatedHours) != nil
    }

    func addLineItem() {
        guard let qty = Int(quantity),
              let price = Double(unitPrice),
              let hours = Double(estimatedHours) else {
            return
        }

        let newItem = PROPOSAL_LINE_ITEM(
            itemNumber: lineItems.count + 1,
            serviceType: selectedService,
            description: description,
            quantity: qty,
            unitOfMeasure: "each",
            unitPrice: price,
            laborCost: 0.0, // Will calculate with crew costs later
            equipmentCost: 0.0, // Will calculate with equipment costs later
            materialCost: 0.0,
            estimatedHours: hours
        )

        lineItems.append(newItem)
        dismiss()
    }
}
