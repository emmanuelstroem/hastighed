# Tasks: Connectivity Service (Internet availability + connection type)

**Input**: Design documents from `/Users/emmanuel/Developer/Github/emmanuelstroem/hastighed/specs/003-check-internet-connection/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Notes
- Project type: iOS (Swift). Implement under `hastighed/Services/` and tests in `hastighedTests/`.
- Use `NWPathMonitor` via an abstraction to enable deterministic tests.
- Expose: `isInternetUsable() -> Bool` and `currentNetworkType() -> NetworkType`.

## Phase 3.1: Setup
- [ ] T001 Ensure XCTest targets exist and build in active scheme
- [ ] T002 [P] Create `hastighedTests/ConnectivityServiceTests.swift` placeholder

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [ ] T003 Write unit tests in `hastighedTests/ConnectivityServiceTests.swift`:
  - Assert `isInternetUsable()` toggles with path status changes
  - Assert `currentNetworkType()` maps Wi‑Fi vs Cellular vs None
  - Assert status change callback publishes `ConnectivityStatus`
  - Use a `NetworkPathMonitoring` mock to simulate paths and interfaces

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T004 Create `hastighed/Services/ConnectivityService.swift`:
  - API: `isInternetUsable() -> Bool`, `currentNetworkType() -> NetworkType`, `onStatusChange(_ handler: @escaping (ConnectivityStatus) -> Void)`
  - Implement using injected `NetworkPathMonitoring` (wrap `NWPathMonitor`)
  - Map `NWPath.Status` and `availableInterfaces` to `ConnectivityStatus`
- [ ] T005 [P] Add `hastighed/Models/ConnectivityModels.swift` with:
  - `enum NetworkType { case wifi, cellular, other, none }`
  - `enum ConnectivityReason { case online, offline, captivePortal, hostUnreachable, constrained }`
  - `struct ConnectivityStatus { let usable: Bool; let reason: ConnectivityReason; let networkType: NetworkType }`
- [ ] T006 Add DI initializer to `ConnectivityService` accepting `NetworkPathMonitoring`
- [ ] T007 Stub reachability probe method (host‑specific) for future captive portal checks

## Phase 3.4: Integration
- [ ] T008 Wire `ConnectivityService` into app environment in `hastighed/hastighedApp.swift`
- [ ] T009 [P] Surface status in `hastighed/Views/Components/DebugOverlayView.swift`
- [ ] T010 Append usage steps to `specs/003-check-internet-connection/quickstart.md`

## Phase 3.5: Polish
- [ ] T011 [P] Edge case tests: no interfaces, constrained, transition spam
- [ ] T012 Ensure main‑thread delivery for UI observers and thread safety
- [ ] T013 Update `README.md` with ConnectivityService usage

## Phase 3.6: Conformance Verification (Plan/Spec/Gates)
- [ ] T014 Audit `ConnectivityService` against contracts in `specs/003-check-internet-connection/contracts/README.md`
  - File: `hastighed/Services/ConnectivityService.swift`
  - Verify API names/signatures: `isInternetUsable()`, `currentNetworkType()`, `onStatusChange((ConnectivityStatus) -> Void)`
  - Verify use of `NWPathMonitor` abstraction and mapping to `ConnectivityStatus`
- [ ] T015 Add XCTest validating immediate callback behavior in `onStatusChange` (invoked with current status)
  - File: `hastighedTests/ConnectivityServiceTests.swift`
- [ ] T016 Verify SwiftUI environment injection and usage
  - File: `hastighed/hastighedApp.swift` uses singleton `ConnectivityService.shared`
  - File: `hastighed/Services/ConnectivityService.swift` defines `EnvironmentValues.connectivityService`
  - File: `hastighed/Views/Components/DebugOverlayView.swift` consumes environment and renders Online/Offline + network type
- [ ] T017 Validate platform and constraints alignment
  - iOS target 17+ in `hastighed.xcodeproj/project.pbxproj` (IPHONEOS_DEPLOYMENT_TARGET)
  - Performance gates documented (<2s load, low CPU/energy); add TODO markers to perf test plan if missing
- [ ] T018 Ensure offline-first posture is preserved
  - No hard dependency on network for speedometer/limit display (verify with airplane mode run)
- [ ] T019 [P] Prepare DownloadService scaffolding to align with plan
  - Create `hastighed/Services/DownloadService.swift` skeleton with enqueue/pause/resume/cancel/cleanup stubs
  - Create `hastighedTests/DownloadServiceTests.swift` with failing tests for pause/resume/cancel/cleanup
- [ ] T020 Update `specs/003-check-internet-connection/quickstart.md` if UI steps changed

## Phase 3.7: Offline Maps UI States
- [ ] T021 Ensure menu buttons reflect state in `OfflineMapsView.swift`
  - downloading → show Pause, Cancel
  - completed (available locally) → show Delete only
  - notStarted (unavailable locally) → show Download
  - paused → show Resume, Cancel
- [ ] T022 [P] Add tests (if UI test target available) or manual verification steps in quickstart
 - [ ] T023 Implement Cancel semantics to abort and clean state
   - Service: On `cancel(identifier:)` remove partial resume file and any temp fragments
   - UI: Clear percentage for the id (remove from `progressById`) and force state refresh
   - Verify state becomes `notStarted`
 - [ ] T024 [P] Update quickstart.md with cancel behavior checks
   - Start download → Cancel → percent disappears; re-offer Download; no local/partial files remain
 - [ ] T025 Update Pause/Resume label behavior
   - When state is `.paused`, hide "Pause" and show only "Resume" and "Cancel"
   - When state is `.downloading`, show "Pause" and "Cancel" (no "Resume")
 - [ ] T026 Ensure progress is paused when state is `.paused`
   - Service: Stop emitting progress while paused (no `onProgress` callbacks)
   - Simulation: suspend timer while paused and resume on resume
 - [ ] T027 Verify resume continues the same download
   - Service: Use persisted resume data to continue; status flips back to `.downloading`
   - UI: Percentage should increase from the paused value (not reset)
 - [ ] T028 [P] Add quickstart steps for Pause/Resume/Progress behavior

## Phase 3.8: GPKG URL & File Size Display
- [ ] T029 Set Denmark GPKG URL
  - Update `OfflineMapsView.swift` EU list to use `https://hastighed.stillestorm.dk/denmark.gpkg`
  - Ensure `DownloadService.enqueueDownload` uses the same URL for identifier `DK`
