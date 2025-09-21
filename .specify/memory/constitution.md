# Hastighed Project Constitution

## Core Principles

### I. Safety & Focus First
Design for minimal distraction. Glanceable UI, clear thresholds, and conservative alerting. CarPlay surfaces must prioritize legibility and driver attention.

### II. Offline‑First by Default
Primary experience must work without internet. Use on‑device GPKG to resolve street name and speed limit; defer downloads and sync when online.

### III. Test‑First (Non‑Negotiable)
TDD workflow using XCTest: write tests, ensure they fail, implement, then refactor. CI enforces tests passing before merge.

### IV. Performance & Efficiency
Honor budgets: <2s load to first meaningful UI; p95 <200ms for GPKG and web queries; low CPU and energy; adaptive refresh 1 Hz–120 fps.

### V. Privacy & Minimal Data
Only collect what’s necessary for functionality. No raw location leaves the device by default. Clear user controls for permissions and network access.

### VI. Simplicity & Clarity
Prefer straightforward designs and readable code over abstractions. Small, composable services with explicit responsibilities.

### VII. Observability & Transparency
Deterministic state and clear runtime indicators. Structured logging for debug builds; user‑facing states should be understandable at a glance.

### VIII. View Composition & Customization
Views must present one primary concern and be configured via parameters. All views are written using the latest SwiftUI and must include a settings entry or parameter to show/hide the view or its sub‑elements. Views must remain passive (no business logic or side‑effectful operations inside views); delegate to ViewModels/services.

### IX. Single‑Responsibility Functions
Each function performs exactly one purpose and is independently testable. Prefer small, named helpers over multi‑purpose methods.

### X. Build Integrity
Builds must succeed at all times after final code changes. Broken builds block merges; fix‑forward promptly.

### XI. Platform Currency
Code should adopt the latest stable Swift, SwiftUI, and Apple frameworks available for the project’s target platform. Favor modern APIs over deprecated or legacy approaches.

### XII. Performance Non‑Regression
Changes must not degrade energy (battery), CPU, or memory beyond budgets. Measure and verify when in doubt; optimize for efficiency by default.

## Technical Baseline & Constraints

### Platform & Stack
- Language: Swift 6.x
- Target Platform: iOS 17+
- UI: SwiftUI (Liquid Glass aesthetic on device; CarPlay Ultra focus in vehicle)
- Networking/Reachability: Network framework (NWPathMonitor)
- Location: CoreLocation
- Testing: XCTest (unit, integration, UI as needed)

### Performance Goals
- Load: <2 seconds to first meaningful UI (post‑permission)
- Interaction: perceptually instant speed and view refresh
- Refresh rate: adaptive between 1 Hz and 120 fps based on motion/state
- Efficiency: low energy and CPU utilization as default behavior

### Constraints
- Offline‑first with GPKG for street/speed lookups
- Memory utilization: <100 MB steady state
- Latency: p95 <200 ms for on‑device GPKG queries and web requests

### Scale / Scope
- 50k users
- 1M LOC repository scale target (upper bound planning)

### CarPlay Support
- Provide a CarPlay display for current speed, speed limit, and alerts
- Follow CarPlay HIG; minimize interaction and maximize legibility
- Audible alert when current speed exceeds 5% over the current limit; visual parity with on‑device UI

### UI Thresholds
- Amber state when within ±5% of current speed limit
- Red state when exceeding the limit (beyond the ±5% amber band)

## Development Workflow & Quality Gates

### Documentation Flow
- Use /.specify tools: spec → plan → tasks → implementation
- Specs avoid implementation details; plans capture design and contracts; tasks enumerate actionable steps (TDD order)

### Branching & Reviews
- Feature branches per spec number (e.g., 003‑feature‑name)
- PRs must link spec/plan/tasks and meet gates below

### Required Gates (All Must Pass)
1. Tests: New/changed code has XCTest coverage; tests written first and passing in CI
2. Performance: Budgets respected (<2s load; p95 <200ms; adaptive refresh; low CPU/energy)
3. Offline: Core flows usable without internet; no hard dependency on network for MVP behaviors
4. Accessibility: Dynamic Type supported; clear labels for critical UI
5. Privacy: No unnecessary data retention; user can disable app network access from settings
6. Simplicity: Avoid unnecessary abstractions; code is readable and maintainable
7. CarPlay: If feature touches driving UI, CarPlay parity considered and documented
8. Build: Final code changes must compile successfully; CI green before merge
9. Views: One‑thing focus, parameterized customization, latest SwiftUI, show/hide setting, no business logic in views
10. Functions: Single responsibility and unit‑testable
11. Platform: Prefer latest stable Swift and Apple APIs over legacy

### Observability & Debugging
- Provide debug overlays and structured logs in debug builds; keep production logs minimal and privacy‑preserving

### Security
- Depend on platform entitlements and least‑privilege permissions
- Validate downloads; allow pause/resume/delete for user‑initiated packages

## Governance

- This constitution supersedes ad‑hoc practices for this repository
- Amendments require a PR updating this document, rationale in the description, and maintainer approval
- All PRs must affirm compliance with Core Principles and Quality Gates
- Deviations require a “Complexity Tracking” entry in the plan with justification and an exit strategy

**Version**: 1.0.0 | **Ratified**: 2025‑09‑21 | **Last Amended**: 2025‑09‑21
# [PROJECT_NAME] Constitution
<!-- Example: Spec Constitution, TaskFlow Constitution, etc. -->

## Core Principles

### [PRINCIPLE_1_NAME]
<!-- Example: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: Every feature starts as a standalone library; Libraries must be self-contained, independently testable, documented; Clear purpose required - no organizational-only libraries -->

### [PRINCIPLE_2_NAME]
<!-- Example: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Every library exposes functionality via CLI; Text in/out protocol: stdin/args → stdout, errors → stderr; Support JSON + human-readable formats -->

### [PRINCIPLE_3_NAME]
<!-- Example: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: TDD mandatory: Tests written → User approved → Tests fail → Then implement; Red-Green-Refactor cycle strictly enforced -->

### [PRINCIPLE_4_NAME]
<!-- Example: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: Focus areas requiring integration tests: New library contract tests, Contract changes, Inter-service communication, Shared schemas -->

### [PRINCIPLE_5_NAME]
<!-- Example: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Example: Text I/O ensures debuggability; Structured logging required; Or: MAJOR.MINOR.BUILD format; Or: Start simple, YAGNI principles -->

## [SECTION_2_NAME]
<!-- Example: Additional Constraints, Security Requirements, Performance Standards, etc. -->

[SECTION_2_CONTENT]
<!-- Example: Technology stack requirements, compliance standards, deployment policies, etc. -->

## [SECTION_3_NAME]
<!-- Example: Development Workflow, Review Process, Quality Gates, etc. -->

[SECTION_3_CONTENT]
<!-- Example: Code review requirements, testing gates, deployment approval process, etc. -->

## Governance
<!-- Example: Constitution supersedes all other practices; Amendments require documentation, approval, migration plan -->

[GOVERNANCE_RULES]
<!-- Example: All PRs/reviews must verify compliance; Complexity must be justified; Use [GUIDANCE_FILE] for runtime development guidance -->

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
<!-- Example: Version: 2.1.1 | Ratified: 2025-06-13 | Last Amended: 2025-07-16 -->