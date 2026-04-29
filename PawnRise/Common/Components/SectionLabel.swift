import UIKit

public final class SectionLabel: UILabel {
    public init(text: String) {
        super.init(frame: .zero)
        self.text = text.uppercased()
        font = .systemFont(ofSize: 9, weight: .semibold)
        textColor = Theme.color(\.tx3)
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        let attr = NSAttributedString(string: text.uppercased(), attributes: [
            .kern: 1.4,
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: Theme.color(\.tx3)
        ])
        attributedText = attr
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
