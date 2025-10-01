# TreeShop

**Map-First Business Operations Platform for Tree Care Professionals**

## Overview

TreeShop is a revolutionary iOS app that treats geography as the primary data structure for tree care operations. Unlike traditional directory-based CRUD applications, TreeShop positions the map as the interface where every tree, job, and customer exists first as a location.

**The Differentiator:** When you drive past a property where you've worked, TreeShop shows you. When you tap a parcel, you see every tree scored, every job completed, every dollar earned - all in one card.

## Current Features (v1.0)

### ✅ Complete Lead Management System
- **4-Stage Workflow**: LEAD → PROPOSAL → WORK_ORDER → INVOICE → COMPLETED
- **Color-Coded Map Pins**: Visual workflow tracking that updates automatically
- **Comprehensive Lead Data**: 50+ fields including customer info, property details, service requests, site visits, assignments, and follow-ups

### ✅ Map-First Interface
- User location tracking and auto-zoom
- Address search with autocomplete
- Custom workflow-colored pins
- Tap pins for lead details
- MapKit integration with realistic terrain

### ✅ Master Navigation Menu
- 3-level tiered slide-out menu
- Right-side drawer with smooth animations
- Quick action buttons (search, calendar, notifications)
- Badge counts for active items
- Access to all app sections

### ✅ Professional UI/UX
- Dark mode native design
- Reusable component library
- Consistent spacing and typography
- Smooth animations and transitions
- Empty states and loading indicators

### ✅ Offline-First Architecture
- SwiftData persistence
- Works in no-signal environments
- Automatic sync when online (ready for CloudKit)

## Technical Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Mapping**: MapKit
- **Architecture**: MVVM with Observable pattern
- **Design**: Dark mode first, supports light mode

## Project Structure

```
TreeShop/
├── Models/
│   ├── LEAD.swift                    # Lead data model
│   ├── Drawing.swift
│   └── User.swift
├── ViewModels/
│   ├── WORKFLOW_MANAGER.swift        # Lead lifecycle management
│   └── DrawingViewModel.swift
├── Views/
│   ├── MAIN_VIEW.swift               # Main app interface
│   ├── WORKFLOW_MAP_PIN.swift        # Map and pins
│   ├── MASTER_MENU.swift             # Navigation menu
│   ├── ADD_LEAD_FORM.swift           # Lead creation
│   ├── ADDRESS_SEARCH_VIEW.swift     # Location search
│   └── COMPONENT_LIBRARY.swift       # Reusable UI components
├── Utils/
│   └── WORKFLOW_CONSTANTS.swift      # Theme and constants
└── Services/
    └── AuthService.swift
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/treeshoptech/TreeShop.git
cd TreeShop
```

2. Open in Xcode:
```bash
open TreeShop.xcodeproj
```

3. Build and run (Cmd+R)

**Requirements:**
- Xcode 16.0+
- iOS 17.0+ device or simulator
- Apple Developer account for device testing

## Workflow System

### Stage Colors
- **LEAD**: Bright Blue - New leads coming in
- **PROPOSAL**: Orange - Proposals sent to customers
- **WORK_ORDER**: Green - Active jobs in progress
- **INVOICE**: Red/Pink - Jobs completed, payment pending
- **COMPLETED**: Gray - Fully completed and paid

### Lead Lifecycle
1. **Lead Received** → Pin appears on map (blue)
2. **Contact Customer** → Schedule site visit or send proposal
3. **Proposal Sent** → Pin turns orange
4. **Proposal Accepted** → Creates work order (green pin)
5. **Work Completed** → Generate invoice (red pin)
6. **Payment Received** → Mark complete (gray pin)

## Service Types
- Tree Removal
- Tree Trimming
- Stump Grinding
- Forestry Mulching
- Tree Assessment
- Emergency Service

## Future Roadmap

### Phase 2: Proposal & Work Order System
- Proposal generation with pricing
- AFISS complexity scoring
- Work order creation and assignment
- Time tracking and project journal

### Phase 3: Invoice & Payment
- Invoice generation
- Payment tracking
- Review requests
- Customer portal

### Phase 4: Advanced Features
- AFISS assessment system (secret competitive advantage)
- TreeScore/TrimScore calculations
- Equipment cost tracking
- Employee management system
- Performance metrics (PpH)
- AI-orchestrated operations
- Drive-by memory notifications

### Phase 5: Business Intelligence
- Reports and analytics dashboard
- Conversion tracking
- Lead source analysis
- Revenue forecasting
- KPI monitoring

## Development Notes

### Code Style
- **SCREAMING_CASE** for files and major components
- Organized, intentional naming conventions
- Comprehensive inline documentation
- Consistent use of APP_THEME constants

### Architecture Principles
- Offline-first with eventual sync
- Map as primary data structure
- Geography before directory
- Progressive workflow (one-way advancement)
- Systematic data organization

## Contributing

This is a private project for TreeShop Tech. Internal development only.

## License

Proprietary - All Rights Reserved

© 2025 TreeShop Tech

---

**Built to shock the industry through systematic domination.**

*Two empires cannot exist. TreeShop chooses systematic domination.*

🤖 Generated with [Claude Code](https://claude.com/claude-code)
