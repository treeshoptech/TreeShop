import SwiftUI
import SwiftData

struct PROPOSALS_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PROPOSAL.createdDate, order: .reverse) private var proposals: [PROPOSAL]

    @State private var searchText = ""
    @State private var selectedStatusFilter: String?

    var filteredProposals: [PROPOSAL] {
        var result = proposals

        if !searchText.isEmpty {
            result = result.filter {
                $0.customerName.lowercased().contains(searchText.lowercased()) ||
                $0.proposalNumber.lowercased().contains(searchText.lowercased())
            }
        }

        if let status = selectedStatusFilter {
            result = result.filter { $0.proposalStatus == status }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: APP_THEME.SPACING_SM) {
                            Button(action: { selectedStatusFilter = nil }) {
                                Text("All")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedStatusFilter == nil ? .white : APP_THEME.TEXT_SECONDARY)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedStatusFilter == nil ? WORKFLOW_COLORS.PROPOSAL : APP_THEME.BG_SECONDARY)
                                    .cornerRadius(16)
                            }

                            ForEach(["Draft", "Sent", "Viewed", "Accepted", "Declined"], id: \.self) { status in
                                Button(action: { selectedStatusFilter = status }) {
                                    Text(status)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedStatusFilter == status ? .white : APP_THEME.TEXT_SECONDARY)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedStatusFilter == status ? WORKFLOW_COLORS.PROPOSAL : APP_THEME.BG_SECONDARY)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                    }
                    .background(APP_THEME.BG_SECONDARY)

                    if filteredProposals.isEmpty {
                        EMPTY_STATE(
                            icon: "doc.text",
                            title: "No Proposals",
                            message: "Proposals will appear here when created from leads"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                ForEach(filteredProposals) { proposal in
                                    NavigationLink(destination: PROPOSAL_DETAIL_VIEW(proposal: proposal)) {
                                        PROPOSAL_CARD(proposal: proposal)
                                    }
                                }
                            }
                            .padding(APP_THEME.SPACING_MD)
                        }
                    }
                }
            }
            .navigationTitle("Proposals")
            .searchable(text: $searchText, prompt: "Search proposals...")
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - PROPOSAL CARD

struct PROPOSAL_CARD: View {
    let proposal: PROPOSAL

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposalNumber)
                        .font(.caption)
                        .foregroundColor(WORKFLOW_COLORS.PROPOSAL)

                    Text(proposal.customerName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text(proposal.propertyAddress)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                STATUS_BADGE(text: proposal.proposalStatus, color: WORKFLOW_COLORS.PROPOSAL, size: .SMALL)
            }

            Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_LG) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("$\(String(format: "%.0f", proposal.totalAmount))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(APP_THEME.SUCCESS)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Line Items")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("\(proposal.lineItems.count)")
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.INFO)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Est. Hours")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("\(String(format: "%.1f", proposal.estimatedDuration))")
                        .font(.subheadline)
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

// MARK: - PROPOSAL DETAIL VIEW

