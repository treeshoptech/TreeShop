import SwiftUI
import SwiftData
import MapKit

struct TREES_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TREE.createdDate, order: .reverse) private var trees: [TREE]

    @State private var showingAddTree = false
    @State private var searchText = ""
    @State private var selectedStatusFilter: TREE_HEALTH_STATUS?
    @State private var showMapView = true

    var filteredTrees: [TREE] {
        var result = trees.filter { !$0.isRemoved }

        if !searchText.isEmpty {
            result = result.filter {
                $0.species.lowercased().contains(searchText.lowercased()) ||
                ($0.commonName?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }

        if let status = selectedStatusFilter {
            result = result.filter { $0.healthStatus == status.rawValue }
        }

        return result
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
                                    .background(selectedStatusFilter == nil ? APP_THEME.PRIMARY : APP_THEME.BG_SECONDARY)
                                    .cornerRadius(16)
                            }

                            ForEach(TREE_HEALTH_STATUS.allCases, id: \.self) { status in
                                if status != .REMOVED {
                                    Button(action: { selectedStatusFilter = status }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: status.icon)
                                            Text(status.rawValue)
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedStatusFilter == status ? .white : APP_THEME.TEXT_SECONDARY)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedStatusFilter == status ? status.color : APP_THEME.BG_SECONDARY)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, APP_THEME.SPACING_MD)
                        .padding(.vertical, APP_THEME.SPACING_SM)
                    }
                    .background(APP_THEME.BG_SECONDARY)

                    if showMapView {
                        TREES_MAP_VIEW(trees: filteredTrees)
                    } else {
                        if filteredTrees.isEmpty {
                            EMPTY_STATE(
                                icon: "tree.fill",
                                title: "No Trees",
                                message: "Score your first tree to get started",
                                actionTitle: "Add Tree",
                                action: { showingAddTree = true }
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: APP_THEME.SPACING_MD) {
                                    ForEach(filteredTrees) { tree in
                                        NavigationLink(destination: TREE_DETAIL_VIEW(tree: tree)) {
                                            TREE_CARD(tree: tree)
                                        }
                                    }
                                }
                                .padding(APP_THEME.SPACING_MD)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trees")
            .searchable(text: $searchText, prompt: "Search trees...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTree = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingAddTree) {
                ADD_TREE_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - TREE CARD

struct TREE_CARD: View {
    let tree: TREE

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                Image(systemName: "tree.fill")
                    .font(.title2)
                    .foregroundColor(tree.pinColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tree.displayName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text(tree.species)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                STATUS_BADGE(text: tree.healthStatus, color: tree.pinColor, size: .SMALL)
            }

            Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_MD) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DBH")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("\(String(format: "%.1f", tree.dbh))\"")
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Height")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("\(Int(tree.height))'")
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TreeScore")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    Text("\(Int(tree.treeScore))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(APP_THEME.PRIMARY)
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

// MARK: - TREES MAP VIEW

struct TREES_MAP_VIEW: View {
    let trees: [TREE]
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(trees) { tree in
                Annotation(tree.displayName, coordinate: tree.coordinate) {
                    ZStack {
                        Circle()
                            .fill(tree.pinColor)
                            .frame(width: 24, height: 24)

                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

// MARK: - ADD TREE VIEW

struct ADD_TREE_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var species = ""
    @State private var dbh = ""
    @State private var height = ""
    @State private var canopyRadius = ""
    @State private var conditionRating = 3
    @State private var healthStatus: TREE_HEALTH_STATUS = .HEALTHY
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var calculatedTreeScore: Double {
        guard let dbhValue = Double(dbh),
              let heightValue = Double(height),
              let crValue = Double(canopyRadius) else {
            return 0.0
        }
        return TREE.calculateTreeScore(height: heightValue, dbh: dbhValue, canopyRadius: crValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Tree Identification", icon: "tree.fill", color: APP_THEME.PRIMARY) {
                            TEXT_FIELD_ROW(title: "Species", text: $species, placeholder: "Red Oak")
                        }

                        FORM_SECTION(title: "Professional Measurements", icon: "ruler.fill", color: APP_THEME.INFO) {
                            TEXT_FIELD_ROW(title: "DBH (inches)", text: $dbh, placeholder: "24.0", keyboardType: .decimalPad)
                            TEXT_FIELD_ROW(title: "Height (feet)", text: $height, placeholder: "60", keyboardType: .decimalPad)
                            TEXT_FIELD_ROW(title: "Canopy Radius (feet)", text: $canopyRadius, placeholder: "15", keyboardType: .decimalPad)

                            if calculatedTreeScore > 0 {
                                VStack(spacing: APP_THEME.SPACING_SM) {
                                    Text("TreeScore")
                                        .font(.caption)
                                        .foregroundColor(APP_THEME.TEXT_TERTIARY)

                                    Text("\(Int(calculatedTreeScore))")
                                        .font(.system(size: 36))
                                        .fontWeight(.bold)
                                        .foregroundColor(APP_THEME.PRIMARY)

                                    Text("H × DBH² + CR²")
                                        .font(.caption2)
                                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.PRIMARY.opacity(0.1))
                                .cornerRadius(APP_THEME.RADIUS_MD)
                            }
                        }

                        FORM_SECTION(title: "Condition Assessment", icon: "stethoscope.circle.fill", color: APP_THEME.WARNING) {
                            Picker("Health Status", selection: $healthStatus) {
                                ForEach(TREE_HEALTH_STATUS.allCases, id: \.self) { status in
                                    if status != .REMOVED {
                                        HStack {
                                            Image(systemName: status.icon)
                                            Text(status.rawValue)
                                        }.tag(status)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)

                            Picker("Condition Rating", selection: $conditionRating) {
                                ForEach(1...5, id: \.self) { rating in
                                    HStack {
                                        ForEach(0..<rating, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                        }
                                        Text("\(rating) stars")
                                    }.tag(rating)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.BG_TERTIARY)
                            .cornerRadius(APP_THEME.RADIUS_SM)
                        }

                        ACTION_BUTTON(
                            title: "Save Tree",
                            icon: "checkmark.circle.fill",
                            color: APP_THEME.PRIMARY
                        ) {
                            saveTree()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Score Tree")
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
        !species.isEmpty &&
        Double(dbh) != nil &&
        Double(height) != nil &&
        Double(canopyRadius) != nil
    }

    func saveTree() {
        guard let dbhValue = Double(dbh),
              let heightValue = Double(height),
              let crValue = Double(canopyRadius) else {
            return
        }

        // Use selected coordinate or default (will add map picker later)
        let coord = selectedCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let newTree = TREE(
            latitude: coord.latitude,
            longitude: coord.longitude,
            species: species,
            dbh: dbhValue,
            height: heightValue,
            canopyRadius: crValue
        )

        newTree.conditionRating = conditionRating
        newTree.healthStatus = healthStatus.rawValue

        modelContext.insert(newTree)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving tree: \(error)")
        }
    }
}

// MARK: - TREE DETAIL VIEW

struct TREE_DETAIL_VIEW: View {
    let tree: TREE

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: APP_THEME.SPACING_LG) {
                    // Tree header
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        Image(systemName: "tree.fill")
                            .font(.system(size: 60))
                            .foregroundColor(tree.pinColor)

                        Text(tree.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                        Text(tree.species)
                            .font(.headline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)

                        STATUS_BADGE(text: tree.healthStatus, color: tree.pinColor)
                    }
                    .frame(maxWidth: .infinity)

                    // Measurements
                    FORM_SECTION(title: "Measurements", icon: "ruler.fill", color: APP_THEME.INFO) {
                        DETAIL_ROW(icon: "arrow.left.and.right", label: "DBH", value: "\(String(format: "%.1f", tree.dbh)) inches")
                        DETAIL_ROW(icon: "arrow.up", label: "Height", value: "\(Int(tree.height)) feet")
                        DETAIL_ROW(icon: "circle.fill", label: "Canopy Radius", value: "\(String(format: "%.1f", tree.canopyRadius)) feet")
                        DETAIL_ROW(icon: "circle.dotted", label: "Crown Spread", value: "\(String(format: "%.1f", tree.crownSpread)) feet")
                    }

                    // TreeScore
                    FORM_SECTION(title: "TreeScore", icon: "star.fill", color: APP_THEME.PRIMARY) {
                        VStack(spacing: APP_THEME.SPACING_SM) {
                            Text("\(Int(tree.treeScore))")
                                .font(.system(size: 48))
                                .fontWeight(.bold)
                                .foregroundColor(APP_THEME.PRIMARY)

                            Text("H × DBH² + CR²")
                                .font(.caption)
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)

                            Text("\(Int(tree.height)) × \(String(format: "%.0f", tree.dbh * tree.dbh)) + \(String(format: "%.0f", tree.canopyRadius * tree.canopyRadius)) = \(Int(tree.treeScore))")
                                .font(.caption2)
                                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(APP_THEME.SPACING_MD)
                        .background(APP_THEME.PRIMARY.opacity(0.1))
                        .cornerRadius(APP_THEME.RADIUS_MD)
                    }

                    // Condition
                    FORM_SECTION(title: "Condition", icon: "stethoscope.fill", color: APP_THEME.WARNING) {
                        HStack {
                            ForEach(0..<tree.conditionRating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(APP_THEME.WARNING)
                            }
                            ForEach(0..<(5 - tree.conditionRating), id: \.self) { _ in
                                Image(systemName: "star")
                                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
                            }
                        }
                        .padding(APP_THEME.SPACING_SM)
                    }

                    Spacer(minLength: 100)
                }
                .padding(APP_THEME.SPACING_MD)
            }
        }
        .navigationTitle(tree.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
