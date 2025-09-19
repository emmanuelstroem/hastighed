# Tasks: Responsive Geometry & Dynamic Type

**Input**: Design documents from `/specs/001-responsive-geometry/`
**Prerequisites**: plan.md (required), research.md, data-model.md, quickstart.md

## Execution Flow (main)
```
1. Load plan.md and supporting docs
2. Write tests/validation steps (Quickstart) before implementation
3. Implement geometry + dynamic type by component
4. Validate across device matrix and orientations
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Phase 3.1: Setup
- [ ] T001 Add `LayoutGuide` helper in `hastighed/Views/Components/LayoutGuide.swift` to centralize proportional sizing (base = min(w,h))
- [ ] T002 Add preview device group in `#Preview` helpers for iPhone SE/Pro Max/iPad 11/12.9 portrait+landscape to speed validation

## Phase 3.2: Tests First (validation scenarios)
- [ ] T003 [P] Update `specs/001-responsive-geometry/quickstart.md` with concrete device matrix checks per images (portrait/landscape positioning)
- [ ] T004 [P] Add UI notes to `research.md` documenting chosen breakpoints and min/max clamps

## Phase 3.3: Core Implementation
- [ ] T005 Refactor `hastighed/Views/Components/GaugeArcView.swift` to accept `diameter` instead of fixed `size`; clamp lineWidth proportionally
- [ ] T006 Refactor `hastighed/Views/Components/SpeedometerView.swift` to drive font size from provided `diameter` and adopt `.font(.system(.largeTitle, design: .rounded))` with Dynamic Type and `.minimumScaleFactor(0.5)`
- [ ] T007 Refactor `hastighed/Views/Components/SpeedLimitSignView.swift` to compute `diameter` externally; ensure text uses Dynamic Type and respects `.minimumScaleFactor(0.7)`; keep ring proportional
- [ ] T008 Wire responsive geometry in `hastighed/Views/HomeView.swift` using `GeometryReader` at top-level:
  - Compute `base = min(proxy.size.width, proxy.size.height)`
  - Gauge diameter ≈ `min(base*0.8, proxy.size.width-40)` in portrait; `min(base*0.9, proxy.size.height-80)` in landscape
  - Place `SpeedLimitSignView` sized as `clamp(base*0.28, min: 96, max: 220)` bottom (portrait) or trailing (landscape) per screenshots
  - Convert fixed paddings to proportional where appropriate and respect safe areas
- [ ] T009 Ensure `HomeView` labels use text styles (`.largeTitle`, `.headline`, `.caption2`) and support Dynamic Type ranges; apply `.lineLimit` and `.minimumScaleFactor` as needed
- [ ] T010 Update `hastighed/Views/SpeedMonitoringView.swift` to compute card heights from geometry and adopt Dynamic Type for all text; avoid hard-coded font sizes (86/48) in favor of proportional to base

## Phase 3.4: Integration
- [ ] T011 Verify layouts with iPad split view (1/2 and 1/3 width) and adjust `ViewThatFits` wrappers around clusters that need compact alternatives in `HomeView`
- [ ] T012 Ensure settings button hit target remains ≥44pt and stays within bounds in all orientations

## Phase 3.5: Polish
- [ ] T013 [P] Add accessibility audit pass: Large accessibility text sizes behave without clipping; adjust `.dynamicTypeSize(... .accessibility5)` if needed
- [ ] T014 [P] Instrument basic performance check: ensure no layout loops; large view recomputes avoided (pass derived sizes down)
- [ ] T015 Update `specs/001-responsive-geometry/quickstart.md` results after verification

## Dependencies
- T001 before T005–T010
- T003–T004 before core implementation (T005–T010)
- T005–T010 before integration validation (T011–T012)
- Implementation before polish (T013–T015)

## Parallel Example
```
# After setup (T001–T002), run in parallel:
Task: "Update quickstart validation" (T003)
Task: "Document clamps in research" (T004)

# During polish, run in parallel:
Task: "Accessibility audit" (T013)
Task: "Performance check" (T014)
```

## Notes
- Use `GeometryReader` only at container level; pass down diameters to avoid nested geometry readers
- Prefer `.font(.title/.headline/.caption)` for Dynamic Type; clamp with `.minimumScaleFactor`
- Respect safe areas and use `.safeAreaInset` if needed

## Phase 3.6: Gauge Color Thresholds and Parameters
- [ ] G001 Update `hastighed/Views/Components/GaugeArcView.swift` to accept `speedValue` and `speedLimit` and compute `progress` internally
- [ ] G002 Implement 5% buffer calculation: `buffer = speedLimit * 0.05`
- [ ] G003 Apply color rules: `teal` when `speedValue <= speedLimit`; `orange` when `speedValue <= speedLimit + buffer`; `red` otherwise
- [ ] G004 [P] Add unit tests (if applicable) or preview scenarios covering boundary values (exact limit, at +5%, over +5%)
- [ ] G005 Wire `HomeView` to pass `speedValue` and `speedLimit` into `GaugeArcView` and remove external `progressColor` usage
- [ ] G006 Validate visuals on iPhone SE/Pro Max and iPad in portrait/landscape per screenshots

### Dependencies
- G001–G003 before G005
- Validation (G006) after wiring (G005)
- G004 can be run in parallel after G003

## Phase 3.7: Orientation-based Arrangement of Gauge and Sign
- [ ] O001 Update `hastighed/Views/HomeView.swift` to place the gauge and speed limit sign in a `VStack` in portrait
- [ ] O002 Update `hastighed/Views/HomeView.swift` to place the gauge and speed limit sign in a `HStack` in landscape (side by side), maintaining spacing and alignment from `LayoutGuide`
- [ ] O003 Ensure consistent sizing rules for both orientations using `LayoutGuide` (shared diameter for gauge and sign proportions)
- [ ] O004 [P] Add preview cases for portrait and landscape verifying side-by-side vs stacked layouts
- [ ] O005 Validate on iPad split view that `HStack` variant still fits within bounds

### Dependencies
- O001 before O002 (shared helpers first)
- O003 after O001/O002
- Previews (O004) can run in parallel after O001

## Phase 3.8: Rotation Transition Animations
- [ ] R001 Introduce `@Namespace var gaugeNS` in `HomeView.swift` and wrap gauge/sign containers with `matchedGeometryEffect` IDs for portrait/landscape positions
- [ ] R002 Use `.transition(.scale.combined(with: .opacity))` for smaller elements and `.transition(.identity)` for matched elements
- [ ] R003 Apply `withAnimation(.spring(response: 0.35, dampingFraction: 0.85))` when orientation changes to drive smooth repositioning along shortest path
- [ ] R004 Ensure state is orientation-driven (from geometry) to avoid duplicate animations; use `.animation(nil)` on subviews that shouldn’t animate independently
- [ ] R005 [P] Add preview that toggles between sizes (portrait <-> landscape) to visually validate transitions
- [ ] R006 Validate on devices that rotation produces smooth, natural motion with no jitter

### Dependencies
- R001 before R003
- Previews (R005) can run in parallel after R001–R002
