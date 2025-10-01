//
//  DrawingViewModel.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData
import MapKit
import SwiftUI

@Observable
final class DrawingViewModel {
    private let modelContext: ModelContext

    // Current drawing state
    var currentDrawing: Drawing?
    var activeDrawingType: DrawingType?
    var isDrawing: Bool = false

    // All drawings
    private(set) var drawings: [Drawing] = []

    // Selection & editing
    var selectedDrawing: Drawing?
    var showingEditMenu: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDrawings()
    }

    // MARK: - Drawing Management

    func startDrawing(type: DrawingType) {
        let drawing = Drawing(type: type)
        currentDrawing = drawing
        activeDrawingType = type
        isDrawing = true
    }

    func addPoint(_ coordinate: CLLocationCoordinate2D) {
        guard let drawing = currentDrawing else { return }

        // For area drawings, check if user tapped near the first point to close polygon
        if drawing.type == .area, drawing.coordinates.count >= 3 {
            let firstCoord = drawing.coordinates[0].clLocationCoordinate
            let location1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let location2 = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)

            // If tapped within 30 meters of first point, close the polygon
            if location1.distance(from: location2) < 30 {
                finishDrawing()
                return
            }
        }

        drawing.addCoordinate(coordinate)
    }

    func finishDrawing() {
        guard let drawing = currentDrawing else { return }

        // Validate drawing has enough points
        switch drawing.type {
        case .distance:
            guard drawing.coordinates.count >= 2 else {
                cancelDrawing()
                return
            }
        case .area:
            guard drawing.coordinates.count >= 3 else {
                cancelDrawing()
                return
            }
        case .freehand:
            guard drawing.coordinates.count >= 2 else {
                cancelDrawing()
                return
            }
        }

        // Save drawing
        modelContext.insert(drawing)
        try? modelContext.save()

        // Reset state
        currentDrawing = nil
        activeDrawingType = nil
        isDrawing = false

        loadDrawings()
    }

    func cancelDrawing() {
        currentDrawing = nil
        activeDrawingType = nil
        isDrawing = false
    }

    func deleteDrawing(_ drawing: Drawing) {
        modelContext.delete(drawing)
        try? modelContext.save()
        loadDrawings()

        if selectedDrawing?.id == drawing.id {
            selectedDrawing = nil
        }
    }

    func updateDrawing(_ drawing: Drawing, name: String? = nil, colorHex: String? = nil, opacity: Double? = nil, lineWidth: Double? = nil) {
        if let name = name {
            drawing.name = name
        }
        if let colorHex = colorHex {
            drawing.colorHex = colorHex
        }
        if let opacity = opacity {
            drawing.opacity = opacity
        }
        if let lineWidth = lineWidth {
            drawing.lineWidth = lineWidth
        }

        drawing.updatedAt = Date()
        try? modelContext.save()
        loadDrawings()
    }

    // MARK: - Selection

    func selectDrawing(_ drawing: Drawing, at location: CGPoint) {
        selectedDrawing = drawing
        showingEditMenu = true
    }

    func deselectDrawing() {
        selectedDrawing = nil
        showingEditMenu = false
    }

    // MARK: - Data Loading

    private func loadDrawings() {
        let descriptor = FetchDescriptor<Drawing>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        drawings = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Formatting Helpers

    func formattedDistance(_ meters: Double) -> String {
        let feet = meters * 3.28084
        if feet < 5280 {
            return String(format: "%.1f ft", feet)
        } else {
            let miles = feet / 5280
            return String(format: "%.2f mi", miles)
        }
    }

    func formattedArea(_ squareMeters: Double) -> String {
        let sqFeet = squareMeters * 10.7639
        if sqFeet < 43560 {
            return String(format: "%.1f sq ft", sqFeet)
        } else {
            let acres = sqFeet / 43560
            return String(format: "%.2f acres", acres)
        }
    }
}