struct PROPOSAL_DETAIL_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    let proposal: PROPOSAL

    @State private var showingConvertToWorkOrder = false

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Header
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        Text(proposal.proposalNumber)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        STATUS_BADGE(text: proposal.proposalStatus, color: WORKFLOW_COLORS.PROPOSAL)

                        Text(proposal.customerName)
                            .font(.headline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                    .frame(maxWidth: .infinity)

                    // Line items
                    FORM_SECTION(title: "Line Items", icon: "list.bullet", color: APP_THEME.PRIMARY) {
                        ForEach(proposal.lineItems) { item in
                            PROPOSAL_LINE_ITEM_ROW(item: item)
                        }
                    }

                    // Pricing
                    FORM_SECTION(title: "Pricing", icon: "dollarsign.circle.fill", color: APP_THEME.SUCCESS) {
                        DETAIL_ROW(icon: "list.bullet", label: "Subtotal", value: "$\(String(format: "%.2f", proposal.subtotal))")

                        if proposal.taxAmount > 0 {
                            DETAIL_ROW(icon: "percent", label: "Tax", value: "$\(String(format: "%.2f", proposal.taxAmount))")
                        }

                        Divider().background(APP_THEME.TEXT_TERTIARY)

                        HStack {
                            Text("TOTAL")
                                .font(.headline)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                            Spacer()

                            Text("$\(String(format: "%.2f", proposal.totalAmount))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.SUCCESS)
                        }
                    }

                    // Actions
                    if proposal.proposalStatus == "Draft" {
                        ACTION_BUTTON(
                            title: "Mark as Sent",
                            icon: "paperplane.fill",
                            color: APP_THEME.INFO
                        ) {
                            proposal.markAsSent()
                            try? modelContext.save()
                        }
                    }

                    if proposal.proposalStatus == "Sent" || proposal.proposalStatus == "Viewed" {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            ACTION_BUTTON(
                                title: "Mark as Accepted - Create Work Order",
                                icon: "checkmark.circle.fill",
                                color: WORKFLOW_COLORS.WORK_ORDER
                            ) {
                                showingConvertToWorkOrder = true
                            }

                            ACTION_BUTTON(
                                title: "Mark as Declined",
                                icon: "xmark.circle.fill",
                                color: APP_THEME.ERROR,
                                style: .OUTLINED
                            ) {
                                proposal.markAsDeclined(reason: nil)
                                try? modelContext.save()
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle("Proposal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConvertToWorkOrder) {
            CONVERT_PROPOSAL_TO_WORK_ORDER_VIEW(proposal: proposal)
        }
    }
}

// MARK: - CONVERT PROPOSAL TO WORK ORDER

struct CONVERT_PROPOSAL_TO_WORK_ORDER_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let proposal: PROPOSAL

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(WORKFLOW_COLORS.WORK_ORDER)

                            Text("Convert to Work Order")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)

                            Text("Customer accepted! Create work order to begin operations.")
                                .font(.subheadline)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                .multilineTextAlignment(.center)
                        }
                        .padding(APP_THEME.SPACING_LG)

                        FORM_SECTION(title: "Proposal Summary", icon: "doc.text", color: WORKFLOW_COLORS.PROPOSAL) {
                            DETAIL_ROW(icon: "person.fill", label: "Customer", value: proposal.customerName)
                            DETAIL_ROW(icon: "dollarsign.circle.fill", label: "Total", value: "$\(String(format: "%.2f", proposal.totalAmount))", color: APP_THEME.SUCCESS)
                            DETAIL_ROW(icon: "clock.fill", label: "Est. Hours", value: String(format: "%.1f", proposal.estimatedDuration))
                        }

                        ACTION_BUTTON(
                            title: "Create Work Order",
                            icon: "checkmark.circle.fill",
                            color: WORKFLOW_COLORS.WORK_ORDER
                        ) {
                            convertToWorkOrder()
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
            .navigationTitle("Accept Proposal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    func convertToWorkOrder() {
        // Convert line items
        let woLineItems = proposal.lineItems.map { WORK_ORDER_LINE_ITEM(from: $0) }

        // Extract service types from line items
        let serviceTypes = Array(Set(proposal.lineItems.compactMap { SERVICE_TYPE(rawValue: $0.serviceType) }))

        // Create work order
        let workOrder = WORK_ORDER(
            proposalID: proposal.id,
            customerName: proposal.customerName,
            customerPhone: proposal.customerPhone,
            propertyAddress: proposal.propertyAddress,
            jobDescription: "Work Order from Proposal \(proposal.proposalNumber)",
            serviceTypes: serviceTypes,
            lineItems: woLineItems,
            estimatedDuration: proposal.estimatedDuration
        )

        workOrder.leadID = proposal.leadID
        workOrder.customerID = proposal.customerID
        workOrder.estimatedTotalCost = proposal.totalAmount

        // Mark proposal as accepted and converted
        proposal.markAsAccepted()
        proposal.convertedToWorkOrder = true
        proposal.workOrderID = workOrder.id
        proposal.conversionDate = Date()

        modelContext.insert(workOrder)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error converting to work order: \(error)")
        }
    }
}
