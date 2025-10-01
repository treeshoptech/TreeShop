import SwiftUI
import SwiftData
import MapKit

@Model
final class PROPERTY {
    // MARK: - IDENTIFICATION
    var id: UUID
    var createdDate: Date
    var lastModifiedDate: Date

    // MARK: - LOCATION
    var propertyAddress: String
    var city: String
    var state: String
    var zipCode: String
    var latitude: Double
    var longitude: Double

    // MARK: - PROPERTY DETAILS
    var propertyType: String // "Residential", "Commercial", "Municipal", etc.
    var acreage: Double?
    var parcelNumber: String?
    var lotSize: String?

    // MARK: - OWNERSHIP
    var customerID: UUID? // Link to CUSTOMER
    var ownerName: String? // From public records if different from customer
    var ownershipType: String? // "Owner Occupied", "Rental", "Investment"

    // MARK: - PARCEL DATA
    var parcelBoundaryCoordinates: [PARCEL_COORDINATE] // Polygon vertices
    var hasParcelBoundary: Bool

    // MARK: - TREES ON PROPERTY
    var treeIDs: [String] // UUIDs of trees on this property
    var treeCount: Int
    var totalTreeScore: Double // Sum of all tree scores
    var totalTrimScore: Double // Sum of all trim scores

    // MARK: - JOB HISTORY
    var leadIDs: [String]
    var proposalIDs: [String]
    var workOrderIDs: [String]
    var invoiceIDs: [String]
    var jobsCompleted: Int
    var totalRevenueFromProperty: Double
    var firstJobDate: Date?
    var lastJobDate: Date?

    // MARK: - AFISS ASSESSMENT
    var afissAssessmentDate: Date?
    var afissAssessorID: UUID?
    var afissStructuresScore: Double?
    var afissLandscapeScore: Double?
    var afissUtilitiesScore: Double?
    var afissAccessScore: Double?
    var afissProjectSpecificScore: Double?
    var afissTotalMultiplier: Double?
    var afissNotes: String?

    // MARK: - SITE CHARACTERISTICS
    var accessType: String? // "Easy", "Moderate", "Difficult", "Crane Required"
    var utilitiesPresent: [String] // "Power Lines", "Gas Lines", "Water Lines", etc.
    var structuresNearby: [String] // "House", "Garage", "Pool", "Fence", etc.
    var groundConditions: String? // "Flat", "Sloped", "Wet", "Rocky"
    var parkingAvailable: String? // "Street", "Driveway", "None"

    // MARK: - PHOTOS & MEDIA
    var photoURLs: [String]
    var documentURLs: [String]
    var videoURLs: [String]

    // MARK: - NOTES & HISTORY
    var propertyNotes: String?
    var hazardsIdentified: [String]
    var specialInstructions: String?
    var gateCode: String?
    var keyLocation: String?

    // MARK: - STATUS
    var isActive: Bool
    var lastVisitDate: Date?
    var nextScheduledDate: Date?

    // MARK: - INITIALIZER
    init(
        propertyAddress: String,
        city: String,
        state: String,
        zipCode: String,
        latitude: Double,
        longitude: Double,
        propertyType: CUSTOMER_TYPE = .RESIDENTIAL,
        customerID: UUID? = nil
    ) {
        self.id = UUID()
        self.createdDate = Date()
        self.lastModifiedDate = Date()

        // Location
        self.propertyAddress = propertyAddress
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude

        // Property details
        self.propertyType = propertyType.rawValue
        self.acreage = nil
        self.parcelNumber = nil
        self.lotSize = nil

        // Ownership
        self.customerID = customerID
        self.ownerName = nil
        self.ownershipType = nil

        // Parcel data
        self.parcelBoundaryCoordinates = []
        self.hasParcelBoundary = false

        // Trees
        self.treeIDs = []
        self.treeCount = 0
        self.totalTreeScore = 0.0
        self.totalTrimScore = 0.0

        // Job history
        self.leadIDs = []
        self.proposalIDs = []
        self.workOrderIDs = []
        self.invoiceIDs = []
        self.jobsCompleted = 0
        self.totalRevenueFromProperty = 0.0
        self.firstJobDate = nil
        self.lastJobDate = nil

        // AFISS
        self.afissAssessmentDate = nil
        self.afissAssessorID = nil
        self.afissStructuresScore = nil
        self.afissLandscapeScore = nil
        self.afissUtilitiesScore = nil
        self.afissAccessScore = nil
        self.afissProjectSpecificScore = nil
        self.afissTotalMultiplier = nil
        self.afissNotes = nil

        // Site characteristics
        self.accessType = nil
        self.utilitiesPresent = []
        self.structuresNearby = []
        self.groundConditions = nil
        self.parkingAvailable = nil

        // Media
        self.photoURLs = []
        self.documentURLs = []
        self.videoURLs = []

        // Notes
        self.propertyNotes = nil
        self.hazardsIdentified = []
        self.specialInstructions = nil
        self.gateCode = nil
        self.keyLocation = nil

        // Status
        self.isActive = true
        self.lastVisitDate = nil
        self.nextScheduledDate = nil
    }

    // MARK: - COMPUTED PROPERTIES
    var fullAddress: String {
        "\(propertyAddress), \(city), \(state) \(zipCode)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasAFISSAssessment: Bool {
        afissAssessmentDate != nil
    }

    var averageRevenuePerJob: Double {
        guard jobsCompleted > 0 else { return 0.0 }
        return totalRevenueFromProperty / Double(jobsCompleted)
    }

    // MARK: - METHODS
    func addTree(treeID: UUID) {
        if !treeIDs.contains(treeID.uuidString) {
            treeIDs.append(treeID.uuidString)
            treeCount = treeIDs.count
            lastModifiedDate = Date()
        }
    }

    func removeTree(treeID: UUID) {
        treeIDs.removeAll { $0 == treeID.uuidString }
        treeCount = treeIDs.count
        lastModifiedDate = Date()
    }

    func addJob(revenue: Double, jobDate: Date) {
        jobsCompleted += 1
        totalRevenueFromProperty += revenue

        if firstJobDate == nil {
            firstJobDate = jobDate
        }
        lastJobDate = jobDate
        lastVisitDate = jobDate

        lastModifiedDate = Date()
    }

    func updateAFISS(
        structures: Double,
        landscape: Double,
        utilities: Double,
        access: Double,
        projectSpecific: Double
    ) {
        afissStructuresScore = structures
        afissLandscapeScore = landscape
        afissUtilitiesScore = utilities
        afissAccessScore = access
        afissProjectSpecificScore = projectSpecific
        afissTotalMultiplier = 1.0 + structures + landscape + utilities + access + projectSpecific
        afissAssessmentDate = Date()
        lastModifiedDate = Date()
    }
}

// MARK: - PARCEL COORDINATE

struct PARCEL_COORDINATE: Codable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
