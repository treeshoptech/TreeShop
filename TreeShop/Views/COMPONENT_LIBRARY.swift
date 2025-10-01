import SwiftUI
import MapKit

// MARK: - FORM SECTION

struct FORM_SECTION<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            // Section Header
            HStack(spacing: APP_THEME.SPACING_SM) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Text(title)
                    .font(.headline)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)
            }

            // Section Content
            VStack(spacing: APP_THEME.SPACING_MD) {
                content
            }
            .padding(APP_THEME.SPACING_MD)
            .background(APP_THEME.BG_SECONDARY)
            .cornerRadius(APP_THEME.RADIUS_MD)
        }
    }
}

// MARK: - TEXT FIELD ROW

struct TEXT_FIELD_ROW: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(TREESHOP_TEXT_FIELD_STYLE())
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(TREESHOP_TEXT_FIELD_STYLE())
            }
        }
    }
}

struct TREESHOP_TEXT_FIELD_STYLE: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(APP_THEME.SPACING_MD)
            .background(APP_THEME.BG_TERTIARY)
            .cornerRadius(APP_THEME.RADIUS_SM)
            .foregroundColor(APP_THEME.TEXT_PRIMARY)
    }
}

// MARK: - PICKER ROW

struct PICKER_ROW<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    if let displayable = option as? any DisplayableEnum {
                        Text(displayable.displayName).tag(option)
                    } else {
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .pickerStyle(.menu)
            .padding(APP_THEME.SPACING_MD)
            .background(APP_THEME.BG_TERTIARY)
            .cornerRadius(APP_THEME.RADIUS_SM)
            .tint(APP_THEME.PRIMARY)
        }
    }
}

// MARK: - DETAIL ROW

struct DETAIL_ROW: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = APP_THEME.TEXT_SECONDARY

    var body: some View {
        HStack(spacing: APP_THEME.SPACING_MD) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)

                Text(value)
                    .font(.body)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)
            }

            Spacer()
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - STATUS BADGE

struct STATUS_BADGE: View {
    let text: String
    let color: Color
    var size: BADGE_SIZE = .MEDIUM

    enum BADGE_SIZE {
        case SMALL, MEDIUM, LARGE

        var font: Font {
            switch self {
            case .SMALL: return .caption2
            case .MEDIUM: return .caption
            case .LARGE: return .subheadline
            }
        }

        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .SMALL: return (6, 3)
            case .MEDIUM: return (8, 4)
            case .LARGE: return (12, 6)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, size.padding.horizontal)
            .padding(.vertical, size.padding.vertical)
            .background(color)
            .cornerRadius(12)
    }
}

// MARK: - ACTION BUTTON

struct ACTION_BUTTON: View {
    let title: String
    let icon: String?
    let color: Color
    var style: BUTTON_STYLE = .FILLED
    let action: () -> Void

    enum BUTTON_STYLE {
        case FILLED, OUTLINED, TEXT
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: APP_THEME.SPACING_SM) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(style == .FILLED ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(APP_THEME.SPACING_MD)
            .background(
                style == .FILLED ? color : (style == .OUTLINED ? Color.clear : Color.clear)
            )
            .overlay(
                style == .OUTLINED ?
                RoundedRectangle(cornerRadius: APP_THEME.RADIUS_MD)
                    .stroke(color, lineWidth: 2)
                : nil
            )
            .cornerRadius(APP_THEME.RADIUS_MD)
        }
    }
}

// MARK: - INFO CARD

struct INFO_CARD: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            Text(title)
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - STAT CARD

struct STAT_CARD: View {
    let label: String
    let value: String
    let change: Double?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            Text(label)
                .font(.caption)
                .foregroundColor(APP_THEME.TEXT_TERTIARY)

            HStack(alignment: .lastTextBaseline, spacing: APP_THEME.SPACING_SM) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(change)))
                    }
                    .font(.caption)
                    .foregroundColor(change >= 0 ? APP_THEME.SUCCESS : APP_THEME.ERROR)
                }
            }

            Rectangle()
                .fill(color)
                .frame(height: 4)
                .cornerRadius(2)
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - WORKFLOW STAGE INDICATOR

struct WORKFLOW_STAGE_INDICATOR: View {
    let currentStage: WORKFLOW_STAGE
    let showLabels: Bool

    init(currentStage: WORKFLOW_STAGE, showLabels: Bool = true) {
        self.currentStage = currentStage
        self.showLabels = showLabels
    }

