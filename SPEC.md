# Hastighed App Specification

## 1. Purpose
"Hastighed" (Danish for "speed") helps drivers proactively avoid speeding infringements across European roads, improving safety for all road users. The app provides real‑time monitoring of the driver's current speed compared to the legal speed limit for the current road segment, offering subtle, glanceable, and configurable feedback.

## 2. Core Value Proposition
- Reduce risk of speeding tickets and penalty points.
- Increase driver situational awareness without distraction.
- Provide a privacy‑respecting, offline‑capable experience.
- Offer a foundation for future driver assistance features.

## 3. Target Users
- Everyday drivers traveling across different European countries.
- Road‑trip travelers & rental car users unfamiliar with local limits.
- Professional drivers needing consistent compliance.

## 4. Non-Goals (Initial Phases)
- Turn‑by‑turn navigation (can deep‑link to mapping apps later).
- Driver behavior scoring / insurance telematics.
- Advertising or selling user data.
- Full ADAS (Advanced Driver Assistance) stack.

## 5. Guiding Principles
| Principle | Description |
|-----------|-------------|
| Safety First | UI avoids cognitive overload; color + haptics only when necessary. |
| Privacy by Design | Location processed on‑device; minimal retention. |
| Battery Conscious | Efficient location + motion sampling adaptive to speed & accuracy needs. |
| Transparency | Clear indication of data sources & confidence of speed limit. |
| Progressive Enhancement | Starts simple; architecture ready for richer data layers. |

## 6. MVP Scope (Milestone 0)
1. Foreground app displaying:
   - Current speed (km/h).
   - Current detected / inferred speed limit.
   - Status indicator (Under / Near / Over limit).
2. Basic speed limit sourcing priority:
   1. Local static rules (fallback: country default categories e.g., urban / rural / motorway).
   2. Simple ruleset derived from country + road type (placeholder classification until real map data).
3. Location & speed acquisition using `CoreLocation`.
4. SwiftUI interface with color feedback:
   - Green: comfortably below.
   - Amber: within configurable threshold (e.g., 0–3 km/h below/above limit).
   - Red: exceeding.
5. Basic settings (threshold tolerance, units km/h vs mph (later)).
6. Disclaimer + responsibility notice.

Out of MVP (but planned soon):
- Persistent settings sync (iCloud / AppStorage after MVP).
- Background monitoring & CarPlay surface.
- Real map tile / OpenStreetMap / HERE / TomTom integration.
- Offline cache of speed limits.

## 7. Future Enhancements (Selected)
- Speed camera zone awareness (legal compliance varies by country—research needed).
- Haptic feedback on Apple Watch companion.
- Route predictive limit changes ahead (querying map graph).
- Machine learning assisted road classification using motion + heading variance.
- Crowdsourced corrections (moderated).
- Voice subtle prompts when approaching limit.

## 8. High-Level Architecture
```
+---------------------------+            +---------------------------+
|        SwiftUI UI         |<---------->|     ViewModel (State)     |
+---------------------------+            +---------------------------+
             ^                                       ^
             |                                       |
             v                                       v
+---------------------------+            +---------------------------+
|   LocationService (CL)    |            |  SpeedLimitService (Rule) |
+---------------------------+            +---------------------------+
             ^                                       ^
             |                                       |
             +---------------+   +------------------+
                             v   v
                    +--------------------+
                    |  Data Sources      |
                    |  - Static rules    |
                    |  - Future: APIs    |
                    +--------------------+
```

## 9. Core Data Models (Initial)
- `SpeedLimit`: numeric value + unit + source + confidence.
- `SpeedReading`: speed + timestamp + accuracy.
- `LimitStatus`: enum { below, near, over } derived.

## 10. Services (Protocols First)
```swift
protocol LocationServicing {
    var latestSpeed: Measurement<UnitSpeed>? { get }
    var latestLocation: CLLocation? { get }
    func start()
    func stop()
}

protocol SpeedLimitProviding {
    func currentSpeedLimit(for location: CLLocation) -> SpeedLimit
}
```

## 11. Limit Derivation (MVP Placeholder)
- Use country code from `CLLocation.isoCountryCode` (if available) else default.
- If no road type classification yet, fall back to generic default (e.g., 50 km/h urban assumed for MVP until refined).
- Provide a `confidence` scalar (0.0–1.0) for UI transparency (MVP: static constants per rule type).

## 12. UI / UX Notes
- Big numerals for speed & limit; high contrast.
- Dynamic type friendly.
- Color contrast meets WCAG (avoid pure saturated red on dark backgrounds for accessibility—choose slightly softened palette).
- Optional subtle pulse animation when over limit.

## 13. Configuration & Thresholds
| Setting | Default | Notes |
|---------|---------|-------|
| Near Tolerance (km/h) | 3 | Within this of limit triggers amber. |
| Units | km/h | mph future toggle. |

## 14. Error / Edge Case Handling
- No GPS permission: show onboarding & rationale.
- Low accuracy or stale reading: dim speed value / show ellipsis.
- Simulator environment: generate synthetic speed ramp.

