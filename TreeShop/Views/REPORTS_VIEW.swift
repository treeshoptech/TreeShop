import SwiftUI
import SwiftData

struct REPORTS_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var leads: [LEAD]
    @Query private var customers: [CUSTOMER]
    @Query private var properties: [PROPERTY]
    @Query private var trees: [TREE]
    @Query private var employees: [EMPLOYEE]
    @Query private var equipment: [EQUIPMENT]
    @Query private var timeEntries: [TIME_ENTRY]

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Marketing & Leads
                        REPORT_SECTION(title: "Marketing & Leads", icon: "chart.line.uptrend.xyaxis", color: WORKFLOW_COLORS.LEAD) {
                            HStack(spacing: APP_THEME.SPACING_MD) {
                                STAT_CARD(
                                    label: "Total Leads",
                                    value: "\(leads.count)",
                                    change: nil,
                                    color: WORKFLOW_COLORS.LEAD
                                )

                                STAT_CARD(
                                    label: "Active Leads",
                                    value: "\(leads.filter { $0.isActive }.count)",
                                    change: nil,
                                    color: WORKFLOW_COLORS.LEAD
                                )
                            }

                            STAT_CARD(
                                label: "Conversion Rate",
                                value: "\(calculateConversionRate())%",
                                change: nil,
                                color: APP_THEME.SUCCESS
                            )
                        }

                        // Customers
                        REPORT_SECTION(title: "Customers", icon: "person.2.fill", color: APP_THEME.INFO) {
                            HStack(spacing: APP_THEME.SPACING_MD) {
                                STAT_CARD(
                                    label: "Total Customers",
                                    value: "\(customers.count)",
                                    change: nil,
                                    color: APP_THEME.INFO
                                )

                                STAT_CARD(
                                    label: "Repeat Customers",
                                    value: "\(customers.filter { $0.isRepeatCustomer }.count)",
                                    change: nil,
                                    color: APP_THEME.SUCCESS
                                )
                            }

                            STAT_CARD(
                                label: "Total Revenue",
                                value: "$\(formatRevenue(customers.reduce(0) { $0 + $1.totalRevenue }))",
                                change: nil,
                                color: APP_THEME.SUCCESS
                            )

                            STAT_CARD(
                                label: "Average CLV",
                                value: "$\(formatRevenue(calculateAverageCLV()))",
                                change: nil,
                                color: APP_THEME.WARNING
                            )
                        }

                        // Operations
                        REPORT_SECTION(title: "Operations", icon: "checkmark.circle.fill", color: APP_THEME.PRIMARY) {
                            HStack(spacing: APP_THEME.SPACING_MD) {
                                STAT_CARD(
                                    label: "Properties",
                                    value: "\(properties.count)",
                                    change: nil,
                                    color: APP_THEME.PRIMARY
                                )

                                STAT_CARD(
                                    label: "Trees Scored",
                                    value: "\(trees.count)",
                                    change: nil,
                                    color: APP_THEME.SUCCESS
                                )
                            }

                            HStack(spacing: APP_THEME.SPACING_MD) {
                                STAT_CARD(
                                    label: "Jobs Completed",
                                    value: "\(calculateTotalJobs())",
                                    change: nil,
                                    color: WORKFLOW_COLORS.WORK_ORDER
                                )

                                STAT_CARD(
                                    label: "Equipment",
                                    value: "\(equipment.count)",
                                    change: nil,
                                    color: APP_THEME.WARNING
                                )
                            }
                        }

                        // Team Performance
                        if !employees.isEmpty {
                            REPORT_SECTION(title: "Team", icon: "person.3.fill", color: APP_THEME.SUCCESS) {
                                STAT_CARD(
                                    label: "Total Employees",
                                    value: "\(employees.filter { $0.employmentStatus == "Active" }.count)",
                                    change: nil,
                                    color: APP_THEME.PRIMARY
                                )

                                if let avgPpH = calculateAveragePpH() {
                                    STAT_CARD(
                                        label: "Average PpH",
                                        value: "\(Int(avgPpH))",
                                        change: nil,
                                        color: APP_THEME.SUCCESS
                                    )
                                }

                                STAT_CARD(
                                    label: "Total Hours Worked",
                                    value: String(format: "%.0f", employees.reduce(0) { $0 + $1.totalHoursWorked }),
                                    change: nil,
                                    color: APP_THEME.INFO
                                )
                            }
                        }

                        // Time Tracking
                        if !timeEntries.isEmpty {
                            REPORT_SECTION(title: "Time Tracking", icon: "clock.fill", color: APP_THEME.WARNING) {
                                HStack(spacing: APP_THEME.SPACING_MD) {
                                    STAT_CARD(
                                        label: "Total Hours",
                                        value: String(format: "%.0f", timeEntries.reduce(0) { $0 + $1.duration }),
                                        change: nil,
                                        color: APP_THEME.WARNING
                                    )

                                    STAT_CARD(
                                        label: "Billable Hours",
                                        value: String(format: "%.0f", timeEntries.filter { $0.isBillable }.reduce(0) { $0 + $1.duration }),
                                        change: nil,
                                        color: APP_THEME.SUCCESS
                                    )
                                }
                            }
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Reports")
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - CALCULATIONS

    func calculateConversionRate() -> Int {
        guard leads.count > 0 else { return 0 }
        let converted = leads.filter { $0.isConverted }.count
        return Int((Double(converted) / Double(leads.count)) * 100)
    }

    func calculateAverageCLV() -> Double {
        guard !customers.isEmpty else { return 0 }
        let total = customers.reduce(0.0) { $0 + $1.lifetimeValue }
        return total / Double(customers.count)
    }

    func calculateTotalJobs() -> Int {
        customers.reduce(0) { $0 + $1.totalJobsCompleted }
    }

    func calculateAveragePpH() -> Double? {
        let employeesWithPpH = employees.filter { $0.averagePpH > 0 }
        guard !employeesWithPpH.isEmpty else { return nil }
        let total = employeesWithPpH.reduce(0.0) { $0 + $1.averagePpH }
        return total / Double(employeesWithPpH.count)
    }

    func formatRevenue(_ value: Double) -> String {
        if value >= 1000000 {
            return String(format: "%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - REPORT SECTION

struct REPORT_SECTION<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)
            }

            content
        }
    }
}
