# Known Issues & Technical Debt

## Runtime / Logic
1. Duplicate `startUpdatingLocation()` call in `LocationService.start()` (harmless but unnecessary) – remove one invocation.
2. Simulation fallback triggers only on denied permission or failure; could offer explicit debug toggle.
3. `simulationTimer` not invalidated on deinit – potential leak if service lifecycle changes.
4. Confidence value not surfaced in UI (missing transparency promised in spec).
5. `SpeedLimitService` hardcoded heuristics; no abstraction for future strategy layering.
6. Possible negative / stale speed readings not explicitly filtered beyond `>= 0` check.
7. No handling for `authorizationStatus == .restricted` distinct from denial messaging.
8. `latestLocation` not timestamp-validated (stale risk if updates pause).

## Build / Tooling
9. No CI pipeline yet (GitHub Actions candidate) to run `make ensure`.
10. `test` target is placeholder (no test bundle in project yet).

## UI / UX
11. Color palette not accessibility audited (contrast & colorblind safe variants TBD).
12. No onboarding screen for permissions clarifying rationale.
13. No state for “waiting for first speed reading” beyond `--` placeholder.
14. Over-limit visual could use subtle pulse animation to increase salience.

## Architecture
15. ViewModel directly instantiates services in `ContentView` initializer (limits dependency injection flexibility for previews/tests).
16. No protocol for `SpeedLimitService` confidence weighting evolution.
17. Lack of persistence for tolerance slider (reset each launch).

## Testing Gaps
18. No unit tests for `deriveStatus` logic edge cases (tolerance boundaries, negative speeds, large deltas).
19. No integration tests for service + view model pipeline.

## Documentation
20. License not yet declared (will matter before public distribution).
21. No CONTRIBUTING guide or issue templates.

---
Generated: 2025-09-19
