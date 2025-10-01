//
//  Drawing.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData
import MapKit
import SwiftUI

@Model
final class Drawing {
    @Attribute(.unique) var id: UUID
    var type: DrawingType
    var name: String
    var colorHex: String
    var opacity: Double
    var lineWidth: Double
    var coordinates: [Coordinate]
    var createdAt: Date
    var updatedAt: Date

    // Computed properties
    var color: Color {
        Color(hex: colorHex) ?? .green
    }

    var distance: Double? {
        guard type == .distance, coordinates.count >= 2 else { return nil }
        return calculateTotalDistance()
    }

    var area: Double? {
        guard type == .area, coordinates.count >= 3 else { return nil }
        return calculateArea()
    }

    init(type: DrawingType, name: String = "", colorHex: String = "#00FF00", opacity: Double = 0.7, lineWidth: Double = 3.0) {
        self.id = UUID()
        self.type = type
        self.name = name.isEmpty ? type.defaultName : name
        self.colorHex = colorHex
        self.opacity = opacity
        self.lineWidth = lineWidth
        self.coordinates = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func addCoordinate(_ coordinate: CLLocationCoordinate2D) {
        coordinates.append(Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
        updatedAt = Date()
    }

    func updateCoordinate(at index: Int, to coordinate: CLLocationCoordinate2D) {
        guard index < coordinates.count else { return }
        coordinates[index] = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        updatedAt = Date()
    }

    func removeLastCoordinate() {
        guard !coordinates.isEmpty else { return }
        coordinates.removeLast()
        updatedAt = Date()
    }

    // MARK: - Calculations

    private func calculateTotalDistance() -> Double {
        var total: Double = 0
        for i in 0..<(coordinates.count - 1) {
            let start = coordinates[i].clLocationCoordinate
            let end = coordinates[i + 1].clLocationCoordinate
            let location1 = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let location2 = CLLocation(latitude: end.latitude, longitude: end.longitude)
            total += location2.distance(from: location1)
        }
        return total // meters
    }

    private func calculateArea() -> Double {
        guard coordinates.count >= 3 else { return 0 }

        // Shoelace formula for polygon area
        var area: Double = 0
        let coords = coordinates.map { $0.clLocationCoordinate }

        for i in 0..<coords.count {
            let j = (i + 1) % coords.count
            area += coords[i].longitude * coords[j].latitude
            area -= coords[j].longitude * coords[i].latitude
        }

        area = abs(area) / 2.0

        // Convert from degrees² to meters² (approximate)
        let latInMeters = 111320.0 // meters per degree latitude
        let lonInMeters = cos(coords[0].latitude * .pi / 180.0) * 111320.0
        return area * latInMeters * lonInMeters
    }
}

// MARK: - Supporting Types

enum DrawingType: String, Codable {
    case distance
    case area
    case freehand

    var defaultName: String {
        switch self {
        case .distance: return "Distance Measurement"
        case .area: return "Area Measurement"
        case .freehand: return "Drawing"
        }
    }

    var icon: String {
        switch self {
        case .distance: return "ruler"
        case .area: return "square.on.square.dashed"
        case .freehand: return "pencil.line"
        }
    }
}

@Model
final class Coordinate {
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
