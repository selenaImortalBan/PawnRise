import UIKit
import SnapKit

/// Solid accent button ("Грати зараз" etc.). Mirrors `.btn-acc` styling.
public final class PrimaryButton: UIButton {

    public init(title: String, icon: UIImage? = nil) {
        super.init(frame: .zero)
        configure(title: title, icon: icon)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        backgroundColor = Theme.color(\.acc)
    }

    private func configure(title: String, icon: UIImage?) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .small
        config.baseBackgroundColor = Theme.color(\.acc)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 11, leading: 20, bottom: 11, trailing: 20)
        if let icon { config.image = icon.withRenderingMode(.alwaysTemplate); config.imagePadding = 7 }
        var attr = AttributedString(title.uppercased())
        attr.font = .systemFont(ofSize: 12, weight: .semibold)
        attr.kern = 0.6
        config.attributedTitle = attr
        configuration = config
    }
}

/// Outlined secondary button. Mirrors `.btn-ghost`.
public final class GhostButton: UIButton {

    public init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        var attr = AttributedString(title)
        attr.font = .systemFont(ofSize: 12, weight: .medium)
        attr.kern = 0.3
        attr.foregroundColor = Theme.color(\.tx2)
        config.attributedTitle = attr
        configuration = config

        layer.borderWidth = 1
        layer.cornerRadius = 8
        layer.borderColor = Theme.color(\.brd2).cgColor
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        layer.borderColor = Theme.color(\.brd2).resolvedColor(with: traitCollection).cgColor
    }
}
