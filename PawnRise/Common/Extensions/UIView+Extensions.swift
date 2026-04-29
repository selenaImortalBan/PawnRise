import UIKit

public extension UIView {

    /// Sets corner radius and optional border in one go.
    @discardableResult
    func styled(cornerRadius: CGFloat = 0, border: (UIColor, CGFloat)? = nil, clips: Bool = true) -> Self {
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        if let (color, width) = border {
            layer.borderColor = color.cgColor
            layer.borderWidth = width
        }
        if clips { layer.masksToBounds = cornerRadius > 0 }
        return self
    }

    /// Refreshes layer colors that don't automatically adapt to trait changes
    /// (border, shadow, etc.). Call from `traitCollectionDidChange`.
    func refreshDynamicLayerColors(_ borderKey: KeyPath<Palette.Colors, UIColor>? = nil) {
        if let key = borderKey {
            layer.borderColor = Theme.color(key).resolvedColor(with: traitCollection).cgColor
        }
    }
}
