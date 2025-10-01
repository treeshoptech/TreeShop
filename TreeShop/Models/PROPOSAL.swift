import SwiftUI
import SwiftData

@Model
final class PROPOSAL {
    // MARK: - IDENTIFICATION
    var id: UUID
    var proposalNumber: String // e.g., "PROP-2025-001"
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - LEAD REFERENCE
    var leadID: UUID
    var customerID: UUID?
    var customerName: String
    var customerPhone: String
    var customerEmail: String?

    // MARK: - PROPERTY
    var propertyID: UUID?
    var propertyAddress: String
    var propertyCity: String
    var propertyState: String
    var propertyZip: String

    // MARK: - LINE ITEMS
    var lineItems: [PROPOSAL_LINE_ITEM]
    var subtotal: Double
    var taxRate: Double
    var taxAmount: Double
    var totalAmount: Double

    // MARK: - PRICING BREAKDOWN
    var totalLaborCost: Double
    var totalEquipmentCost: Double
    var totalMaterialCost: Double
    var afissMultiplier: Double? // Complexity multiplier (hidden from customer)
    var profitMargin: Double

    // MARK: - CREW & EQUIPMENT ESTIMATE
    var estimatedCrewIDs: [String] // Employee IDs
    var estimatedEquipmentIDs: [String] // Equipment IDs
    var estimatedDuration: Double // Total hours
    var estimatedCrewCost: Double // Total crew hourly cost
    var estimatedEquipmentCostHourly: Double // Total equipment hourly cost

    // MARK: - DOCUMENT
    var proposalPDFURL: String?
    var proposalHTML: String?
    var proposalNotes: String?
    var internalNotes: String? // Not shown to customer

    // MARK: - STATUS
    var proposalStatus: String // "Draft", "Sent", "Viewed", "Accepted", "Declined", "Expired"
    var sentDate: Date?
    var viewedDate: Date?
    var acceptedDate: Date?
    var declinedDate: Date?
    var expirationDate: Date?
    var declineReason: String?

    // MARK: - PAYMENT TERMS
    var paymentTerms: String // "Net 30", "Due on receipt", "50% deposit"
    var depositRequired: Double?
    var depositPaid: Bool
    var depositPaidDate: Date?

    // MARK: - CONVERSION
    var convertedToWorkOrder: Bool
    var workOrderID: UUID?
    var conversionDate: Date?

    // MARK: - INITIALIZER
    init(
        leadID: UUID,
        customerName: String,
        customerPhone: String,
        customerEmail: String?,
        propertyAddress: String,
        propertyCity: String,
        propertyState: String,
        propertyZip: String,
        lineItems: [PROPOSAL_LINE_ITEM],
        taxRate: Double = 0.0
    ) {
        self.id = UUID()

        // Generate proposal number
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        self.proposalNumber = "PROP-\(dateString)-\(UUID().uuidString.prefix(4))"

        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Lead reference
        self.leadID = leadID
        self.customerID = nil
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.customerEmail = customerEmail

        // Property
        self.propertyID = nil
        self.propertyAddress = propertyAddress
        self.propertyCity = propertyCity
        self.propertyState = propertyState
        self.propertyZip = propertyZip

        // Line items
        self.lineItems = lineItems

        // Calculate totals
        let itemsSubtotal = lineItems.reduce(0.0) { $0 + $1.totalPrice }
        let calculatedTaxAmount = itemsSubtotal * taxRate
        let calculatedTotal = itemsSubtotal + calculatedTaxAmount

        self.subtotal = itemsSubtotal
        self.taxRate = taxRate
        self.taxAmount = calculatedTaxAmount
        self.totalAmount = calculatedTotal

        // Pricing breakdown
        let laborCost = lineItems.reduce(0.0) { $0 + $1.laborCost }
        let equipmentCost = lineItems.reduce(0.0) { $0 + $1.equipmentCost }
        let materialCost = lineItems.reduce(0.0) { $0 + $1.materialCost }
        let totalCost = laborCost + equipmentCost + materialCost

        self.totalLaborCost = laborCost
        self.totalEquipmentCost = equipmentCost
        self.totalMaterialCost = materialCost
        self.afissMultiplier = nil
        self.profitMargin = totalCost > 0 ? (itemsSubtotal - totalCost) / totalCost : 0.0

        // Estimates
        self.estimatedCrewIDs = []
        self.estimatedEquipmentIDs = []
        self.estimatedDuration = lineItems.reduce(0.0) { $0 + $1.estimatedHours }
        self.estimatedCrewCost = 0.0
        self.estimatedEquipmentCostHourly = 0.0

        // Document
        self.proposalPDFURL = nil
        self.proposalHTML = nil
        self.proposalNotes = nil
        self.internalNotes = nil

        // Status
        self.proposalStatus = "Draft"
        self.sentDate = nil
        self.viewedDate = nil
        self.acceptedDate = nil
        self.declinedDate = nil
        self.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        self.declineReason = nil

        // Payment
        self.paymentTerms = "Due on receipt"
        self.depositRequired = nil
        self.depositPaid = false
        self.depositPaidDate = nil

        // Conversion
        self.convertedToWorkOrder = false
        self.workOrderID = nil
        self.conversionDate = nil
    }

