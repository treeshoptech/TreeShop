//
//  MapView.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingProfile = false
    @State private var drawingViewModel: DrawingViewModel?
    @State private var selectedDrawing: Drawing?
    @State private var showingEditMenu = false

    var body: some View {
        ZStack {
            // Interactive Map with tap/long-press gestures
            InteractiveMapView(
                region: $region,
                drawings: drawingViewModel?.drawings ?? [],
                currentDrawing: drawingViewModel?.currentDrawing,
                onTap: { coordinate in
                    handleMapTap(coordinate)
                },
                onLongPress: { coordinate, drawing in
                    handleLongPress(coordinate, drawing: drawing)
                }
            )
            .ignoresSafeArea()

            // Top Bar
            VStack {
                HStack {
                    // Logo
                    HStack(spacing: 8) {
                        Image(systemName: "tree.fill")
                            .foregroundStyle(.green)
                        Text("TreeShop")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    // Profile Button
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                }
                .padding()

                Spacer()
            }

            // Measurement Display Overlay
            if let vm = drawingViewModel {
                MeasurementOverlay(
                    drawings: vm.drawings,
                    currentDrawing: vm.currentDrawing
                )
            }

            // Drawing Toolbar - RIGHT SIDE
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    if let vm = drawingViewModel {
                        DrawingToolbar(
                            activeDrawingType: Binding(
                                get: { vm.activeDrawingType },
                                set: { vm.activeDrawingType = $0 }
                            ),
                            isDrawing: vm.isDrawing,
                            onStartDrawing: { type in
                                vm.startDrawing(type: type)
                            },
                            onFinishDrawing: {
                                vm.finishDrawing()
                            },
                            onCancelDrawing: {
                                vm.cancelDrawing()
                            }
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingEditMenu) {
            if let drawing = selectedDrawing {
                DrawingEditMenu(
                    drawing: Binding(
                        get: { drawing },
                        set: { selectedDrawing = $0 }
                    ),
                    onDelete: {
                        drawingViewModel?.deleteDrawing(drawing)
                        showingEditMenu = false
                        selectedDrawing = nil
                    },
                    onDismiss: {
                        showingEditMenu = false
                        selectedDrawing = nil
                    }
                )
            }
        }
        .onAppear {
            if drawingViewModel == nil {
                drawingViewModel = DrawingViewModel(modelContext: modelContext)
            }
        }
    }

    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        guard let vm = drawingViewModel else { return }

        if vm.isDrawing {
            // Add point to current drawing
            vm.addPoint(coordinate)
        }
    }

    private func handleLongPress(_ coordinate: CLLocationCoordinate2D, drawing: Drawing?) {
        if let drawing = drawing {
            // Long press on existing drawing - show edit menu
            selectedDrawing = drawing
            showingEditMenu = true
        } else if let vm = drawingViewModel, !vm.isDrawing {
            // Long press on empty space - could show options to create drawing here
            // For now, do nothing
        }
    }
}

#Preview {
    MapView()
        .modelContainer(for: [User.self, Drawing.self], inMemory: true)
}
