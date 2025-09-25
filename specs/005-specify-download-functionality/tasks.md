# Tasks: Manage GPKG Downloads in Settings (Offline Maps: Denmark, EU focus)

**Input**: Design documents from `/specs/005-specify-download-functionality/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
   → quickstart.md: Extract scenarios → integration tests
3. Generate tasks by category:
   → Setup: folders, scaffolding
   → Tests: contract tests, integration tests (TDD)
   → Core: models, services, view models, views
   → Integration: connectivity, persistence, observability
   → Polish: accessibility, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Create parallel execution examples
7. Return: SUCCESS (tasks ready for execution)
```

## Phase 3.1: Setup
- [ ] T001 [P] Create feature folders `hastighed/Models/OfflineMaps/`, `hastighed/Services/OfflineMaps/`, `hastighed/ViewModels/OfflineMaps/`, `hastighed/Views/OfflineMaps/` (no logic yet)
- [ ] T002 [P] Add asset usage plan for system symbols (download icon) in code comments; no custom assets needed
- [ ] T003 Ensure build succeeds after empty scaffolding creation (no logic)

## Phase 3.2: Tests First (TDD) — MUST FAIL BEFORE 3.3
- [ ] T004 [P] Contract tests for `evaluateDatasetDownloadNetworkPolicy` in `hastighedTests/OfflineMaps/DownloadPolicyTests.swift`
- [ ] T005 [P] Contract tests for `startDatasetDownload`, `pauseDatasetDownload`, `resumeDatasetDownload`, `cancelDatasetDownload`, `deleteLocalDatasetFile`, `getDatasetDownloadStatus`, `observeDatasetDownloadProgress` in `hastighedTests/OfflineMaps/DownloadServiceContractTests.swift`
- [ ] T006 [P] Contract tests for `resolveLocalDatasetStorageLocation` to ensure Application Support path in `hastighedTests/OfflineMaps/StorageLocationTests.swift`
- [ ] T007 [P] Model tests for `DatasetListing`, `DownloadItem`, `LocalGpkgFile`, `DownloadPolicy` with full-word identifiers in `hastighedTests/OfflineMaps/ModelTests.swift`
- [ ] T008 UI integration tests: Settings shows "Offline Maps" section with Denmark row and download control on far right in `hastighedUITests/OfflineMaps/SettingsOfflineMapsUITests.swift`
- [ ] T009 UI integration tests: Download flow (start → pause/resume → cancel/delete → complete with green checkmark) and progress shows "downloadedByteCount / totalByteCount" in `hastighedUITests/OfflineMaps/DownloadFlowUITests.swift`
- [ ] T010 Integration tests: WiFi vs cellular confirmation for files > 50 MB (prompt on cellular before start/resume) in `hastighedTests/OfflineMaps/ConnectivityPolicyIntegrationTests.swift`
- [ ] T011 Integration tests: Persistence across relaunch (and across app update simulation) in `hastighedTests/OfflineMaps/PersistenceIntegrationTests.swift`

## Phase 3.3: Core Implementation (ONLY after tests are failing)
### Models
- [ ] T012 [P] Create `hastighed/Models/OfflineMaps/DatasetListing.swift` with fields from data-model (including `expectedTotalByteCount`, `remoteResourceAddress`)
- [ ] T013 [P] Create `hastighed/Models/OfflineMaps/DownloadItem.swift` with status enum and progress fields
- [ ] T014 [P] Create `hastighed/Models/OfflineMaps/LocalGpkgFile.swift` with Application Support path and persistence flag
- [ ] T015 [P] Create `hastighed/Models/OfflineMaps/DownloadPolicy.swift` with threshold and connectivity type description

### Services
- [ ] T016 Implement `hastighed/Services/OfflineMaps/DownloadService.swift` exposing contracts:
  - startDatasetDownload(datasetIdentifier: String, userConfirmedCellularDownload: Bool)
  - pauseDatasetDownload(datasetIdentifier: String)
  - resumeDatasetDownload(datasetIdentifier: String)
  - cancelDatasetDownload(datasetIdentifier: String) → remove partial files
  - deleteLocalDatasetFile(datasetIdentifier: String)
  - getDatasetDownloadStatus(datasetIdentifier: String)
  - observeDatasetDownloadProgress(datasetIdentifier: String)
  - evaluateDatasetDownloadNetworkPolicy(datasetIdentifier: String)
  - resolveLocalDatasetStorageLocation(datasetIdentifier: String)