    // MARK: - METHODS
    func markAsSent() {
        proposalStatus = "Sent"
        sentDate = Date()
        lastModifiedDate = Date()
    }

    func markAsViewed() {
        if proposalStatus == "Sent" {
            proposalStatus = "Viewed"
        }
        viewedDate = Date()
        lastModifiedDate = Date()
    }

    func markAsAccepted() {
        proposalStatus = "Accepted"
        acceptedDate = Date()
        lastModifiedDate = Date()
    }

    func markAsDeclined(reason: String?) {
        proposalStatus = "Declined"
        declinedDate = Date()
        declineReason = reason
        lastModifiedDate = Date()
    }

    func recalculateTotals() {
        subtotal = lineItems.reduce(0.0) { $0 + $1.totalPrice }
        taxAmount = subtotal * taxRate
        totalAmount = subtotal + taxAmount

        totalLaborCost = lineItems.reduce(0.0) { $0 + $1.laborCost }
        totalEquipmentCost = lineItems.reduce(0.0) { $0 + $1.equipmentCost }
        totalMaterialCost = lineItems.reduce(0.0) { $0 + $1.materialCost }
        estimatedDuration = lineItems.reduce(0.0) { $0 + $1.estimatedHours }

        let totalCost = totalLaborCost + totalEquipmentCost + totalMaterialCost
        profitMargin = totalCost > 0 ? (subtotal - totalCost) / totalCost : 0.0

        lastModifiedDate = Date()
    }
}

// MARK: - PROPOSAL LINE ITEM

struct PROPOSAL_LINE_ITEM: Codable, Identifiable {
    var id: UUID
    var itemNumber: Int
    var serviceType: String // SERVICE_TYPE raw value
    var description: String
    var quantity: Int
    var unitOfMeasure: String // "each", "hour", "acre", "tree"
    var unitPrice: Double
    var totalPrice: Double

    // Cost breakdown (hidden from customer)
    var laborCost: Double
    var equipmentCost: Double
    var materialCost: Double
    var estimatedHours: Double

    // TreeScore reference (if applicable)
    var treeScorePoints: Double?
    var treeIDs: [String] // Trees this line item covers

    init(
        itemNumber: Int,
        serviceType: SERVICE_TYPE,
        description: String,
        quantity: Int,
        unitOfMeasure: String,
        unitPrice: Double,
        laborCost: Double,
        equipmentCost: Double,
        materialCost: Double,
        estimatedHours: Double
    ) {
        self.id = UUID()
        self.itemNumber = itemNumber
        self.serviceType = serviceType.rawValue
        self.description = description
        self.quantity = quantity
        self.unitOfMeasure = unitOfMeasure
        self.unitPrice = unitPrice
        self.totalPrice = Double(quantity) * unitPrice
        self.laborCost = laborCost
        self.equipmentCost = equipmentCost
        self.materialCost = materialCost
        self.estimatedHours = estimatedHours
        self.treeScorePoints = nil
        self.treeIDs = []
    }
}
