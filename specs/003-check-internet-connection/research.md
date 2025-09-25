# Research: Connectivity & Country Context

## Decisions

1. Connectivity usability check
- Decision: Use `NWPathMonitor` for baseline network status and interface type; perform lightweight reachability to content host at download time to guard against captive portals.
- Rationale: `NWPathMonitor` is the Apple‑recommended API for path status and interface; host reachability avoids false positives.
- Alternatives: Legacy `SCNetworkReachability` (older, less expressive), periodic HTTP pings (wasteful on battery/data).

2. Country detection
- Decision: Prefer CoreLocation reverse‑geocoded country from current location; fall back to manual selection if permission denied; do not rely on SIM/locale for default selection.
- Rationale: Physical presence is most relevant for selecting the correct GPKG; user override handles edge cases.
- Alternatives: SIM country (fails when roaming), locale (user preference, not location).

3. Stability window
- Decision: Apply a 10‑minute stability window before switching active country unless user explicitly overrides.
- Rationale: Prevents thrashing near borders; short enough to adapt to travel.
- Alternatives: Distance‑based hysteresis; to revisit if needed.

4. Cellular policy for large downloads
- Decision: Prompt when on cellular for downloads larger than 50 MB; allow user "Always allow on cellular" preference.
- Rationale: Common UX expectation; protects user data plans.
- Alternatives: Different threshold; configurable later.

5. Download API selection
- Decision: Use URLSession background configuration for large GPKG packages to support resume and system-managed retries; persist resume data; keep file IO on background queues.
- Rationale: Reliability, system handling across app lifecycle, energy efficiency.
- Alternatives: Foreground URLSession (simpler but fragile on app suspension), third-party downloaders.

## Open Questions
- Preferred signal priority when sources conflict (we propose physical location > manual override > device settings).  
- Exact performance target for initial detection.  
- Hostname for reachability checks (content distribution endpoint).


