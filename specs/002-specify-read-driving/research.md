# Research: Driving speed + Permission at launch

## Unknowns and Resolutions
- Behavior outside automotive context → Resolution: Still compute and display speed; rely on low-speed threshold and debounce to avoid misleading “driving” state. No special label change in this iteration.
- Poor accuracy threshold for suppressing numeric speed → Resolution: Use `speedAccuracy` when available; consider readings high-confidence when `speedAccuracy ≤ 1.5 m/s` (~5.4 km/h). If absent or worse, mark display as low-confidence/stale and avoid rapid changes.
- Background updates → Resolution: Scope this iteration to foreground updates only. Background behavior is out of scope.
- Permission guidance copy/flow → Resolution: Provide simple, clear rationale on first permission prompt and, if denied, show an in-app explainer with a button to open the app’s Settings page.

## Decisions
- Use CoreLocation with an automotive-optimized configuration for speed derivation.
- Check permission at launch and react according to state:
  - notDetermined → request WhenInUse permission once with rationale
  - authorizedWhenInUse/authorizedAlways → start location updates and speed computation
  - denied/restricted → show explainer and button to open Settings (deep link)
- Low-speed handling: threshold 3 km/h (2 mph) with ~2–3s debounce before showing 0.
- Stale threshold: 3 seconds without a fresh location update causes stale indication.
- Units: derive from user settings; display km/h or mph consistently.

## Alternatives Considered
- Aggressive smoothing filters → Rejected for now to preserve responsiveness; basic debounce and thresholding suffice.
- Background mode with significant location changes → Rejected for this iteration; complexity versus benefit not justified.

## Rationale
- Aligns with user expectation for car use; follows Apple HIG privacy guidance by explaining why location is needed and providing a path to Settings if denied.

## References
- Apple HIG: Privacy and Permissions (rationale and timing of prompts)
- CoreLocation docs: `CLLocationManager`, `CLLocation.speed`, `CLLocation.speedAccuracy`, permission statuses, `UIApplication.openSettingsURLString`

