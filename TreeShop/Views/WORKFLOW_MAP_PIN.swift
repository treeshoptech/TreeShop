import SwiftUI
import MapKit

// MARK: - MAP ANNOTATION

struct WORKFLOW_ANNOTATION: Identifiable, Equatable, Hashable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let stage: WORKFLOW_STAGE
    let title: String
    let subtitle: String
    let lead: LEAD

    init(lead: LEAD) {
        self.id = lead.id
        self.coordinate = lead.coordinate
        self.stage = lead.currentStage
        self.title = lead.customerName
        self.subtitle = lead.propertyAddress
        self.lead = lead
    }

    static func == (lhs: WORKFLOW_ANNOTATION, rhs: WORKFLOW_ANNOTATION) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CUSTOM MAP PIN

struct WORKFLOW_MAP_PIN: View {
    let stage: WORKFLOW_STAGE
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Pin shadow
            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: isSelected ? 52 : 32, height: isSelected ? 52 : 32)
                .offset(y: 2)

            // Pin body
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: isSelected ? 48 : 28, height: isSelected ? 48 : 28)

                // Inner circle with stage color
                Circle()
                    .fill(stage.color)
                    .frame(width: isSelected ? 42 : 22, height: isSelected ? 42 : 22)

                // Pulse effect for selected
                if isSelected {
                    Circle()
                        .stroke(stage.color.opacity(0.5), lineWidth: 4)
                        .frame(width: 56, height: 56)
                        .scaleEffect(1.2)
                        .opacity(0.6)
                }
            }
            .shadow(color: stage.color.opacity(0.4), radius: isSelected ? 8 : 4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - PIN CALLOUT

struct WORKFLOW_PIN_CALLOUT: View {
    let annotation: WORKFLOW_ANNOTATION
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: APP_THEME.SPACING_SM) {
            // Header with stage indicator
            HStack {
                Circle()
                    .fill(annotation.stage.color)
                    .frame(width: 12, height: 12)

                Text(annotation.stage.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(annotation.stage.color)

                Spacer()

                Text("\(annotation.lead.daysSinceCreated)d ago")
                    .font(.caption2)
                    .foregroundColor(APP_THEME.TEXT_TERTIARY)
            }

            // Customer name
            Text(annotation.title)
                .font(.headline)
                .foregroundColor(APP_THEME.TEXT_PRIMARY)

            // Address
            Text(annotation.subtitle)
                .font(.subheadline)
                .foregroundColor(APP_THEME.TEXT_SECONDARY)
                .lineLimit(2)

            // Service types
            if !annotation.lead.serviceTypes.isEmpty {
                HStack(spacing: 4) {
                    ForEach(annotation.lead.serviceTypes.prefix(3), id: \.self) { typeString in
                        if let serviceType = SERVICE_TYPE(rawValue: typeString) {
                            Image(systemName: serviceType.icon)
                                .font(.caption)
                                .foregroundColor(APP_THEME.TEXT_TERTIARY)
                        }
                    }
                    if annotation.lead.serviceTypes.count > 3 {
                        Text("+\(annotation.lead.serviceTypes.count - 3)")
                            .font(.caption2)
                            .foregroundColor(APP_THEME.TEXT_TERTIARY)
                    }
                }
            }

            // Urgency indicator
            if let urgency = URGENCY_LEVEL(rawValue: annotation.lead.urgencyLevel) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(urgency.color)
                        .frame(width: 6, height: 6)

                    Text(urgency.displayName)
                        .font(.caption2)
                        .foregroundColor(urgency.color)
                }
            }

            // Action button
            Button(action: onTap) {
                HStack {
                    Text("View Details")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(annotation.stage.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, APP_THEME.SPACING_SM)
                .background(annotation.stage.color.opacity(0.1))
                .cornerRadius(APP_THEME.RADIUS_SM)
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
        .shadow(color: APP_THEME.SHADOW_LG, radius: 12, x: 0, y: 4)
        .frame(width: 280)
    }
}

// MARK: - MAP WITH WORKFLOW PINS

struct WORKFLOW_MAP_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workflowManager = WORKFLOW_MANAGER()
    @State private var selectedAnnotation: WORKFLOW_ANNOTATION?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var annotations: [WORKFLOW_ANNOTATION] {
        workflowManager.getActiveLeads().map { WORKFLOW_ANNOTATION(lead: $0) }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(annotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    WORKFLOW_MAP_PIN(
                        stage: annotation.stage,
                        isSelected: selectedAnnotation?.id == annotation.id
                    )
                    .onTapGesture {
                        selectedAnnotation = annotation
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .bottom) {
            if let selected = selectedAnnotation {
                WORKFLOW_PIN_CALLOUT(annotation: selected) {
                    // Navigate to lead details
                    print("Navigate to lead: \(selected.lead.id)")
                }
                .padding(APP_THEME.SPACING_MD)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            workflowManager.setContext(modelContext)
            setupNotifications()
        }
        .animation(.spring(response: 0.3), value: selectedAnnotation)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ZoomToLocation"),
            object: nil,
            queue: .main
        ) { notification in
            if let coordinate = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
        }
    }
}
