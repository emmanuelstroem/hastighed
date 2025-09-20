# Tasks: Live location updates with a single shared CLLocation/CLLocationCoordinate2D

Feature dir: `/Users/emmanuel/Developer/Github/emmanuelstroem/hastighed/specs/002-specify-read-driving`

Notes:
- Foreground-only per research.md
- Use a single source of truth for both `CLLocation` and `CLLocationCoordinate2D` across the app via `LocationService`.
- Update speed and coordinates live; expose one shared publisher per datum.
- Tests first for snapshot formatting and simple persistence.

## Ordered Tasks

T001 [P] Validate pre-reqs and scaffold test targets
- Files: `hastighed.xcodeproj` (no code changes)
- Actions:
  - Verify unit test target exists; if missing, create.
  - Add empty test files placeholders.

T002 Define single-source-of-truth APIs in LocationService
- Files: `hastighed/Services/LocationService.swift`
- Actions:
  - Ensure `LocationService` holds the canonical `latestLocation: CLLocation?` and derives `latestCoordinate: CLLocationCoordinate2D?` from it.
  - Keep `coordinatePublisher` and `speedPublisher` fed from `didUpdateLocations` using the same `latestLocation` instance.
  - Document via comments the invariants: coordinate always comes from `latestLocation.coordinate`.

T003 Update LocationServicing protocol for single-source access
- Files: `hastighed/Services/LocationService.swift`
- Actions:
  - Protocol already exposes `latestLocation` and `coordinatePublisher`. Add a read-only computed `latestCoordinate: CLLocationCoordinate2D? { get }` for convenience.
  - Implement in `LocationService` as `latestLocation?.coordinate`.

T004 Wire live updates: ensure didUpdateLocations sends both speed and coordinate
- Files: `hastighed/Services/LocationService.swift`
- Actions:
  - In `didUpdateLocations`, set `latestLocation`, then emit:
    - `coordinateSubject.send(latestLocation?.coordinate)`
    - If `loc.speed >= 0`, compute km/h and emit `speedPublisher`.

T005 [P] ViewModels consume single shared values
- Files: `hastighed/ViewModels/HomeViewModel.swift`, `hastighed/ViewModels/SpeedMonitoringViewModel.swift`
- Actions:
  - Read coordinates only via `locationService.latestLocation?.coordinate` (or `latestCoordinate` if added) to avoid duplicating state.
  - Keep subscriptions to `coordinatePublisher` only to trigger UI refresh; do not store a separate coordinate value.

T006 Expose unified debug snapshot from shared location
- Files: `hastighed/ViewModels/HomeViewModel.swift`, `hastighed/Views/Components/DebugOverlayView.swift`
- Actions:
  - Build `DebugSnapshot.coordinate` from `locationService.latestLocation?.coordinate`.
  - Ensure speed in snapshot uses the same `SpeedReading` emitted from `LocationService`.

T007 Ensure single point of start/stop for live updates
- Files: `hastighed/ContentView.swift`
- Actions:
  - On `.active`, request permission (already implemented). When authorized, `LocationService` starts updates.
  - Avoid multiple managers or secondary services for coordinates.

T008 [P] Unit tests: snapshot formatting and coordinate-source invariants
- Files: `hastighedTests/DebugSnapshotTests.swift`
- Actions:
  - Test that `DebugSnapshot.formattedCoordinate` reflects `latestLocation.coordinate`.
  - Test that speed formatting shows expected unit suffix.

T009 [P] UI tests: overlay presence and live updates (smoke)
- Files: `hastighedUITests/DebugOverlayUITests.swift`
- Actions:
  - Toggle debug overlay and assert text labels update when simulated speed/coordinate change.

T010 Polish: docs and comments
- Files: `specs/002-specify-read-driving/quickstart.md`, `specs/002-specify-read-driving/data-model.md`
- Actions:
  - Note single-source-of-truth pattern and where to access `CLLocation` and coordinate.