## 15. Telemetry & Privacy
- MVP: no external analytics. Local lightweight debug log (console only).
- Future: opt‑in anonymous performance metrics (never raw location).

## 16. Testing Strategy
- Inject protocol abstractions for Location & SpeedLimit services to enable deterministic previews and unit tests.
- Provide mock implementations with fixed sequences.

## 17. Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Inaccurate speed limit inference | Transparently show confidence + disclaimers. |
| Battery drain | Adaptive desiredAccuracy & activityType on `CLLocationManager`. |
| Legal concerns (reliance) | Clear disclaimer; user responsibility emphasized. |
| Data source licensing future | Choose open data first (OpenStreetMap). |

## 18. Licensing & Attribution
- Future external data (OSM) will require attribution screen.

## 19. MVP Acceptance Criteria
- App builds & runs on iOS 17+.
- Displays current speed (simulated if on Simulator) within 2s of permission granted.
- Shows a speed limit value & status color.
- Updates color dynamically as simulated speed crosses limit thresholds.

## 20. Glossary
- MVP: Minimum Viable Product.
- CL: CoreLocation.
- OSM: OpenStreetMap.

---
Version: 0.1.0 (Initial Draft)

## 21. Home Screen Specification (Draft)

### Objective
Provide a single, distraction-minimised surface that shows: current speed, current legal speed limit, and imminent road context (upcoming limit changes, speed cameras, and hazards) within a 250 m look‑ahead corridor in the vehicle's heading direction.

### Functional Requirements
| ID | Requirement | Notes |
|----|-------------|-------|
| HS1 | Display current speed (large numeral) | Updated at least once per second when moving. |
| HS2 | Display current speed limit (sign style) | Shows value + unit. Confidence coloring (later). |
| HS3 | Show upcoming speed limit changes within 250 m | Sorted by distance ascending; only first 2 shown if space constrained. |
| HS4 | Show speed cameras within 250 m | Icon + distance (rounded to 10 m). |
| HS5 | Show other hazards (e.g., school zone, sharp bend) within 250 m | Placeholder model; initially mocked. |
| HS6 | Hide sections with no data | Prevents clutter. |
| HS7 | Degrade gracefully when location accuracy poor | Dim gauge + show small accuracy badge. |
| HS8 | Landscape layout adapts: gauge left, stack of context cards right | See inspiration screenshot. |
| HS9 | Provide quick access to settings (tolerance, units) | Floating gear button. |
| HS10 | All context items expire once passed (distance < 0) | Real-time filtering. |

### Non-Functional
| Aspect | Target |
|--------|--------|
| Update Latency | < 500 ms from new location to UI refresh. |
| Battery | Avoid constant high-accuracy when stationary (< 3 km/h). |
| Accessibility | Supports Dynamic Type; VoiceOver labels for each context item. |

### Data Models (Additions)
```swift
struct UpcomingSpeedLimitChange: Identifiable, Hashable {
   let id = UUID()
   let newLimit: SpeedLimit
   let distanceMeters: Double
}

struct SpeedCamera: Identifiable, Hashable {
   enum CameraType { case fixed, mobile, average }
   let id = UUID()
   let type: CameraType
   let distanceMeters: Double
}

struct RoadHazard: Identifiable, Hashable {
   enum HazardType { case schoolZone, sharpTurn, roadworks }
   let id = UUID()
   let type: HazardType
   let distanceMeters: Double
}
```

### Provider Protocols
```swift
protocol UpcomingLimitProviding { func upcomingChanges(within meters: Double, from location: CLLocation) -> [UpcomingSpeedLimitChange] }
protocol SpeedCameraProviding { func nearbyCameras(within meters: Double, from location: CLLocation) -> [SpeedCamera] }
protocol RoadHazardProviding { func nearbyHazards(within meters: Double, from location: CLLocation) -> [RoadHazard] }
```

Initial implementations will be mock / static collections filtered by distance along a naive straight‑line projection (bearing not yet considered in MVP of this feature).

### View Model Responsibilities
1. Subscribe to speed + location.
2. Query providers each location update (throttle to 1 Hz).
3. Filter items to distance ≤ 250 m and distance ≥ 0.
4. Publish arrays for UI sections.
5. Compute a simplified accuracy state (good / moderate / poor) for gauge styling.

### UI Layout (Portrait)
```
┌─────────────────────────────────────────┐
│   Time  • status icons                  │
│                                         │
│        (Semi-circle speed gauge)        │
│                   0                     │
│                 km/h                    │
│                                         │
│  Upcoming (if any)  Cameras  Hazards    │ (horizontal scroll or stacked chips)
│                                         │
│            [ Speed Limit Sign ]         │
│                                         │
│   Disclaimer / accuracy badge / gear    │
└─────────────────────────────────────────┘
```

### UI Layout (Landscape)
Gauge left 60%, right column lists upcoming items as compact cards with icon, label, distance, value.

### Open Questions
- Should average speed camera zones display entry + exit separately? (Defer)
- Should we provide auditory cue when a new lower limit is within 100 m? (Future haptics/audio spec.)

### Versioning
Home Screen spec version: 0.1 (Initial Draft)

