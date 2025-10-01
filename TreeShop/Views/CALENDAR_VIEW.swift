import SwiftUI
import SwiftData

struct CALENDAR_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SCHEDULED_JOB.scheduledDate) private var scheduledJobs: [SCHEDULED_JOB]

    @State private var selectedDate = Date()
    @State private var showingAddJob = false

    var jobsForSelectedDate: [SCHEDULED_JOB] {
        scheduledJobs.filter { job in
            Calendar.current.isDate(job.scheduledDate, inSameDayAs: selectedDate)
        }
    }

    var todaysJobs: [SCHEDULED_JOB] {
        scheduledJobs.filter { $0.isToday }
    }

    var upcomingJobs: [SCHEDULED_JOB] {
        scheduledJobs.filter { !$0.isPast && !$0.isToday }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Today's Jobs
                        if !todaysJobs.isEmpty {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                                Text("Today")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                ForEach(todaysJobs) { job in
                                    JOB_CALENDAR_CARD(job: job)
                                }
                            }
                        }

                        // Tomorrow's Jobs
                        if !scheduledJobs.filter({ $0.isTomorrow }).isEmpty {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                                Text("Tomorrow")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                ForEach(scheduledJobs.filter { $0.isTomorrow }) { job in
                                    JOB_CALENDAR_CARD(job: job)
                                }
                            }
                        }

                        // Upcoming
                        if !upcomingJobs.filter({ !$0.isTomorrow }).isEmpty {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                                Text("Upcoming")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                ForEach(upcomingJobs.filter { !$0.isTomorrow }.prefix(10)) { job in
                                    JOB_CALENDAR_CARD(job: job)
                                }
                            }
                        }

                        if scheduledJobs.isEmpty {
                            EMPTY_STATE(
                                icon: "calendar.badge.clock",
                                title: "No Scheduled Jobs",
                                message: "Jobs will appear here once work orders are scheduled"
                            )
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddJob = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - JOB CALENDAR CARD

struct JOB_CALENDAR_CARD: View {
    let job: SCHEDULED_JOB

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.customerName)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text(job.propertyAddress)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                STATUS_BADGE(
                    text: job.jobStatus,
                    color: job.isInProgress ? APP_THEME.SUCCESS : (job.isCompleted ? Color.gray : WORKFLOW_COLORS.WORK_ORDER),
                    size: .SMALL
                )
            }

            Divider().background(APP_THEME.TEXT_TERTIARY.opacity(0.3))

            HStack(spacing: APP_THEME.SPACING_MD) {
                Label(job.scheduledStartTime.formatted(date: .omitted, time: .shortened), systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)

                Label("\(String(format: "%.1f", job.estimatedDuration))h", systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)

                if job.crewCount > 0 {
                    Label("\(job.crewCount) crew", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(APP_THEME.PRIMARY)
                }

                if job.equipmentCount > 0 {
                    Label("\(job.equipmentCount) equipment", systemImage: "wrench.fill")
                        .font(.caption)
                        .foregroundColor(APP_THEME.WARNING)
                }

                Spacer()
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}
