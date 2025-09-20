# Quickstart: Driving Speed & Permission at Launch

## Prerequisites
- Real device recommended (GPS); Simulator speed can be simulated.
- Location permission strings configured in Info.plist.

## Steps
1. Launch the app.
2. On first launch (permission notDetermined), grant location permission when prompted.
3. Observe the speed value update within ~2 seconds while driving or simulating.
4. Deny permission, relaunch, and observe in-app explainer with a button to open Settings; tap it to enable permission and return.
5. Drive to a stop; confirm speed settles to 0 after a brief debounce.

## Expected Results
- Speed updates at ~1 Hz with minimal jitter.
- When permission is denied, no numeric speed is shown; Settings deep-link is available.
- Stale indicator appears if no updates for >3 seconds.

