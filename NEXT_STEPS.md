# Next Steps & Enhancement Plan

## Near-Term (Stabilize MVP)
1. Permissions Onboarding
   - Dedicated first-launch screen explaining need for location.
   - Graceful re-prompt path if denied.
2. Accuracy Indicators
   - Show GPS accuracy / stale data indicator (icon + dimming).
3. Unit Toggle
   - Add setting for mph (auto if region = UK/US).
4. Improved Rule Set
   - Distinguish urban vs rural vs motorway with heuristic (speed variance + location updates). 
5. Basic Settings UI
   - Tolerance slider persisted via `AppStorage`.

## Data Layer Evolution
| Stage | Description | Data Source |
|-------|-------------|-------------|
| 1 | Static rule heuristics (current) | Hardcoded |
| 2 | Country + coarse road class inference | Derived from speed + heading variance |
| 3 | Offline OSM extract for limits | Preprocessed local bundle |
| 4 | Online incremental updates | Remote API (caching layer) |

## Watch & CarPlay Exploration
- Create watchOS target sharing view model code.
- Provide haptic pulses on near/over events.
- Investigate CarPlay template suitability (Mapless or info panel?).

## Performance & Battery
- Adaptive update intervals (reduce frequency under low variability speeds).
- Use `CLLocationManager` `allowsBackgroundLocationUpdates` carefully (policy review).

## Testing Strategy Additions
- Unit tests for status derivation edge cases.
- Mock services for deterministic timeline tests.
- UI snapshot test for status color changes.

## Potential External Integrations (Research Needed)
- HERE / TomTom speed limit APIs cost & licensing.
- OpenStreetMap tag coverage consistency for limits across countries.

## Telemetry (Opt-In Future)
- Anonymized events: app start, permission granted, average session length.
- Never store raw coordinates; only coarse region hash for distribution stats.

## Risk Tracking
| Risk | Next Mitigation Step |
|------|----------------------|
| Over-reliance by users | Add recurring subtle disclaimer banner. |
| Inconsistent OSM tagging | Confidence weighting & fallback layering. |
| Battery complaints | Implement dynamic accuracy scaling. |

## Security & Privacy Hardening
- Audit third-party dependencies policy (currently none).
- Consider differential privacy if adding aggregate metrics.

## Open Questions
- Threshold personalization: should tolerance auto-scale with limit? (e.g., % based?)
- Should UI support horizontal layout (landscape mount)?
- Ideal color palette for colorblind accessibility—add pattern / shape?

## Definition of Done for Next Milestone (M1)
- User can adjust & persist tolerance + units.
- Basic onboarding flow implemented.
- Status accuracy shown (confidence badge).
- At least one automated test target integrated.

---
Living document – update as architecture & insights evolve.
