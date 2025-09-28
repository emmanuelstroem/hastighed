# Tasks: GPKG Download 4-State Management

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
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- iOS app in this repository:
  - Source: `hastighed/` (Models, Services, ViewModels, Views)
  - Tests: `hastighedTests/`, `hastighedUITests/`
- Paths shown below assume this structure; adjust if the plan specifies otherwise

## Phase 3.1: Setup
- [ ] T001 [P] Configure SwiftUI icon system for 4-state download management
- [ ] T002 [P] Set up test infrastructure for download state transitions

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] T003 [P] Contract test: Download state transitions in `hastighedTests/DownloadStateTransitionTests.swift`
- [ ] T004 [P] Contract test: Icon visibility logic in `hastighedTests/DownloadIconVisibilityTests.swift`
- [ ] T005 [P] Integration test: Complete download flow in `hastighedTests/DownloadFlowIntegrationTests.swift`
- [ ] T006 [P] UI test: 4-state button behavior in `hastighedUITests/DownloadButtonUITests.swift`

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Model Updates
- [ ] T007 Update DownloadItem model to support all 4 states in `hastighed/Models/OfflineMaps/DownloadItem.swift`
- [ ] T008 Add state transition validation logic in `hastighed/Models/OfflineMaps/DownloadItem.swift`

### Service Layer Updates
- [ ] T009 Update DownloadService to handle resume state properly in `hastighed/Services/OfflineMaps/DownloadService.swift`
- [ ] T010 Add delete state management in DownloadService in `hastighed/Services/OfflineMaps/DownloadService.swift`
- [ ] T011 Implement proper state persistence for all 4 states in `hastighed/Services/OfflineMaps/DownloadService.swift`

### ViewModel Updates
- [ ] T012 Update OfflineMapsViewModel to expose 4-state logic in `hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift`
- [ ] T013 Add state-based icon selection logic in `hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift`

## Phase 3.4: UI Implementation

### Icon System
- [ ] T014 Create DownloadIconView component with 4-state support in `hastighed/Views/Components/DownloadIconView.swift`
- [ ] T015 Implement circular progress ring for download state in `hastighed/Views/Components/DownloadIconView.swift`
- [ ] T016 Add proper accessibility labels for each state in `hastighed/Views/Components/DownloadIconView.swift`

### View Updates
- [ ] T017 Update OfflineMapsSectionView to use new 4-state icon system in `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift`
- [ ] T018 Remove old ProgressToggleButton and replace with DownloadIconView in `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift`
- [ ] T019 Ensure delete icon shows only when file is fully downloaded and available locally in `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift`

## Phase 3.5: Integration
- [ ] T020 Connect DownloadIconView to DownloadService state changes in `hastighed/Views/Components/DownloadIconView.swift`
- [ ] T021 Ensure proper state synchronization between service and UI in `hastighed/ViewModels/OfflineMaps/OfflineMapsViewModel.swift`
- [ ] T022 Add error handling for state transition failures in `hastighed/Services/OfflineMaps/DownloadService.swift`

## Phase 3.6: Polish
- [ ] T023 [P] Unit tests for state transition edge cases in `hastighedTests/DownloadStateEdgeCaseTests.swift`
- [ ] T024 [P] Performance tests for UI responsiveness during state changes in `hastighedTests/DownloadPerformanceTests.swift`
- [ ] T025 [P] Update documentation for 4-state system in `hastighed/Models/OfflineMaps/DownloadItem.swift`
- [ ] T026 Remove unused code and clean up imports in `hastighed/Views/OfflineMaps/OfflineMapsSectionView.swift`
- [ ] T027 Run manual testing for all 4 states and transitions

## Dependencies
- Tests (T003-T006) before implementation (T007-T022)
- T007 blocks T008, T009, T010, T011
- T009 blocks T012, T013
- T014 blocks T015, T016, T017, T018, T019
- T020 blocks T021, T022
- Implementation before polish (T023-T027)

## Parallel Example
```
# Launch T003-T006 together:
Task: "Contract test: Download state transitions in hastighedTests/DownloadStateTransitionTests.swift"
Task: "Contract test: Icon visibility logic in hastighedTests/DownloadIconVisibilityTests.swift"
Task: "Integration test: Complete download flow in hastighedTests/DownloadFlowIntegrationTests.swift"
Task: "UI test: 4-state button behavior in hastighedUITests/DownloadButtonUITests.swift"

# Launch T023-T025 together:
Task: "Unit tests for state transition edge cases in hastighedTests/DownloadStateEdgeCaseTests.swift"
Task: "Performance tests for UI responsiveness in hastighedTests/DownloadPerformanceTests.swift"
Task: "Update documentation for 4-state system in hastighed/Models/OfflineMaps/DownloadItem.swift"
```

## State Transition Rules
1. **Download State**: Show download icon (arrow.down.circle.fill) when no download exists or when resuming from paused
2. **Pause State**: Show pause icon (pause.circle.fill) when download is in progress
3. **Resume State**: Show download icon (arrow.down.circle.fill) when download is paused - same as download state
4. **Delete State**: Show delete icon (trash.circle.fill) ONLY when file is fully downloaded and available locally

## Icon Specifications
- **Download/Resume**: `arrow.down.circle.fill` with green color
- **Pause**: `pause.circle.fill` with orange color  
- **Delete**: `trash.circle.fill` with red color
- **Progress Ring**: Circular progress indicator around the main icon during download
- **Size**: 24pt system font, semibold weight
- **Accessibility**: Each state must have appropriate VoiceOver labels

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts
- Ensure delete icon only appears when `localFileExists(for: datasetIdentifier) == true` AND `downloadStatus == .completed`

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
- [ ] Delete icon visibility logic properly implemented
- [ ] All 4 states have appropriate icons and accessibility labels