- [ ] T017 Implement expected size retrieval using HEAD (Content-Length) for `remoteResourceAddress` and populate `expectedTotalByteCount` in `DatasetListing`
- [ ] T018 Implement single active download with simple FIFO queue and visible queued status
- [ ] T019 Implement resumable downloads when supported; fallback to restart with user messaging
- [ ] T020 Integrate with existing `hastighed/Services/ConnectivityService.swift` to detect connectivity type for policy evaluation

### ViewModel
- [ ] T021 Create `hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift` managing dataset listings, actions (start/pause/resume/cancel/delete), progress updates, and state persistence
- [ ] T022 Add Denmark as initial dataset listing with `remoteResourceAddress` `http://hastighed.stillestorm.dk/denmark.gpkg` and country name "Denmark" (EU focus ready)

### Views
- [ ] T023 Modify `hastighed/Views/SettingsView.swift` to include an "Offline Maps" section that renders `OfflineMapsSectionView`
- [ ] T024 Create `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift` showing a list row per dataset with:
  - Leading: country name
  - Secondary text: file size (from expectedTotalByteCount) in human-readable format
  - Trailing: download control on far right of HStack per state:
    - Idle: Download button/icon
    - Downloading: Pause and Cancel buttons only
    - Paused: Resume and Cancel buttons only
    - Completed: Green checkmark next to country name and a Delete button
  - Progress: show "downloadedByteCount / totalByteCount" below or as subtitle while downloading
- [ ] T025 [P] Create `hastighed/Views/OfflineMaps/DownloadProgressView.swift` to render progress bar and bytes text with accessible labels

### Persistence & File System
- [ ] T026 Implement Application Support subdirectory creation `hastighed/Services/OfflineMaps/LocalStorageService.swift` and file path resolution used by DownloadService
- [ ] T027 Ensure deletion removes local files for both Cancel and Delete flows; verify disk space reclaimed

## Phase 3.4: Integration
- [ ] T028 Wire `OfflineMapsViewModel` into `SettingsView` and bind actions to `DownloadService`
- [ ] T029 Throttle progress UI updates (≤ 2 Hz) to respect performance goals
- [ ] T030 Add structured debug logs for download lifecycle in debug builds only

## Phase 3.5: Polish
- [ ] T031 [P] Accessibility: Provide descriptive labels for controls; announce progress changes
- [ ] T032 Humanize sizes and times (e.g., MB/GB, estimated time remaining when feasible)
- [ ] T033 Documentation: Update `/specs/005-specify-download-functionality/quickstart.md` steps if UI text changes; add README section for Offline Maps
- [ ] T034 Code quality: Verify all identifiers use full words (no abbreviations); fix any violations
- [ ] T035 Ensure final build succeeds; run unit and UI tests; address any regressions

## Dependencies
- Tests (T004–T011) before implementation (T012+)
- Models (T012–T015) before Services (T016–T020)
- Services before ViewModel (T021–T022) and Views (T023–T025)
- Storage (T026–T027) before finishing services (T016) and integration (T028)
- Implementation before polish (T031–T035)

## Parallel Execution Examples
```
# Launch model tasks in parallel after tests are failing:
Tasks: T012, T013, T014, T015

# Launch independent contract tests in parallel:
Tasks: T004, T005, T006, T007

# Launch polish accessibility and size formatting in parallel:
Tasks: T031, T032
```

## Notes
- Use the same dataset URL to determine file size via HEAD request and "Content-Length": `http://hastighed.stillestorm.dk/denmark.gpkg`
- Limit active downloads to one; queue subsequent
- Place the download icon on the far right of each row HStack
- Confirmation dialog required on cellular for files larger than 50 MB before start/resume
- Store files inside Application Support to persist across updates; remove on Cancel/Delete
- Ensure build succeeds after each major step
