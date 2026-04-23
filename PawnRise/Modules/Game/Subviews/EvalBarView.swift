import UIKit
import SnapKit

/// Vertical evaluation bar. Top half = black, bottom half = white.
public final class EvalBarView: UIView {

    private let whitePart = UIView()
    private var evaluationCP: Int = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.color(\.sqDark)
        layer.cornerRadius = 2
        clipsToBounds = true

        whitePart.backgroundColor = Theme.color(\.sqLight)
        addSubview(whitePart)
        update(cp: 0)
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func update(cp: Int) {
        evaluationCP = cp
        // Clamp to [-800, 800] and map to [0, 1] share for white.
        let clamped = Double(max(-800, min(800, cp)))
        let whiteShare = 0.5 + clamped / 1600.0
        setNeedsLayout()
        _whiteShare = CGFloat(whiteShare)
    }

    private var _whiteShare: CGFloat = 0.5
    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height * _whiteShare
        whitePart.frame = CGRect(x: 0, y: bounds.height - h, width: bounds.width, height: h)
    }
}
