import SwiftUI
import MapKit

struct ADDRESS_SEARCH_VIEW: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Search card
            VStack(spacing: 0) {
                // Search header
                HStack(spacing: APP_THEME.SPACING_MD) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                    TextField("Search address...", text: $searchText)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        }
                    }

                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
                .padding(APP_THEME.SPACING_MD)
                .background(APP_THEME.BG_SECONDARY)

                Divider()
                    .background(APP_THEME.TEXT_TERTIARY)

                // Results list
                if isSearching {
                    HStack {
                        ProgressView()
                            .tint(APP_THEME.PRIMARY)
                        Text("Searching...")
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(APP_THEME.SPACING_LG)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        Text("No results found")
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(APP_THEME.SPACING_XL)
                } else if searchText.isEmpty {
                    VStack(spacing: APP_THEME.SPACING_SM) {
                        Image(systemName: "map")
                            .font(.system(size: 48))
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        Text("Search for an address")
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(APP_THEME.SPACING_XL)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchResults, id: \.self) { result in
                                ADDRESS_RESULT_ROW(mapItem: result) {
                                    handleResultSelection(result)
                                }

                                if result != searchResults.last {
                                    Divider()
                                        .background(APP_THEME.TEXT_TERTIARY.opacity(0.3))
                                        .padding(.leading, APP_THEME.SPACING_MD)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxHeight: 500)
            .background(APP_THEME.BG_PRIMARY)
            .cornerRadius(APP_THEME.RADIUS_LG)
            .shadow(color: APP_THEME.SHADOW_LG, radius: 20)
            .padding(APP_THEME.SPACING_MD)
        }
        .transition(.opacity)
        .animation(.spring(response: 0.3), value: isPresented)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address

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

    private func handleResultSelection(_ mapItem: MKMapItem) {
        // Post notification to zoom map to selected location
        NotificationCenter.default.post(
            name: NSNotification.Name("ZoomToLocation"),
            object: nil,
            userInfo: ["coordinate": mapItem.placemark.coordinate]
        )

        isPresented = false
    }
}

// MARK: - ADDRESS RESULT ROW

struct ADDRESS_RESULT_ROW: View {
    let mapItem: MKMapItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: APP_THEME.SPACING_MD) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(APP_THEME.PRIMARY)

                VStack(alignment: .leading, spacing: 4) {
                    if let name = mapItem.name {
                        Text(name)
                            .font(.body)
                            .foregroundColor(APP_THEME.TEXT_PRIMARY)
                    }

                    if let thoroughfare = mapItem.placemark.thoroughfare {
                        Text(thoroughfare)
                            .font(.subheadline)
                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                    }

                    if let locality = mapItem.placemark.locality,
                       let state = mapItem.placemark.administrativeArea {
                        Text("\(locality), \(state)")
                            .font(.caption)
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
            }
            .padding(APP_THEME.SPACING_MD)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
