import UIKit
import SnapKit

/// Small 6-column board preview used on the Home "Puzzle of the day" card and
/// in list rows. Uses a static position rather than a full `Board` so it stays
/// cheap to render.
final class PreviewBoardView: UIView {

    private static let layout: [[String]] = [
        ["·", "·", "♜", "·", "♚", "·"],
        ["·", "·", "·", "·", "♟", "♟"],
        ["·", "·", "·", "·", "·", "♞"],
        ["·", "·", "·", "·", "·", "·"],
        ["·", "·", "·", "·", "·", "·"],
        ["·", "·", "·", "♕", "·", "·"]
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        setNeedsLayout()
        subviews.enumerated().forEach { (_, v) in
            if let label = v as? ColorTaggedLabel {
                label.refresh()
            }
        }
    }

    private func build() {
        for (r, row) in Self.layout.enumerated() {
            for (c, value) in row.enumerated() {
                let tile = ColorTaggedLabel(isLight: (r + c).isMultiple(of: 2))
                tile.text = value == "·" ? "" : value
                tile.font = .systemFont(ofSize: 22)
                tile.textAlignment = .center
                addSubview(tile)
                tile.refresh()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cols = Self.layout[0].count
        let rows = Self.layout.count
        let w = bounds.width / CGFloat(cols)
        let h = bounds.height / CGFloat(rows)
        for (idx, sub) in subviews.enumerated() {
            let r = idx / cols, c = idx % cols
            sub.frame = CGRect(x: CGFloat(c) * w, y: CGFloat(r) * h, width: w, height: h)
        }
    }
}

final class ColorTaggedLabel: UILabel {
    let isLight: Bool
    init(isLight: Bool) {
        self.isLight = isLight
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh() {
        backgroundColor = isLight ? Theme.color(\.sqLight) : Theme.color(\.sqDark)
        textColor = isLight ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.95, alpha: 1)
    }
}
