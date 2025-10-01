//
//  DrawingToolbar.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI

struct DrawingToolbar: View {
    @Binding var activeDrawingType: DrawingType?
    let isDrawing: Bool
    let onStartDrawing: (DrawingType) -> Void
    let onFinishDrawing: () -> Void
    let onCancelDrawing: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isDrawing {
                // Drawing in progress - show finish/cancel
                Button {
                    onFinishDrawing()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .background(.green, in: Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                Button {
                    onCancelDrawing()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .background(.red, in: Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            } else {
                // Show drawing tool options
                ForEach([DrawingType.distance, DrawingType.area], id: \.self) { type in
                    Button {
                        onStartDrawing(type)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.title2)
                            Text(type == .distance ? "Distance" : "Area")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                }
            }
        }
    }
}
