# Data Model: Responsive Geometry & Dynamic Type

## UI Entities
- LayoutGuide
  - base: CGFloat (derived from min(width, height))
  - scale: CGFloat (1.0 baseline)
  - sizes: functions for gaugeDiameter, signSize, spacing
- Typography
  - titleStyle: Font
  - bodyStyle: Font
  - supports Dynamic Type via Text styles

## Relationships
- Views depend on LayoutGuide inputs instead of hard-coded constants.
- Typography applies system Text styles; labels adopt `.minimumScaleFactor` where critical.

## Validation Rules
- No view uses fixed pixel sizes without clamping.
- All text uses system text styles; accessibility sizes render without clipping.
