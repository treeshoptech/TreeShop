import SwiftUI
import SwiftData

@Observable
class WORKFLOW_MANAGER {
    var leads: [LEAD] = []
    private var modelContext: ModelContext?

    init() {}

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        loadLeads()
    }

    // MARK: - LEAD OPERATIONS

    func createLead(_ lead: LEAD) {
        guard let context = modelContext else { return }
        context.insert(lead)
        saveContext()
        loadLeads()
    }

    func updateLead(_ lead: LEAD) {
        lead.lastModifiedDate = Date()
        saveContext()
        loadLeads()
    }

    func deleteLead(_ lead: LEAD) {
        guard let context = modelContext else { return }
        context.delete(lead)
        saveContext()
        loadLeads()
    }

    func archiveLead(_ lead: LEAD, reason: String? = nil) {
        lead.isArchived = true
        lead.isActive = false
        lead.lostReason = reason
        lead.lastModifiedDate = Date()
        saveContext()
        loadLeads()
    }

    // MARK: - WORKFLOW PROGRESSION

    func advanceStage(_ lead: LEAD, notes: String? = nil) {
        guard let nextStage = lead.currentStage.nextStage else { return }

        let transition = STAGE_TRANSITION(
            fromStage: lead.currentStage,
            toStage: nextStage,
            timestamp: Date(),
            notes: notes
        )

        lead.workflowStage = nextStage.rawValue
        lead.stageHistory.append(transition)
        lead.lastModifiedDate = Date()

        // Mark as converted when moving to PROPOSAL
        if nextStage == .PROPOSAL {
            lead.isConverted = true
        }

        saveContext()
        loadLeads()
    }

    func setStage(_ lead: LEAD, to stage: WORKFLOW_STAGE, notes: String? = nil) {
        let transition = STAGE_TRANSITION(
            fromStage: lead.currentStage,
            toStage: stage,
            timestamp: Date(),
            notes: notes
        )

        lead.workflowStage = stage.rawValue
        lead.stageHistory.append(transition)
        lead.lastModifiedDate = Date()

        saveContext()
        loadLeads()
    }

    // MARK: - FILTERING & QUERYING

    func getLeadsByStage(_ stage: WORKFLOW_STAGE) -> [LEAD] {
        leads.filter { $0.workflowStage == stage.rawValue }
    }

    func getActiveLeads() -> [LEAD] {
        leads.filter { $0.isActive && !$0.isArchived }
    }

    func getOverdueLeads() -> [LEAD] {
        leads.filter { $0.isOverdue && $0.isActive }
    }

    func getLeadsByUrgency(_ urgency: URGENCY_LEVEL) -> [LEAD] {
        leads.filter { $0.urgencyLevel == urgency.rawValue }
    }

    func getLeadsNeedingSiteVisit() -> [LEAD] {
        leads.filter { $0.needsSiteVisit && $0.siteVisitCompleted == nil }
    }

    func searchLeads(query: String) -> [LEAD] {
        let lowercased = query.lowercased()
        return leads.filter {
            $0.customerName.lowercased().contains(lowercased) ||
            $0.propertyAddress.lowercased().contains(lowercased) ||
            $0.customerPhone.contains(query)
        }
    }

    // MARK: - STATISTICS

    func getConversionRate() -> Double {
        let total = leads.count
        guard total > 0 else { return 0 }
        let converted = leads.filter { $0.isConverted }.count
        return Double(converted) / Double(total) * 100
    }

    func getAverageResponseTime() -> TimeInterval? {
        let respondedLeads = leads.filter { $0.lastContactDate != nil }
        guard !respondedLeads.isEmpty else { return nil }

        let totalTime = respondedLeads.reduce(0.0) { sum, lead in
            guard let contactDate = lead.lastContactDate else { return sum }
            return sum + contactDate.timeIntervalSince(lead.createdDate)
        }

        return totalTime / Double(respondedLeads.count)
    }

    func getLeadCountBySource() -> [LEAD_SOURCE: Int] {
        var counts: [LEAD_SOURCE: Int] = [:]
        for lead in leads {
            if let source = LEAD_SOURCE(rawValue: lead.leadSource) {
                counts[source, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: - PRIVATE METHODS

    private func loadLeads() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<LEAD>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )

        do {
            leads = try context.fetch(descriptor)
        } catch {
            print("Error loading leads: \(error)")
            leads = []
        }
    }

    private func saveContext() {
        guard let context = modelContext else { return }

        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
