# Hastighed

A lightweight, privacy‑respecting iOS app that helps drivers avoid accidental speeding and stay safely within legal limits across Europe.

## Why It Exists
Different countries, road classes, and temporary conditions can cause drivers to unintentionally exceed speed limits. Hastighed provides a clear, glanceable current speed vs. limit indicator so drivers can self‑correct early—reducing risk, stress, and fines.

## MVP Feature Set
- Real‑time current speed (GPS) in km/h.
- Inferred speed limit (rule‑based placeholder initially).
- Status color: green (below), amber (near), red (over).
- Simple configurable tolerance threshold.
- Works in foreground; simulator produces synthetic speed for testing.

## Roadmap (Short Term)
| Phase | Focus |
|-------|-------|
| M0 | Core speed + limit display (this) |
| M1 | Better rule granularity, persistence, settings UI |
| M2 | Background updates (where policy allows), richer limit sources |
| M3 | Watch companion + haptics + CarPlay exploration |

Longer‑term ideas live in `SPEC.md` & `NEXT_STEPS.md`.

## Architecture Snapshot
See `SPEC.md` for full rationale.
```
SwiftUI View -> ViewModel -> (LocationService + SpeedLimitService)
```
All services abstracted by protocols for testability & preview injection.

## Getting Started (Development)
1. Open `hastighed.xcodeproj` in Xcode 15 or later.
2. Build & run on device (recommended) or Simulator.
3. On Simulator, a synthetic ramping speed is shown (since no real GPS speed).
4. Adjust placeholder limit or thresholds in code for experimentation.

## Safety & Responsibility
This app is an assistive tool only. It may display incorrect or outdated limits. Always follow posted road signs and exercise judgment. The developer(s) assume no liability for misuse.

## Privacy
- No external analytics or tracking in MVP.
- Location used only transiently for deriving speed & limit.
- Future opt‑in metrics will exclude precise coordinates.

## Contributing (Early Stage)
The project is pre‑alpha. Structure & APIs may shift rapidly. Feel free to open issues with ideas or data source suggestions.

## License
TBD (likely MIT or Apache‑2.0). Attribution will be added when external datasets are integrated.

---
© 2025 Hastighed Project