//
//  MeasurementOverlay.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI
import MapKit

struct MeasurementOverlay: View {
    let drawings: [Drawing]
    let currentDrawing: Drawing?

    var body: some View {
        ZStack {
            // Show current drawing measurement
            if let current = currentDrawing {
                if let distance = current.distance, current.type == .distance {
                    Text(formattedDistance(distance))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green, in: Capsule())
                        .shadow(radius: 4)
                        .position(x: UIScreen.main.bounds.width / 2, y: 120)
                } else if let area = current.area, current.type == .area {
                    Text(formattedArea(area))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green, in: Capsule())
                        .shadow(radius: 4)
                        .position(x: UIScreen.main.bounds.width / 2, y: 120)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func formattedDistance(_ meters: Double) -> String {
        let feet = meters * 3.28084
        if feet < 5280 {
            return String(format: "%.1f ft", feet)
        } else {
            let miles = feet / 5280
            return String(format: "%.2f mi", miles)
        }
    }

    private func formattedArea(_ squareMeters: Double) -> String {
        let sqFeet = squareMeters * 10.7639
        if sqFeet < 43560 {
            return String(format: "%.0f sq ft", sqFeet)
        } else {
            let acres = sqFeet / 43560
            return String(format: "%.2f acres", acres)
        }
    }
}