## Parallelization Guidance
- [P] T001, T008, T009 can be prepared in parallel.
- T002→T004→T005 must be sequential (shared files and contracts).
- T006 depends on T002–T005.
- T007 can follow after T004.

## Example Agent Commands
- Build: `xcodebuild -scheme hastighed -destination 'platform=iOS Simulator,name=iPhone 16 Pro' | cat`
- Tests (once added): `xcodebuild test -scheme hastighed -destination 'platform=iOS Simulator,name=iPhone 16 Pro' | cat`

# Tasks: Reduce Location Energy Impact

Feature Dir: `/Users/emmanuel/Developer/Github/emmanuelstroem/hastighed/specs/002-specify-read-driving`

## Notes
- Objective: Lower energy impact from location usage while preserving acceptable speed responsiveness and accuracy for driving.
- Context: CoreLocation configured for automotive; app foreground-only for this iteration.

## Numbered Tasks

- T001 — Instrument energy + update cadence [P]
  - Files: `hastighed/Services/LocationService.swift`, `hastighed/ViewModels/HomeViewModel.swift`
  - Add lightweight logging/metrics: timestamped location update intervals, average Hz, authorization state, foreground/background transitions.
  - Dependency: none

- T002 — Adaptive accuracy policy
  - File: `hastighed/Services/LocationService.swift`
  - Implement dynamic `desiredAccuracy` and `distanceFilter`:
    - Stationary/low-speed (< 3 km/h for 3s): raise `distanceFilter` (e.g., 15–25 m)
    - Normal driving: `kCLLocationAccuracyBestForNavigation`, `distanceFilter` ~ 5–10 m
    - Very high speed (> 110 km/h): consider `distanceFilter` ~ 15 m to reduce frequency
  - Ensure quick ramp back to high accuracy on motion detection.
  - Dependency: T001

- T003 — Motion-based pausing and resume
  - File: `hastighed/Services/LocationService.swift`
  - Use `pausesLocationUpdatesAutomatically = true` and implement `CLLocationManagerDelegate` hooks to resume promptly when motion occurs (keep `activityType = .automotiveNavigation`).
  - Dependency: T002

- T004 — Throttle UI updates [P]
  - File: `hastighed/ViewModels/HomeViewModel.swift`
  - Debounce or `removeDuplicates` on speed/coordinate publishing to avoid unnecessary state churn when values are unchanged within tolerance.
  - Preserve responsiveness for >1 km/h deltas or >10 m coordinate deltas.
  - Dependency: none

- T005 — Sim update rate based on accuracy
  - File: `hastighed/Services/LocationService.swift`
  - Ignore updates when `horizontalAccuracy` is poor and speed change < threshold; this reduces downstream work and redraws.
  - Dependency: T002

- T006 — Foreground-only enforcement
  - Files: `hastighed/ContentView.swift`, `hastighed/Services/LocationService.swift`
  - Stop updates on app going inactive/background; restart on active.
  - Use scene phase to call `start()`/`stop()` appropriately.
  - Dependency: T001

- T007 — Settings option: Battery saver [P]
  - Files: `hastighed/Models/SettingsStore.swift`, `hastighed/Views/SettingsView.swift`
  - Add `@AppStorage("batterySaver")` with UI toggle. When enabled, apply more conservative `distanceFilter` and stronger UI throttling.
  - Dependency: none

- T008 — Tests: Update throttling and policy switches [P]
  - Files: `hastighedTests/LocationEnergyPolicyTests.swift`
  - Unit tests for adaptive policy transitions and debounced UI updates.
  - Dependency: T002, T004

- T009 — Documentation and quickstart update [P]
  - Files: `specs/002-specify-read-driving/quickstart.md`
  - Document battery saver mode, expected update rates, and scenarios to validate energy impact.
  - Dependency: T007

## Parallelization
- [P] T001, T004, T007, T008, T009 can proceed in parallel; T002→T003→T005 follow sequentially.