    var body: some View {
        VStack(spacing: APP_THEME.SPACING_SM) {
            HStack(spacing: 0) {
                ForEach(Array(WORKFLOW_STAGE.allCases.enumerated()), id: \.element) { index, stage in
                    // Stage circle
                    ZStack {
                        Circle()
                            .fill(stage.rawValue <= currentStage.rawValue ? stage.color : APP_THEME.TEXT_TERTIARY.opacity(0.3))
                            .frame(width: 32, height: 32)

                        if stage == currentStage {
                            Circle()
                                .stroke(stage.color, lineWidth: 3)
                                .frame(width: 40, height: 40)
                        }
                    }

                    // Connector line
                    if index < WORKFLOW_STAGE.allCases.count - 1 {
                        Rectangle()
                            .fill(
                                stage.rawValue < currentStage.rawValue ?
                                currentStage.color :
                                APP_THEME.TEXT_TERTIARY.opacity(0.3)
                            )
                            .frame(height: 3)
                    }
                }
            }

            if showLabels {
                HStack {
                    ForEach(WORKFLOW_STAGE.allCases, id: \.self) { stage in
                        Text(stage.displayName)
                            .font(.caption2)
                            .foregroundColor(
                                stage == currentStage ?
                                stage.color :
                                APP_THEME.TEXT_TERTIARY
                            )
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - EMPTY STATE

struct EMPTY_STATE: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: APP_THEME.SPACING_LG) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(APP_THEME.TEXT_TERTIARY)

            VStack(spacing: APP_THEME.SPACING_SM) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                Text(message)
                    .font(.body)
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, APP_THEME.SPACING_XL)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, APP_THEME.SPACING_LG)
                        .padding(.vertical, APP_THEME.SPACING_MD)
                        .background(APP_THEME.PRIMARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(APP_THEME.SPACING_XL)
    }
}

// MARK: - LOADING INDICATOR

struct LOADING_INDICATOR: View {
    let message: String

    var body: some View {
        VStack(spacing: APP_THEME.SPACING_MD) {
            ProgressView()
                .tint(APP_THEME.PRIMARY)
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(APP_THEME.BG_PRIMARY.opacity(0.8))
    }
}

// MARK: - ADDRESS INPUT WITH AUTOCOMPLETE

struct ADDRESS_INPUT_FIELD: View {
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var coordinate: CLLocationCoordinate2D?

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingResults = false

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            Text("Address")
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)

            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)

                    TextField("Start typing address...", text: $searchText)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }

                    if isSearching {
                        ProgressView()
                            .tint(APP_THEME.PRIMARY)
                    } else if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            showingResults = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        }
                    }
                }
                .padding(APP_THEME.SPACING_MD)
                .background(APP_THEME.BG_TERTIARY)
                .cornerRadius(showingResults && !searchResults.isEmpty ? [.topLeft, .topRight] : .allCorners, APP_THEME.RADIUS_SM)

                // Results dropdown
                if showingResults && !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                            .background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(searchResults.prefix(5), id: \.self) { result in
                                    Button(action: {
                                        selectAddress(result)
                                    }) {
                                        HStack(spacing: APP_THEME.SPACING_SM) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(APP_THEME.PRIMARY)

                                            VStack(alignment: .leading, spacing: 2) {
                                                if let name = result.name {
                                                    Text(name)
                                                        .font(.body)
                                                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                                                }
                                                if let thoroughfare = result.placemark.thoroughfare {
                                                    Text(thoroughfare)
                                                        .font(.caption)
                                                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                                }
                                                if let locality = result.placemark.locality,
                                                   let state = result.placemark.administrativeArea {
                                                    Text("\(locality), \(state)")
                                                        .font(.caption2)
                                                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(APP_THEME.SPACING_SM)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if result != searchResults.prefix(5).last {
                                        Divider()
                                            .background(APP_THEME.TEXT_TERTIARY.opacity(0.2))
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .background(APP_THEME.BG_TERTIARY)
                    .cornerRadius([.bottomLeft, .bottomRight], APP_THEME.RADIUS_SM)
                }
            }

            // Selected address display
            if !address.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(APP_THEME.SUCCESS)
                            .font(.caption)

                        Text("Selected:")
                            .font(.caption)
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    }

                    Text(address)
                        .font(.body)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text("\(city), \(state) \(zipCode)")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
                .padding(APP_THEME.SPACING_SM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(APP_THEME.SUCCESS.opacity(0.1))
                .cornerRadius(APP_THEME.RADIUS_SM)
            }
        }
    }

    private func performSearch(query: String) {
        guard query.count > 2 else {
            searchResults = []
            showingResults = false
            return
        }

        isSearching = true
        showingResults = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false

            guard let response = response else {
                searchResults = []
                return
            }

            searchResults = response.mapItems
        }
    }

    private func selectAddress(_ mapItem: MKMapItem) {
        let placemark = mapItem.placemark

        // Extract address components - combine street number + street name
        var fullAddress = ""
        if let streetNumber = placemark.subThoroughfare {
            fullAddress = streetNumber
        }
        if let streetName = placemark.thoroughfare {
            if !fullAddress.isEmpty {
                fullAddress += " "
            }
            fullAddress += streetName
        }

        address = fullAddress
        city = placemark.locality ?? ""
        state = placemark.administrativeArea ?? ""
        zipCode = placemark.postalCode ?? ""
        coordinate = placemark.coordinate

        // Update search text to show full address
        searchText = "\(address), \(city), \(state) \(zipCode)"

        // Hide results
        showingResults = false
    }
}

// MARK: - CORNER RADIUS EXTENSION

extension View {
    func cornerRadius(_ corners: UIRectCorner, _ radius: CGFloat) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - PROTOCOL FOR DISPLAYABLE ENUMS

protocol DisplayableEnum {
    var displayName: String { get }
}

extension WORKFLOW_STAGE: DisplayableEnum {}
extension URGENCY_LEVEL: DisplayableEnum {}
extension LEAD_SOURCE: DisplayableEnum {}
extension CONTACT_METHOD: DisplayableEnum {}
extension SERVICE_TYPE: DisplayableEnum {}
