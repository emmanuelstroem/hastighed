## Feature: Responsive Geometry & Dynamic Type

### Overview
Add responsive geometry so all views scale within device boundaries across iPhone and iPad, in all orientations. Adopt Dynamic Type so all text scales with the user's preferred content size without clipping or truncation.

### Problem Statement
Several views use fixed sizes and fonts, which may clip on small devices or look too small/large on iPad. We need an adaptive layout that:
- Respects safe areas and available container size
- Scales UI elements proportionally
- Adopts Dynamic Type for accessibility and legibility

### Goals
- Views never overflow or get clipped on any supported device or orientation.
- Layout adapts naturally on iPad (including split view), maintaining visual hierarchy.
- All text uses Dynamic Type styles and scales correctly up to largest accessibility sizes.
- Maintain 60 fps rendering and avoid layout loops.

### Non-Goals
- No redesign of app flows or navigation.
- No new backend or data contracts.

### User Stories
- As a driver, I want the speedometer and limit sign to fit my screen so nothing is cut off on small iPhones.
- As an iPad user, I want the UI to scale and layout well in full screen and split view.
- As a user with larger text settings, I want labels to scale without truncation so I can read them easily.

### Functional Requirements
- Replace hard-coded frames with responsive sizing using container geometry (e.g., GeometryReader, containerRelativeFrame).
- Constrain widths/heights to available bounds; use scalable vector shapes where possible.
- Use size classes and scene phase/orientation to adapt major layout decisions.
- All text uses Dynamic Type-friendly APIs (Text styles) with `.dynamicTypeSize(...)` where needed.
- Ensure important text has `.minimumScaleFactor` and `.lineLimit` policies to avoid clipping.
- Respect safe areas and consider inset content when necessary.

### Non-Functional Requirements
- Performance: Maintain 60 fps; avoid excessive layout recalculations.
- Accessibility: Support Dynamic Type up to accessibility sizes; maintain contrast and tappable sizes.
- Maintainability: Centralize sizing rules to avoid scattering magic numbers.

### Acceptance Criteria
- On iPhone SE, iPhone 15 Pro Max, iPad 11", iPad 12.9" (portrait/landscape), no view content is clipped.
- With Dynamic Type set to Extra Extra Extra Large and Accessibility sizes, primary labels remain readable and layout remains within bounds (may wrap or scale as specified).
- UI passes manual checks in split view on iPad (1/2 and 1/3 width) without overflow.
- No regression to core features in `HomeView`, `SpeedMonitoringView`, `SettingsView`.

### Constraints & Dependencies
- SwiftUI app; no new third-party dependencies.
- iOS/iPadOS target: keep current project minimum.
- Use SwiftUI primitives: GeometryReader, ViewThatFits, containerRelativeFrame, size classes, Dynamic Type.

### Risks
- Over-scaling can reduce legibility; mitigate with sensible min/max bounds.
- Complex geometry can cause layout loops; mitigate with stateless derived sizes.

### Success Metrics
- Visual QA across device matrix passes.
- Accessibility audit for Dynamic Type passes.
- No performance regressions observed in Instruments (layout time remains stable).