## Agent Commands
- To implement a task TXXX, run:
  - `/impl TXXX` then follow the edits in the specified file.

## Dependency Order
1) T001 [P] → 2) T002 → 3) T003 → 4) T005 → 5) T004 [P] → 6) T006 → 7) T007 [P] → 8) T008 [P] → 9) T009 [P]

## Addendum: Real-time GPS + UnitSystem Picker

T011 Ensure real-time GPS updates at ~1 Hz with minimal jitter
- Files: `hastighed/Services/LocationService.swift`
- Actions:
  - Confirm `manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation` and `manager.activityType = .automotiveNavigation`.
  - Set `manager.distanceFilter = kCLDistanceFilterNone` to allow highest cadence in foreground.
  - Keep `pausesLocationUpdatesAutomatically = true`.
  - In `didUpdateLocations`, emit immediately to `speedPublisher` and `coordinatePublisher`.
  - Add a comment about foreground-only scope per research.md.

T012 [P] Throttle UI updates based on display delta only (keep service real-time)
- Files: `hastighed/ViewModels/HomeViewModel.swift`, `hastighed/ViewModels/SpeedMonitoringViewModel.swift`
- Actions:
  - Ensure `removeDuplicates` compares using converted display units via `SettingsStore.displaySpeed`.
  - Keep tolerance configurable; default 0.1 in both view models.

T013 Replace unit toggle with UnitSystem picker
- Files: `hastighed/Views/SettingsView.swift`, `hastighed/Models/AppConfig.swift`, `hastighed/Models/SettingsStore.swift`
- Actions:
  - Add `@AppStorage(AppStorageKeys.useImperialUnits)` binding via a `Picker("Unit System", selection:)` with `UnitSystem.metric` and `.imperial` options.
  - Implement mapping between picker selection and `useImperialUnits` boolean.
  - Remove or hide the previous toggle.

T014 [P] Update previews and labels to use shared unit system
- Files: `hastighed/Views/Components/DebugOverlayView.swift`, any other previews
- Actions:
  - Ensure previews reference `UnitSystem.metric.speedUnitLabel` or construct from a temporary `SettingsStore` if needed.

T015 [P] Tests: verify picker persistence and display conversion
- Files: `hastighedUITests/SettingsPickerUITests.swift`, `hastighedTests/UnitConversionTests.swift`
- Actions:
  - UI test: switch picker to Imperial, relaunch app, verify mph labels.
  - Unit test: `SettingsStore` conversions return expected values for both systems.

### Parallelization
- [P] T012, T014, T015 can run in parallel.
- T011 before T012.
- T013 after AppConfig/SettingsStore helpers are present (already added).

## Addendum: Visibility settings for views

T016 Add AppStorage keys and SettingsStore properties for visibility
- Files: `hastighed/Models/AppConfig.swift`, `hastighed/Models/SettingsStore.swift`
- Actions:
  - Define keys: `showGauge`, `showSpeedLimit`, `showSpeedCameras`, `showHazards`, `showDebugOverlay`.
  - In `SettingsStore`, add `@AppStorage` Bools defaulting to true (debug overlay follows existing key).

T017 Settings UI: toggles for each section
- Files: `hastighed/Views/SettingsView.swift`
- Actions:
  - Add a new section "Visibility" with toggles bound to the new `SettingsStore` properties.

T018 Consume visibility flags in HomeView layout
- Files: `hastighed/Views/HomeView.swift`
- Actions:
  - Conditionally render: gauge, speed limit sign, upcoming limits list, cameras list, hazards list, debug overlay based on flags.
  - Defaults should preserve current behavior (all visible except debug follows setting).

T019 [P] UI tests for visibility persistence
- Files: `hastighedUITests/VisibilitySettingsUITests.swift`
- Actions:
  - Toggle each visibility switch off/on and assert presence/absence in UI.
  - Relaunch app to verify persistence.

### Parallelization
- [P] T019 can run in parallel after T017+T018.
- T016 before T017 and T018.
