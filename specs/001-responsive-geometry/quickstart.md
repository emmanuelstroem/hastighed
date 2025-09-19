# Quickstart: Validate Responsive Geometry & Dynamic Type

1) Build and run on iPhone SE (portrait/landscape)
- Verify no clipping in `HomeView`, `SpeedMonitoringView`, `SettingsView` and all the views in `Components` folder.
- Text scales with system setting; critical labels readable.

2) Build and run on iPhone 16 Pro Max
- Ensure proportional scaling; no excessive empty space; gauges/sign centered.

3) Build and run on iPad 11" and 12.9"
- Full screen: layout scales; elements remain within safe areas.
- Split view: 1/2 and 1/3 widths; verify ViewThatFits chooses compact layout without overflow.

4) Dynamic Type
- Settings → Accessibility → Display & Text Size → Larger Text → set to largest.
- Re-run app; verify no truncation of primary labels, allow wrapping where specified.

5) Performance
- Interact with app; ensure smooth animations (~60 fps). No layout loops or jitter.

Acceptance: All views remain within bounds in all tested configurations without clipping; text remains legible; performance is smooth.
