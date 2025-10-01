//
//  TreeShopApp.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI
import SwiftData

@main
struct TreeShopApp: App {
    // SwiftData container
    let modelContainer: ModelContainer

    // Auth service
    @State private var authService: AuthService

    init() {
        do {
            // Configure SwiftData with all models
            let schema = Schema([
                User.self,
                Drawing.self,
                Coordinate.self,
                LEAD.self,
                PROPOSAL.self,
                WORK_ORDER.self,
                COMPANY.self,
                USER_PROFILE.self,
                EMPLOYEE.self,
                CUSTOMER.self,
                PROPERTY.self,
                TREE.self,
                EQUIPMENT.self,
                SCHEDULED_JOB.self,
                TIME_ENTRY.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])

            // Initialize auth service
            let context = modelContainer.mainContext
            authService = AuthService(modelContext: context)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MAIN_VIEW()
                    .environment(authService)
            } else {
                LoginView()
                    .environment(authService)
            }
        }
        .modelContainer(modelContainer)
    }
}
