import SwiftUI

/// Centralized geometry helper for proportional sizing.
/// Computes a base dimension from the available container and exposes
/// commonly used sizes with sensible clamping to keep UI legible.
struct LayoutGuide {
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets

    /// The shortest side after accounting for safe area insets.
    var base: CGFloat {
        let width = containerSize.width - (safeAreaInsets.leading + safeAreaInsets.trailing)
        let height = containerSize.height - (safeAreaInsets.top + safeAreaInsets.bottom)
        return max(0, min(width, height))
    }

    func clamped(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        return max(minValue, min(maxValue, value))
    }

    /// Recommended gauge diameter for portrait layout.
    func gaugeDiameterPortrait(maxWidth: CGFloat) -> CGFloat {
        let proposed = base * 0.8
        return clamped(min(proposed, maxWidth - 40), min: 160, max: 520)
    }

    /// Recommended gauge diameter for landscape layout.
    func gaugeDiameterLandscape(maxHeight: CGFloat) -> CGFloat {
        let proposed = base * 0.9
        return clamped(min(proposed, maxHeight - 80), min: 180, max: 600)
    }

    /// Recommended speed limit sign diameter (works both orientations).
    var signDiameter: CGFloat {
        clamped(base * 0.28, min: 96, max: 240)
    }

    /// Proportional spacing unit.
    var spacing: CGFloat { clamped(base * 0.03, min: 8, max: 24) }
}


