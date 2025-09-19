# Research: Responsive Geometry & Dynamic Type

## Unknowns from Technical Context
- Best pattern to keep vector gauges within bounds without hard-coded frames.
- Handling Dynamic Type for custom gauges and labels simultaneously.
- iPad split view adaptations using size classes.

## Findings

### Geometry & Sizing
- Use GeometryReader at top container to derive `min(availableWidth, availableHeight)` as base size.
- Use containerRelativeFrame where possible to let system cap sizes.
- Prefer ViewThatFits to swap layouts for narrow vs wide configurations.
- Use safeAreaInset or padding to keep content off notches/home indicator.

### Proportional Scaling
- Define a `LayoutScale` struct to compute sizes as percentages of base.
- Clamp sizes with sensible min/max to avoid illegible UI on extreme sizes.

### Dynamic Type
- Use Text with `.font(.largeTitle/.title/.body)` and let system scale.
- Where precise scaling needed, apply `.dynamicTypeSize(..., .. .accessibility5)` to allow full range.
- Combine `.minimumScaleFactor` with `.lineLimit(1 or nil)` per label importance.

### Size Classes & iPad
- Use `@Environment(\.horizontalSizeClass)` and `\.verticalSizeClass` to branch high-level layouts.
- In split view, width is reduced; rely on GeometryReader and ViewThatFits for graceful degradation.

### Performance
- Avoid stateful geometry in view state; compute sizes in body from GeometryProxy.
- Avoid multiple nested GeometryReaders; pass computed sizes down as parameters.

## Decisions
- Introduce a small `LayoutGuide` to centralize size calculations.
- Update views to consume sizes instead of fixed constants.
- Adopt Dynamic Type across all `Text` and adjust custom components for scaling.

## Alternatives Considered
- UIScreen-based fixed breakpoints: rejected for split view and device diversity.
- Third-party layout helpers: rejected to minimize dependencies.


