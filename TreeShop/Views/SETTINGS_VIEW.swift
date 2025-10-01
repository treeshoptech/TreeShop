import SwiftUI
import SwiftData

struct SETTINGS_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var companies: [COMPANY]
    @Query private var users: [USER_PROFILE]

    var company: COMPANY? {
        companies.first
    }

    var currentUser: USER_PROFILE? {
        users.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                List {
                    // Profile Section
                    Section {
                        if let user = currentUser {
                            NavigationLink(destination: USER_PROFILE_VIEW()) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(user.userRole.color.opacity(0.2))
                                            .frame(width: 50, height: 50)

                                        Text(user.initials)
                                            .font(.headline)
                                            .foregroundColor(user.userRole.color)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.fullName)
                                            .font(.headline)
                                            .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                        Text(user.userRole.rawValue)
                                            .font(.caption)
                                            .foregroundColor(APP_THEME.TEXT_SECONDARY)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // Company
                    Section("Company") {
                        NavigationLink(destination: COMPANY_SETTINGS_VIEW()) {
                            Label(company?.companyName ?? "Set Up Company", systemImage: "building.2.fill")
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        }
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // App Preferences
                    Section("Preferences") {
                        SETTING_ROW(icon: "paintbrush.fill", title: "Theme", value: "Dark", color: APP_THEME.PRIMARY)
                        SETTING_ROW(icon: "map.fill", title: "Default Map Type", value: "Standard", color: APP_THEME.INFO)
                        SETTING_ROW(icon: "ruler.fill", title: "Units", value: "Imperial", color: APP_THEME.WARNING)
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // Notifications
                    Section("Notifications") {
                        SETTING_TOGGLE(icon: "bell.fill", title: "Push Notifications", isOn: .constant(true), color: APP_THEME.ERROR)
                        SETTING_TOGGLE(icon: "envelope.fill", title: "Email Notifications", isOn: .constant(true), color: APP_THEME.INFO)
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // Data & Sync
                    Section("Data & Sync") {
                        SETTING_TOGGLE(icon: "icloud.fill", title: "Cloud Sync", isOn: .constant(true), color: APP_THEME.INFO)
                        SETTING_TOGGLE(icon: "arrow.clockwise.circle.fill", title: "Auto Backup", isOn: .constant(true), color: APP_THEME.SUCCESS)
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // Security
                    Section("Security & Privacy") {
                        SETTING_TOGGLE(icon: "faceid", title: "Face ID", isOn: .constant(false), color: APP_THEME.PRIMARY)
                        SETTING_TOGGLE(icon: "lock.fill", title: "Require PIN", isOn: .constant(false), color: APP_THEME.ERROR)
                        SETTING_TOGGLE(icon: "location.fill", title: "Location Tracking", isOn: .constant(true), color: APP_THEME.WARNING)
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)

                    // About
                    Section("About") {
                        SETTING_ROW(icon: "info.circle.fill", title: "Version", value: "1.0.0", color: APP_THEME.TEXT_TERTIARY)
                        SETTING_ROW(icon: "doc.text.fill", title: "Build", value: "1", color: APP_THEME.TEXT_TERTIARY)
                    }
                    .listRowBackground(APP_THEME.BG_SECONDARY)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - SETTING ROW

struct SETTING_ROW: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            Spacer()

            Text(value)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)
        }
    }
}

// MARK: - SETTING TOGGLE

struct SETTING_TOGGLE: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(APP_THEME.PRIMARY)
        }
    }
}
