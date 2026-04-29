import UIKit
import SnapKit

public final class PlayerRowView: UIView {

    public struct Configuration {
        public let glyph: String
        public let name: String
        public let elo: Int
        public init(glyph: String, name: String, elo: Int) {
            self.glyph = glyph; self.name = name; self.elo = elo
        }
    }

    private let avatar = UILabel()
    private let nameLabel = UILabel()
    private let eloLabel = UILabel()
    private let clockLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func configure(_ config: Configuration) {
        avatar.text = config.glyph
        nameLabel.text = config.name
        eloLabel.text = "\(config.elo)"
    }

    public func setClock(seconds: Int, ticking: Bool) {
        let m = seconds / 60
        let s = seconds % 60
        clockLabel.text = String(format: "%d:%02d", m, s)
        clockLabel.textColor = ticking ? Theme.color(\.acc) : Theme.color(\.tx3)
        clockLabel.backgroundColor = ticking ? Theme.color(\.accd) : .clear
        clockLabel.layer.borderColor = ticking ? Theme.color(\.accbrd).cgColor : UIColor.clear.cgColor
        clockLabel.layer.borderWidth = ticking ? 1 : 0
        clockLabel.layer.cornerRadius = 6
        clockLabel.layer.masksToBounds = true
        clockLabel.textAlignment = .center
    }

    private func build() {
        avatar.font = .systemFont(ofSize: 14)
        avatar.textAlignment = .center
        avatar.backgroundColor = Theme.color(\.s2)
        avatar.layer.cornerRadius = 5
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 1
        avatar.layer.borderColor = Theme.color(\.brd2).cgColor
        avatar.snp.makeConstraints { make in make.size.equalTo(22) }

        nameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        nameLabel.textColor = Theme.color(\.tx1)

        eloLabel.font = .monospacedSystemFont(ofSize: 9.5, weight: .regular)
        eloLabel.textColor = Theme.color(\.tx3)

        clockLabel.font = .monospacedSystemFont(ofSize: 18, weight: .medium)
        clockLabel.textColor = Theme.color(\.tx3)

        let leftStack = UIStackView(arrangedSubviews: [avatar, nameLabel, eloLabel])
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 6

        let row = UIStackView(arrangedSubviews: [leftStack, UIView(), clockLabel])
        row.axis = .horizontal
        row.alignment = .center
        addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14))
        }
    }
}
