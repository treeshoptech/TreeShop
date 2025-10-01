import SwiftUI
import SwiftData

struct EQUIPMENT_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EQUIPMENT.equipmentName) private var equipment: [EQUIPMENT]

    @State private var showingAddEquipment = false
    @State private var searchText = ""
    @State private var selectedTypeFilter: EQUIPMENT_TYPE?

    var filteredEquipment: [EQUIPMENT] {
        var result = equipment.filter { $0.equipmentStatus == "Active" }

        if !searchText.isEmpty {
            result = result.filter {
                $0.equipmentName.lowercased().contains(searchText.lowercased()) ||
                ($0.make?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.model?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        if let type = selectedTypeFilter {
            result = result.filter { $0.equipmentType == type.rawValue }
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

                            ForEach(EQUIPMENT_TYPE.allCases, id: \.self) { type in
                                Button(action: { selectedTypeFilter = type }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
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

                    if filteredEquipment.isEmpty {
                        EMPTY_STATE(
                            icon: "wrench.and.screwdriver.fill",
                            title: "No Equipment",
                            message: searchText.isEmpty ?
                                "Add your first piece of equipment to get started" :
                                "No equipment found matching '\(searchText)'",
                            actionTitle: searchText.isEmpty ? "Add Equipment" : nil,
                            action: searchText.isEmpty ? { showingAddEquipment = true } : nil
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                ForEach(filteredEquipment) { item in
                                    NavigationLink(destination: EQUIPMENT_DETAIL_VIEW(equipment: item)) {
                                        EQUIPMENT_CARD(equipment: item)
                                    }
                                }
                            }
                            .padding(APP_THEME.SPACING_MD)
                        }
                    }
                }
            }
            .navigationTitle("Equipment")
            .searchable(text: $searchText, prompt: "Search equipment...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEquipment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                ADD_EQUIPMENT_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - EQUIPMENT CARD

struct EQUIPMENT_CARD: View {
    let equipment: EQUIPMENT

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                Image(systemName: equipment.equipmentTypeEnum.icon)
                    .font(.title2)
                    .foregroundColor(equipment.equipmentTypeEnum.color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.equipmentName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    if let make = equipment.make, let model = equipment.model {
                        Text("\(make) \(model)")
                            .font(.subheadline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    } else {
                        Text(equipment.equipmentTypeEnum.rawValue)
                            .font(.subheadline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                }

                Spacer()

                if equipment.shouldConsiderReplacement {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(APP_THEME.WARNING)
                }

                if !equipment.isAvailable {
                    STATUS_BADGE(text: "In Use", color: APP_THEME.INFO, size: .SMALL)
                }
            }

            Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_LG) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hourly Cost")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("$\(String(format: "%.2f", equipment.totalHourlyCost))/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(APP_THEME.WARNING)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Min Rate")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("$\(String(format: "%.2f", equipment.minimumBillingRate))/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(APP_THEME.ERROR)
                }

                if equipment.utilizationRate > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Utilization")
                            .font(.caption)
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        Text("\(Int(equipment.utilizationRate * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(equipment.isUnderutilized ? APP_THEME.WARNING : APP_THEME.SUCCESS)
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

// MARK: - ADD EQUIPMENT VIEW

struct ADD_EQUIPMENT_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var equipmentName = ""
    @State private var equipmentType: EQUIPMENT_TYPE = .TRUCK
    @State private var make = ""
    @State private var model = ""

    // 6 Inputs for cost calculation
    @State private var purchasePrice = ""
    @State private var annualHours = "1200" // Default 1,200 hours
    @State private var fuelGPH = ""
    @State private var fuelPrice = "3.50" // Default fuel price

    @State private var calculatedCost: Double = 0.0
    @State private var showingCostBreakdown = false

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Equipment Information", icon: "wrench.and.screwdriver.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "Equipment Name", text: $equipmentName, placeholder: "CAT 265 Track Loader")

                            Picker("Equipment Type", selection: $equipmentType) {
                                ForEach(EQUIPMENT_TYPE.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }.tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)

                            TEXT_FIELD_ROW(title: "Make (Optional)", text: $make, placeholder: "Caterpillar")
                            TEXT_FIELD_ROW(title: "Model (Optional)", text: $model, placeholder: "265")
                        }

                        FORM_SECTION(title: "6-Input Cost System", icon: "dollarsign.circle.fill", color: APP_THEME.WARNING) {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                                Text("These 6 inputs calculate your true hourly cost")
                                    .font(.caption)
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                                TEXT_FIELD_ROW(title: "1. Purchase Price", text: $purchasePrice, placeholder: "115000", keyboardType: .decimalPad)

                                TEXT_FIELD_ROW(title: "2. Annual Usage Hours", text: $annualHours, placeholder: "1200", keyboardType: .decimalPad)

                                TEXT_FIELD_ROW(title: "3. Fuel Consumption (GPH)", text: $fuelGPH, placeholder: "14.0", keyboardType: .decimalPad)

                                TEXT_FIELD_ROW(title: "4. Current Fuel Price/Gal", text: $fuelPrice, placeholder: "3.50", keyboardType: .decimalPad)

                                Text("5. Depreciation: 5-year cycle (standard)")
                                    .font(.caption)
                                    .foregroundColor(APP_THEME.TEXT_TERTIARY)

                                Text("6. Maintenance: 15% of purchase price annually (standard)")
                                    .font(.caption)
                                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
                            }

                            if calculatedCost > 0 {
                                Button(action: { showingCostBreakdown.toggle() }) {
                                    VStack(spacing: APP_THEME.SPACING_SM) {
                                        Text("Required Hourly Rate")
                                            .font(.caption)
                                            .foregroundColor(APP_THEME.TEXT_TERTIARY)

                                        Text("$\(String(format: "%.2f", calculatedCost))/hour")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(APP_THEME.ERROR)

                                        HStack(spacing: 4) {
                                            Text(showingCostBreakdown ? "Hide" : "Show")
                                            Text("Breakdown")
                                            Image(systemName: showingCostBreakdown ? "chevron.up" : "chevron.down")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(APP_THEME.PRIMARY)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(APP_THEME.SPACING_MD)
                                    .background(APP_THEME.ERROR.opacity(0.1))
                                    .cornerRadius(APP_THEME.RADIUS_MD)
                                }

                                if showingCostBreakdown, let costs = getCostBreakdown() {
                                    VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                                        DETAIL_ROW(icon: "fuelpump.fill", label: "Fuel Cost", value: "$\(String(format: "%.2f", costs.fuel))/hr")
                                        DETAIL_ROW(icon: "chart.line.downtrend.xyaxis", label: "Depreciation", value: "$\(String(format: "%.2f", costs.depreciation))/hr")
                                        DETAIL_ROW(icon: "wrench.fill", label: "Maintenance", value: "$\(String(format: "%.2f", costs.maintenance))/hr")
                                        DETAIL_ROW(icon: "shield.fill", label: "Insurance/Fixed", value: "$\(String(format: "%.2f", costs.insuranceFixed))/hr")
                                    }
                                    .padding(APP_THEME.SPACING_SM)
                                    .background(APP_THEME.BG_TERTIARY)
                                    .cornerRadius(APP_THEME.RADIUS_SM)
                                }
                            }
                        }

                        ACTION_BUTTON(
                            title: "Add Equipment",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            addEquipment()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
            .onChange(of: purchasePrice) { _, _ in calculateCost() }
            .onChange(of: annualHours) { _, _ in calculateCost() }
            .onChange(of: fuelGPH) { _, _ in calculateCost() }
            .onChange(of: fuelPrice) { _, _ in calculateCost() }
        }
        .preferredColorScheme(.dark)
    }

    var isValid: Bool {
        !equipmentName.isEmpty &&
        Double(purchasePrice) != nil &&
        Double(annualHours) != nil &&
        Double(fuelGPH) != nil &&
        Double(fuelPrice) != nil
    }

    func calculateCost() {
        guard let price = Double(purchasePrice),
              let hours = Double(annualHours),
              let gph = Double(fuelGPH),
              let fuel = Double(fuelPrice) else {
            calculatedCost = 0.0
            return
        }

        let costs = EQUIPMENT.calculateCosts(
            purchasePrice: price,
            annualHours: hours,
            fuelGPH: gph,
            fuelPrice: fuel,
            depreciationYears: 5,
            maintenancePercentage: 0.15,
            insuranceAnnual: 0,
            registrationAnnual: 0,
            storageAnnual: 0
        )

        calculatedCost = costs.total
    }

    func getCostBreakdown() -> (fuel: Double, depreciation: Double, maintenance: Double, insuranceFixed: Double, total: Double)? {
        guard let price = Double(purchasePrice),
              let hours = Double(annualHours),
              let gph = Double(fuelGPH),
              let fuel = Double(fuelPrice) else {
            return nil
        }

        return EQUIPMENT.calculateCosts(
            purchasePrice: price,
            annualHours: hours,
            fuelGPH: gph,
            fuelPrice: fuel,
            depreciationYears: 5,
            maintenancePercentage: 0.15,
            insuranceAnnual: 0,
            registrationAnnual: 0,
            storageAnnual: 0
        )
    }

    func addEquipment() {
        guard let price = Double(purchasePrice),
              let hours = Double(annualHours),
              let gph = Double(fuelGPH),
              let fuel = Double(fuelPrice) else {
            return
        }

        let newEquipment = EQUIPMENT(
            equipmentName: equipmentName,
            equipmentType: equipmentType,
            purchasePrice: price,
            purchaseDate: Date(),
            annualUsageHours: hours,
            fuelConsumptionGPH: gph,
            currentFuelPrice: fuel
        )

        if !make.isEmpty {
            newEquipment.make = make
        }
        if !model.isEmpty {
            newEquipment.model = model
        }

        modelContext.insert(newEquipment)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding equipment: \(error)")
        }
    }
}

// MARK: - EQUIPMENT DETAIL VIEW

struct EQUIPMENT_DETAIL_VIEW: View {
    let equipment: EQUIPMENT

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Header
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        Image(systemName: equipment.equipmentTypeEnum.icon)
                            .font(.system(size: 60))
                            .foregroundColor(equipment.equipmentTypeEnum.color)

                        Text(equipment.equipmentName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        if let make = equipment.make, let model = equipment.model {
                            Text("\(make) \(model)")
                                .font(.headline)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                        }

                        STATUS_BADGE(text: equipment.equipmentTypeEnum.rawValue, color: equipment.equipmentTypeEnum.color)
                    }
                    .frame(maxWidth: .infinity)

                    // Cost Breakdown
                    FORM_SECTION(title: "Cost Analysis", icon: "dollarsign.circle.fill", color: APP_THEME.WARNING) {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Text("Required Minimum Billing Rate")
                                .font(.caption)
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)

                            Text("$\(String(format: "%.2f", equipment.minimumBillingRate))/hour")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.ERROR)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(APP_THEME.SPACING_MD)
                        .background(APP_THEME.ERROR.opacity(0.1))
                        .cornerRadius(APP_THEME.RADIUS_MD)

                        Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

                        DETAIL_ROW(icon: "fuelpump.fill", label: "Fuel Cost", value: "$\(String(format: "%.2f", equipment.fuelCostPerHour))/hr")
                        DETAIL_ROW(icon: "chart.line.downtrend.xyaxis", label: "Depreciation", value: "$\(String(format: "%.2f", equipment.depreciationCostPerHour))/hr")
                        DETAIL_ROW(icon: "wrench.fill", label: "Maintenance", value: "$\(String(format: "%.2f", equipment.maintenanceCostPerHour))/hr")
                        DETAIL_ROW(icon: "shield.fill", label: "Insurance/Fixed", value: "$\(String(format: "%.2f", equipment.insuranceFixedCostPerHour))/hr")

                        Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

                        DETAIL_ROW(icon: "exclamationmark.triangle.fill", label: "Total Hourly Cost", value: "$\(String(format: "%.2f", equipment.totalHourlyCost))/hr", color: APP_THEME.WARNING)
                    }

                    // Business Intelligence
                    FORM_SECTION(title: "Business Requirements", icon: "chart.bar.fill", color: APP_THEME.INFO) {
                        DETAIL_ROW(icon: "calendar.badge.clock", label: "Daily Revenue Need", value: "$\(String(format: "%.2f", equipment.dailyRevenueRequirement))")
                        DETAIL_ROW(icon: "chart.line.uptrend.xyaxis", label: "Annual Revenue Target", value: "$\(String(format: "%.0f", equipment.annualRevenueTarget))")
                    }

                    // Utilization
                    if equipment.totalHoursUsed > 0 {
                        FORM_SECTION(title: "Utilization", icon: "clock.fill", color: APP_THEME.PRIMARY) {
                            DETAIL_ROW(icon: "clock.fill", label: "Hours This Year", value: String(format: "%.1f", equipment.hoursUsedThisYear))
                            DETAIL_ROW(icon: "percent", label: "Utilization Rate", value: "\(Int(equipment.utilizationRate * 100))%", color: equipment.isUnderutilized ? APP_THEME.WARNING : APP_THEME.SUCCESS)
                            DETAIL_ROW(icon: "timer", label: "Total Hours", value: String(format: "%.1f", equipment.totalHoursUsed))
                        }
                    }

                    // Replacement Warning
                    if equipment.shouldConsiderReplacement {
                        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(APP_THEME.WARNING)
                                Text("Replacement Consideration")
                                    .font(.headline)
                                    .foregroundColor(APP_THEME.WARNING)
                            }

                            if let notes = equipment.replacementTriggerNotes {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                            }
                        }
                        .padding(APP_THEME.SPACING_MD)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(APP_THEME.WARNING.opacity(0.1))
                        .cornerRadius(APP_THEME.RADIUS_MD)
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(equipment.equipmentName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
