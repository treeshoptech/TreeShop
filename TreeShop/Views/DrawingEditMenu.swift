//
//  DrawingEditMenu.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI

struct DrawingEditMenu: View {
    @Binding var drawing: Drawing
    let onDelete: () -> Void
    let onDismiss: () -> Void

    @State private var editedName: String = ""
    @State private var selectedColor: Color = .green
    @State private var opacity: Double = 0.7
    @State private var lineWidth: Double = 3.0

    let availableColors: [(String, Color)] = [
        ("Green", .green),
        ("Red", .red),
        ("Blue", .blue),
        ("Yellow", .yellow),
        ("Orange", .orange),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Cyan", .cyan),
        ("White", .white),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(.gray)

                            TextField("Drawing name", text: $editedName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundStyle(.white)
                        }

                        // Measurements (if applicable)
                        if let distance = drawing.distance {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Distance")
                                    .font(.headline)
                                    .foregroundStyle(.gray)

                                Text(formattedDistance(distance))
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let area = drawing.area {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Area")
                                    .font(.headline)
                                    .foregroundStyle(.gray)

                                Text(formattedArea(area))
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.headline)
                                .foregroundStyle(.gray)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                ForEach(availableColors, id: \.0) { name, color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                    }
                                }
                            }
                        }

                        // Opacity slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Opacity")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(Int(opacity * 100))%")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }

                            Slider(value: $opacity, in: 0.2...1.0)
                                .tint(.green)
                        }

                        // Line width slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Line Width")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(Int(lineWidth))pt")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }

                            Slider(value: $lineWidth, in: 1...10, step: 1)
                                .tint(.green)
                        }

                        // Delete button
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Drawing", systemImage: "trash.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(.green)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundStyle(.green)
                    .fontWeight(.semibold)
                }

                ToolbarItem(placement: .principal) {
                    Text("Edit Drawing")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            editedName = drawing.name
            selectedColor = drawing.color
            opacity = drawing.opacity
            lineWidth = drawing.lineWidth
        }
    }

    private func saveChanges() {
        drawing.name = editedName
        drawing.colorHex = selectedColor.hexString
        drawing.opacity = opacity
        drawing.lineWidth = lineWidth
        drawing.updatedAt = Date()
        onDismiss()
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
