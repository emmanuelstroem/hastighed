# Improvement Backlog (Prioritized)

## P0 – Next Milestone (M1)
- Persist tolerance slider using `@AppStorage`.
- Add units toggle (auto-detect region; manual override in Settings view).
- Introduce onboarding screen for location permission rationale + retry path.
- Display confidence badge (chip with percentage & source color coding).
- Add unit tests for `deriveStatus` logic (boundary ± tolerance, over, near, below).
- Refactor service creation: inject via top-level composition root (improves testability).

## P1 – Quality & Foundations
- Add GitHub Actions workflow: build + (future) tests using `make ensure`.
- Create test target + snapshot testing (status color states).
- Add README section: architecture & extension guidelines.
- Implement accessibility audit (Dynamic Type adjustments & VoiceOver labels).
- Add pulsing animation for over-limit state (respect reduced motion).

## P2 – Data & Intelligence
- Expand `SpeedLimitService` to strategy chain (fallback layering: cached map -> heuristics -> default).
- Implement heuristic for road type inference (variance in heading + average speed cluster).
- Cache last known limit with timestamp to smooth transitions.
- Add mph support with locale-driven default.

## P3 – Platform Extensions
- watchOS companion target with haptic alerts.
- CarPlay exploratory info template (if allowed without nav features).
- Widget / Live Activity for glanceable persistent speed state.

## P4 – Telemetry & Privacy (Opt-In)
- Add opt-in settings flag for anonymous performance metrics (no raw coordinates).
- Local logging buffer export for debugging (user-controlled).

## P5 – Developer Experience
- Add `make test` executing real XCTest suite.
- Add `make format` (SwiftFormat / SwiftLint integration) – decide tooling.
- Define contribution guidelines, code style doc.

## P6 – Risk Mitigation Enhancements
- Periodic disclaimer reminder banner (dismissible for session).
- Confidence explanation help sheet.
- Add unit scaling tolerance option (percentage-based tolerance per limit).

## Icebox / Evaluate Later
- Crowdsourced correction submission flow (moderation model needed).
- Offline OSM extract bundling + incremental update mechanism.
- Voice feedback near/over threshold.

---
Updated: 2025-09-19