- [ ] T030 Implement FileSizeProvider
  - New service in `hastighed/Services/FileSizeService.swift` that performs HTTP HEAD to read `Content-Length`
  - Fallback to GET-range (bytes=0-0) if HEAD not supported
  - Return size in bytes; format helper to human-readable MB/GB
- [ ] T031 Display human-readable size instead of country code
  - In `OfflineMapsView.swift`, fetch and cache size per id; show e.g., "42 MB" under the country name
  - Persist lightweight cache in-memory for session (optional: UserDefaults keyed by URL+Etag)
- [ ] T032 [P] Error handling & offline behavior
  - If size unavailable, show "—" and keep UI responsive; retry on next appear with backoff
- [ ] T033 [P] Tests/verification
  - Unit-test size formatting (bytes → MB/GB)
  - Manual step: verify Denmark URL size renders and updates correctly

## Phase 3.9: Completion Notification (fade in/out)
- [ ] T034 Create lightweight notification view component
  - File: `hastighed/Views/Components/DownloadNotificationView.swift`
  - Shows: leading green checkmark.circle.fill, text: "Download complete: <name>"
  - Animates fade/slide in and auto-dismiss after 2–3s
- [ ] T035 Emit notification on completion
  - In `DownloadService`, on successful completion, post `DownloadCompleted` with `{ id, fileURL }`
  - Derive `<name>` from fileURL.lastPathComponent without extension
- [ ] T036 Present notification
  - Integrate in `OfflineMapsView` (or a top-level container) to listen and show banner
  - Ensure multiple completions queue or replace current message
- [ ] T037 [P] Verification
  - Manual: trigger download, observe banner fades in/out with correct name
  - Accessibility: VoiceOver reads message; banner not obstructing controls

## Phase 3.10: Re-implement downloads using DownloadManager (3rd-party)
- [ ] T038 Add SPM dependency
  - Xcode → Project → Package Dependencies → add `https://github.com/shapedbyiris/download-manager.git`
  - Target: `hastighed`
- [ ] T039 Create minimal wrapper service
  - File: `hastighed/Services/Downloads.swift`
  - API: `enqueue(url:id)`, `pause(id)`, `resume(id)`, `cancel(id)`, `delete(id)`, `progress(id)`, `state(id)`
  - Internals: call `DownloadManager.shared.addDownload` with destination in `Application Support/OfflineMaps/{id}.gpkg`
  - Post `Notification.Name("DownloadCompleted")` with `{ id, fileURL, name }`
- [ ] T040 [P] Implement Settings UI for Offline Maps
  - File: `hastighed/Views/Settings/OfflineMapsView.swift`
  - Show EU countries list with sizes (optional placeholder first)
  - Buttons per state: Download; Pause/Cancel; Resume/Cancel; Delete
  - Show percentage and human-readable bytes (bridge `Float` progress to bytes)
- [ ] T041 [P] Hook global completion banner
  - File: `hastighed/ContentView.swift`
  - Listen for `DownloadCompleted` and show bottom toast for 2–3s
