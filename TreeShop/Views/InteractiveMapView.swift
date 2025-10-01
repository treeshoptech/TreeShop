//
//  InteractiveMapView.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI
import MapKit

struct InteractiveMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let drawings: [Drawing]
    let currentDrawing: Drawing?
    let onTap: (CLLocationCoordinate2D) -> Void
    let onLongPress: (CLLocationCoordinate2D, Drawing?) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .hybridFlyover
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        // Add long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if !regionsEqual(mapView.region, region) {
            mapView.setRegion(region, animated: true)
        }

        // Remove all overlays and add current ones
        mapView.removeOverlays(mapView.overlays)

        // Add saved drawings
        for drawing in drawings {
            if drawing.coordinates.count >= 2 {
                let coordinates = drawing.coordinates.map { $0.clLocationCoordinate }

                if drawing.type == .area, coordinates.count >= 3 {
                    let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                    polygon.title = drawing.id.uuidString
                    mapView.addOverlay(polygon)
                } else {
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    polyline.title = drawing.id.uuidString
                    mapView.addOverlay(polyline)
                }
            }
        }

        // Add current drawing in progress
        if let current = currentDrawing, current.coordinates.count >= 2 {
            let coordinates = current.coordinates.map { $0.clLocationCoordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            polyline.title = "current"
            mapView.addOverlay(polyline)
        }

        // Add point annotations for current drawing
        if let current = currentDrawing {
            mapView.removeAnnotations(mapView.annotations.filter { $0.title == "drawingPoint" })

            for (index, coord) in current.coordinates.enumerated() {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coord.clLocationCoordinate
                annotation.title = "drawingPoint"
                annotation.subtitle = "\(index)"
                mapView.addAnnotation(annotation)
            }
        }

        // Update coordinator's drawing reference
        context.coordinator.drawings = drawings
        context.coordinator.currentDrawing = currentDrawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawings: drawings,
            currentDrawing: currentDrawing,
            onTap: onTap,
            onLongPress: onLongPress
        )
    }

    private func regionsEqual(_ r1: MKCoordinateRegion, _ r2: MKCoordinateRegion) -> Bool {
        abs(r1.center.latitude - r2.center.latitude) < 0.0001 &&
        abs(r1.center.longitude - r2.center.longitude) < 0.0001 &&
        abs(r1.span.latitudeDelta - r2.span.latitudeDelta) < 0.0001 &&
        abs(r1.span.longitudeDelta - r2.span.longitudeDelta) < 0.0001
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        var drawings: [Drawing]
        var currentDrawing: Drawing?
        let onTap: (CLLocationCoordinate2D) -> Void
        let onLongPress: (CLLocationCoordinate2D, Drawing?) -> Void

        init(drawings: [Drawing], currentDrawing: Drawing?, onTap: @escaping (CLLocationCoordinate2D) -> Void, onLongPress: @escaping (CLLocationCoordinate2D, Drawing?) -> Void) {
            self.drawings = drawings
            self.currentDrawing = currentDrawing
            self.onTap = onTap
            self.onLongPress = onLongPress
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coordinate)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // Check if long press is on an existing drawing
            let tappedDrawing = findDrawingAtPoint(point, in: mapView)
            onLongPress(coordinate, tappedDrawing)
        }

        private func findDrawingAtPoint(_ point: CGPoint, in mapView: MKMapView) -> Drawing? {
            // Check overlays at this point
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                // Simple proximity check - if tap is within 20 meters of any overlay point
                if let polyline = overlay as? MKPolyline {
                    let coords = polyline.points()
                    for i in 0..<polyline.pointCount {
                        let overlayCoord = coords[i].coordinate
                        let location1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        let location2 = CLLocation(latitude: overlayCoord.latitude, longitude: overlayCoord.longitude)

                        if location1.distance(from: location2) < 20 { // 20 meters
                            if let id = overlay.title as? String,
                               let uuid = UUID(uuidString: id),
                               let drawing = drawings.first(where: { $0.id == uuid }) {
                                return drawing
                            }
                        }
                    }
                } else if let polygon = overlay as? MKPolygon {
                    let coords = polygon.points()
                    for i in 0..<polygon.pointCount {
                        let overlayCoord = coords[i].coordinate
                        let location1 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        let location2 = CLLocation(latitude: overlayCoord.latitude, longitude: overlayCoord.longitude)

                        if location1.distance(from: location2) < 20 { // 20 meters
                            if let id = overlay.title as? String,
                               let uuid = UUID(uuidString: id),
                               let drawing = drawings.first(where: { $0.id == uuid }) {
                                return drawing
                            }
                        }
                    }
                }
            }
            return nil
        }

        // MARK: - MKMapViewDelegate

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }

            // Customize drawing point markers
            if annotation.title == "drawingPoint" {
                let identifier = "DrawingPoint"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }

                view?.markerTintColor = .systemGreen
                view?.glyphImage = UIImage(systemName: "circle.fill")
                view?.canShowCallout = false
                view?.displayPriority = .defaultLow // Hide labels when zoomed out

                return view
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Find the drawing for this overlay
            var drawing: Drawing?
            if let title = overlay.title as? String {
                if title == "current" {
                    drawing = currentDrawing
                } else if let uuid = UUID(uuidString: title) {
                    drawing = drawings.first(where: { $0.id == uuid })
                }
            }

            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor(drawing?.color.opacity((drawing?.opacity ?? 0.7) * 0.3) ?? .green.opacity(0.2))
                renderer.strokeColor = UIColor(drawing?.color.opacity(drawing?.opacity ?? 0.7) ?? .green.opacity(0.7))
                renderer.lineWidth = drawing?.lineWidth ?? 3.0
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(drawing?.color.opacity(drawing?.opacity ?? 0.7) ?? .green.opacity(0.7))
                renderer.lineWidth = drawing?.lineWidth ?? 3.0
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
