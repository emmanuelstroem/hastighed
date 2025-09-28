# Tasks: SHA512 Checksum-Based Update Detection for Offline Maps

**Input**: Design documents from `/specs/005-specify-download-functionality/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: Swift 6.x, SwiftUI, CoreLocation, Network/NWPathMonitor, XCTest, iOS 17+
2. Load design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- iOS app in this repository:
  - Source: `hastighed/` (Models, Services, ViewModels, Views)
  - Tests: `hastighedTests/`, `hastighedUITests/`

## Phase 3.1: Setup
- [x] T001 [P] Configure SHA512 checksum validation utilities in `hastighed/Services/OfflineMaps/SHA512Utilities.swift`
- [x] T002 [P] Add HTTP utilities for downloading .sha512 files in `hastighed/Services/OfflineMaps/SHA512DownloadService.swift`
- [x] T003 [P] Create local SHA512 checksum service in `hastighed/Services/OfflineMaps/SHA512ChecksumService.swift`
- [x] T004 [P] Create update detection orchestration service in `hastighed/Services/OfflineMaps/UpdateDetectionService.swift`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] T005 [P] Contract test SHA512 checksum validation in `hastighedTests/SHA512ChecksumServiceTests.swift`
- [ ] T006 [P] Contract test .sha512 file downloading in `hastighedTests/SHA512DownloadServiceTests.swift`
- [ ] T007 [P] Contract test SHA512 comparison logic in `hastighedTests/SHA512ComparisonServiceTests.swift`
- [ ] T008 [P] Integration test update button visibility in `hastighedTests/UpdateButtonVisibilityTests.swift`
- [ ] T009 [P] UI test update button interaction in `hastighedUITests/UpdateButtonUITests.swift`
- [ ] T010 [P] Integration test SHA512 checksum persistence in `hastighedTests/SHA512ChecksumPersistenceTests.swift`
- [ ] T011 [P] Performance test SHA512 validation for large files in `hastighedTests/SHA512ValidationPerformanceTests.swift`

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Data Models
- [x] T012 Update DatasetListing model to include SHA512 checksum URLs in `hastighed/Models/OfflineMaps/DatasetListing.swift`
- [x] T013 Update DownloadItem model to include SHA512 update status in `hastighed/Models/OfflineMaps/DownloadItem.swift`

### Services
- [x] T014 Update OfflineMapsViewModel to integrate SHA512 services in `hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift`

### UI Components
- [x] T015 [P] Create UpdateButtonView component in `hastighed/Views/Components/UpdateButtonView.swift`
- [ ] T016 Update OfflineMapsSectionView to show update indicators in `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift`

## Phase 3.4: Integration
- [ ] T017 Integrate SHA512ChecksumService with DownloadService for automatic SHA512 validation
- [ ] T018 Integrate SHA512DownloadService with settings view presentation checks
- [ ] T019 Integrate UpdateDetectionService with UI state management
- [ ] T020 Add SHA512 checksum persistence to existing download state persistence
- [ ] T021 Add update detection to settings view onAppear sequence

## Phase 3.5: Polish
- [ ] T022 [P] Unit tests for SHA512 validation edge cases in `hastighedTests/SHA512ValidationEdgeCasesTests.swift`
- [ ] T023 [P] Unit tests for SHA512 comparison logic in `hastighedTests/SHA512ComparisonLogicTests.swift`
- [ ] T024 [P] Performance tests for SHA512 validation on large files in `hastighedTests/SHA512ValidationPerformanceTests.swift`
- [ ] T025 [P] Accessibility tests for update button in `hastighedUITests/UpdateButtonAccessibilityTests.swift`
- [ ] T026 [P] Update documentation with SHA512 checksum feature in `README.md`
- [ ] T027 Remove debug logging and optimize SHA512 validation
- [ ] T028 Run manual testing for SHA512-based update detection scenarios

## Dependencies
- Tests (T005-T011) before implementation (T012-T015)
- T012-T013 (Models) before T014 (Services)
- T014 (Services) before T016 (UI)
- T014 (Services) before T017-T021 (Integration)
- Implementation before polish (T022-T028)

## Parallel Execution Examples

### Phase 3.2: Test Development (T005-T011)
```bash
# Launch all test tasks in parallel:
Task: "Create contract test SHA512 checksum validation in hastighedTests/SHA512ChecksumServiceTests.swift"
Task: "Create contract test .sha512 file downloading in hastighedTests/SHA512DownloadServiceTests.swift"
Task: "Create contract test SHA512 comparison logic in hastighedTests/SHA512ComparisonServiceTests.swift"
Task: "Create integration test update button visibility in hastighedTests/UpdateButtonVisibilityTests.swift"
Task: "Create UI test update button interaction in hastighedUITests/UpdateButtonUITests.swift"
Task: "Create integration test SHA512 checksum persistence in hastighedTests/SHA512ChecksumPersistenceTests.swift"
Task: "Create performance test SHA512 validation for large files in hastighedTests/SHA512ValidationPerformanceTests.swift"
```

### Phase 3.3: Model Creation (T012-T013)
```bash
# Launch model creation tasks in parallel:
Task: "Update DatasetListing model to include SHA512 checksum URLs in hastighed/Models/OfflineMaps/DatasetListing.swift"
Task: "Update DownloadItem model to include SHA512 update status in hastighed/Models/OfflineMaps/DownloadItem.swift"
```

### Phase 3.3: Service Creation (T014)
```bash
# Launch service creation tasks in parallel:
Task: "Update OfflineMapsViewModel to integrate SHA512 services in hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift"
```

### Phase 3.3: UI Component Creation (T015)
```bash
# Launch UI component tasks in parallel:
Task: "Create UpdateButtonView component in hastighed/Views/Components/UpdateButtonView.swift"
```

## Feature Requirements Summary

### SHA512 Checksum Tracking
- Download both .gpkg and .sha512 files for each dataset
- Validate local .gpkg files against their .sha512 files
- Store SHA512 checksum metadata with download completion
- Persist SHA512 checksum data across app launches
- Support SHA512 validation for large files (>500MB)

### Remote .sha512 File Fetching
- Download .sha512 files from remote URLs (e.g., liechtenstein.gpkg.sha512)
- Cache remote .sha512 files with timestamps
- Handle network failures gracefully
- Check for updates when settings view is presented

### Update Detection
- Compare local .sha512 file content with remote .sha512 file content
- Detect changes when SHA512 checksums differ
- Show "update available" indicator in settings view
- Show update button on maps with different SHA512 versions

### Update Button UI
- Show update button only when SHA512 checksums differ
- Position next to download/delete button
- Use refresh icon with visual indicator
- Support accessibility with VoiceOver labels
- Show different SHA512 version information

### Integration Points
- Integrate with existing DownloadService to download both file types
- Integrate with existing OfflineMapsViewModel for settings view checks
- Integrate with existing UI components
- Maintain existing download functionality
- Trigger update checks on settings view presentation

## Validation Checklist
*GATE: Checked before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] SHA512 validation supports large files
- [ ] Update detection based on SHA512 checksum comparison
- [ ] UI integration maintains existing functionality
- [ ] Performance requirements met (<2s load, <100MB memory)
- [ ] Settings view triggers update checks on presentation
- [ ] Both .gpkg and .sha512 files are downloaded together

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- SHA512 validation must be efficient for large files
- Update detection must be reliable and fast
- UI must maintain existing design patterns
- Update checks triggered on settings view presentation
- Both file types (.gpkg and .sha512) downloaded together
- Use Swift Crypto framework for SHA512 calculations
- Keep number of files to a minimum for maintainability