- [ ] T042 Persist simple state
  - File: `hastighed/Services/Downloads.swift`
  - Keep `urlById`, `localFileById` persisted in `Application Support/OfflineMaps/state.json`
  - On init: scan directory for `.gpkg` files and set state=`completed`
- [ ] T043 [P] Tests/verification
  - Manual quickstart: start, pause, resume, cancel, delete; persistence across relaunch
  - Edge cases: cellular vs Wi‑Fi prompt (future), missing file on launch

## Phase 3.11: File size on load + bytes progress + pause/resume polish
- [ ] T044 Implement FileSizeService (HEAD with Range fallback)
  - File: `hastighed/Services/FileSizeService.swift`
  - API: `fetchSize(url:completion:)`, `cachedSize(url:)`, `format(bytes:)`
- [ ] T045 Show file size on load in OfflineMapsView
  - File: `hastighed/Views/Components/OfflineMapsView.swift`
  - On appear: call `FileSizeService.fetchSize` for each country; show formatted size under name
  - If unavailable: show "—" and retry on next appear
- [ ] T046 Bridge DownloadManager progress to bytes using known total
  - File: `hastighed/Services/Downloads.swift`
  - Before enqueue: fetch and store `totalBytesById[id]` from `FileSizeService`
  - In onProgress(progress: Float): compute `written = total * progress` and publish `(written,total)`
  - Expose `currentProgress(id)` returning bytes tuple
- [ ] T047 Persist total bytes and local file
  - File: `hastighed/Services/Downloads.swift`
  - Extend state.json with `totalBytes` field and load/save it
- [ ] T048 Pause/Resume UX and behavior
  - File: `hastighed/Services/Downloads.swift`, `hastighed/Views/Components/OfflineMapsView.swift`
  - Pause: stop progress updates immediately; set state `.paused`
  - Resume: re‑enqueue using same URL; progress resumes from 0 if package lacks resume API
  - If DownloadManager adds resume API, switch to true resume (document in code)
- [ ] T049 [P] Update quickstart with bytes and size validation
  - Verify sizes show on load; progress displays `x/y MB` (or GB) and pauses/resumes


## Phase 3.10: Show human-readable bytes under percentage (e.g., 10.2/42 MB)
- [ ] T038 Add unit tests for size formatting
  - File: `hastighedTests/FileSizeFormattingTests.swift`
  - Cases: 1024 → "1 KB"; 10_240 → "10 KB"; 10_700_000 → "10.2 MB"; 42_000_000 → "42 MB"; 1_800_000_000 → "1.8 GB"
- [ ] T039 Implement formatting helpers
  - File: `hastighed/Services/FileSizeService.swift`
  - Update `format(bytes:)` to return one decimal for MB/GB when fractional, integer otherwise
  - Add `formatProgress(written:total:) -> String` to yield strings like "10.2/42 MB"
- [ ] T040 [P] Cache latest progress in DownloadService
  - File: `hastighed/Services/DownloadService.swift`
  - Keep `lastProgressById[id] = (written,total)` on progress callbacks (memory only)
  - Add accessor `currentProgress(for:) -> (Int64, Int64)?` for UI snapshot
- [ ] T041 Update UI to render bytes line under percentage
  - File: `hastighed/Views/Components/OfflineMapsView.swift`
  - Below the percentage text/progress, show `FileSizeService.formatProgress(written:total:)`
  - Visibility rules:
    - Show when state is `.downloading` or `.paused`
    - Hide when state is `.notStarted` or `.completed` or after Cancel/Delete
- [ ] T042 [P] Quickstart updates for validation
  - Add steps: observe bytes increasing; pause keeps bytes visible and stable; resume continues; cancel/delete hides; completed shows checkmark and no bytes line
- [ ] T043 Accessibility & layout polish [P]
  - Dynamic Type friendly layout; label announced as "Downloaded x of y"
  - Ensure truncation/line wrapping does not break layout on narrow devices


## Dependencies
- T003 before T004–T007 (tests before implementation)
- T004 depends on T005 (models before service)
- T008 depends on T004
- T009 depends on T008

## Parallel Example
```
# After T003 fails, execute in parallel:
Task: "T005 Add models in hastighed/Models/ConnectivityModels.swift" [P]
Task: "T010 Append usage to specs/003-check-internet-connection/quickstart.md" [P]

# Conformance tasks that can run together:
Task: "T014 Audit ConnectivityService against contracts" 
Task: "T015 Immediate-callback unit test in hastighedTests/ConnectivityServiceTests.swift" [P]
Task: "T019 Prepare DownloadService scaffolding and tests" [P]
Task: "T021 Ensure OfflineMapsView menu reflects state" [P]
```


