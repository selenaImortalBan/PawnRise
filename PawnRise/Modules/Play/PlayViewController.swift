import UIKit
import SnapKit

public final class PlayViewController: UIViewController, PlayViewInput {

    public typealias StartHandler = (GameMode, Difficulty, Opening?) -> Void

    private let presenter: PlayPresenter
    private let onStart: StartHandler

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private var difficultyButtons: [UIControl] = []

    public init(onStart: @escaping StartHandler,
                presenter: PlayPresenter = PlayPresenter()) {
        self.onStart = onStart
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.color(\.bg)
        presenter.view = self
        buildLayout()
        presenter.viewDidLoad()
    }

    private func buildLayout() {
        view.addSubview(scroll)
        scroll.showsVerticalScrollIndicator = false
        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        scroll.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 8
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scroll)
        }

        stack.addArrangedSubview(buildHeader())
        for mode in [GameMode.rated, .free, .opening] {
            stack.addArrangedSubview(buildModeBlock(mode, featured: mode == .rated))
        }
        stack.addArrangedSubview(UIView.spacer(height: 8))
        stack.addArrangedSubview(buildDifficulty())
        stack.addArrangedSubview(UIView.spacer(height: 24))
    }

    private func buildHeader() -> UIView {
        let wrapper = UIView()
        let title = UILabel()
        title.text = "Режими"
        title.font = .systemFont(ofSize: 26, weight: .semibold)
        title.textColor = Theme.color(\.tx1)

        let sub = UILabel()
        sub.text = "Обери формат — ШІ підлаштується"
        sub.font = .systemFont(ofSize: 12, weight: .regular)
        sub.textColor = Theme.color(\.tx3)

        let stack = UIStackView(arrangedSubviews: [title, sub])
        stack.axis = .vertical
        stack.spacing = 3

        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 18, bottom: 16, right: 18))
        }
        return wrapper
    }

    private func buildModeBlock(_ mode: GameMode, featured: Bool) -> UIView {
        let wrapper = UIView()
        let card = UIControl()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = (featured ? Theme.color(\.accbrd) : Theme.color(\.brd)).cgColor

        let iconWrap = UIView()
        iconWrap.backgroundColor = featured ? Theme.color(\.accd) : Theme.color(\.s2)
        iconWrap.layer.cornerRadius = 9
        iconWrap.layer.borderWidth = 1
        iconWrap.layer.borderColor = (featured ? Theme.color(\.accbrd) : Theme.color(\.brd)).cgColor
        iconWrap.snp.makeConstraints { make in make.size.equalTo(40) }
        let icon = UIImageView(image: modeIcon(mode))
        icon.tintColor = featured ? Theme.color(\.acc) : Theme.color(\.tx2)
        icon.contentMode = .scaleAspectFit
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        let name = UILabel()
        name.text = mode.title
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        name.textColor = Theme.color(\.tx1)

        let desc = UILabel()
        desc.numberOfLines = 0
        desc.text = mode.subtitle
        desc.font = .systemFont(ofSize: 11.5, weight: .light)
        desc.textColor = Theme.color(\.tx3)

        let tagStack = UIStackView()
        tagStack.axis = .horizontal
        tagStack.spacing = 5
        for tag in mode.tags { tagStack.addArrangedSubview(makeTag(tag)) }
        tagStack.addArrangedSubview(UIView())

        let info = UIStackView(arrangedSubviews: [name, desc, tagStack])
        info.axis = .vertical
        info.spacing = 3
        info.setCustomSpacing(7, after: desc)

        let chevron = UIImageView(image: UIImage(systemName: "arrow.right"))
        chevron.tintColor = Theme.color(\.tx4)
        chevron.contentMode = .scaleAspectFit
        chevron.snp.makeConstraints { make in make.size.equalTo(12) }

        let rowStack = UIStackView(arrangedSubviews: [iconWrap, info, chevron])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 13
        card.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 14, bottom: 15, right: 14))
        }
        card.addAction(UIAction { [weak self] _ in self?.startFrom(mode: mode) }, for: .touchUpInside)

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }

    private func startFrom(mode: GameMode) {
        let opening: Opening? = mode == .opening ? OpeningCatalog.all.first : nil
        onStart(mode, presenter.selectedDifficulty, opening)
    }

    private func buildDifficulty() -> UIView {
        let wrapper = UIView()
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "РІВЕНЬ СУПЕРНИКА", attributes: [
            .kern: 1.3,
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: Theme.color(\.tx3)
        ])

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 6
        difficultyButtons.removeAll()
        for diff in Difficulty.allCases {
            let btn = makeDifficultyButton(diff)
            row.addArrangedSubview(btn)
            difficultyButtons.append(btn)
        }
        refreshDifficultySelection()

        let stack = UIStackView(arrangedSubviews: [label, row])
        stack.axis = .vertical
        stack.spacing = 10
        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 12, right: 16))
        }
        return wrapper
    }

    private func makeDifficultyButton(_ diff: Difficulty) -> UIControl {
        let btn = UIControl()
        btn.backgroundColor = Theme.color(\.s1)
        btn.layer.cornerRadius = 9
        btn.layer.borderWidth = 1
        btn.layer.borderColor = Theme.color(\.brd).cgColor
        btn.accessibilityValue = "\(diff.rawValue)"

        let icon = UILabel()
        icon.text = diff.emoji
        icon.font = .systemFont(ofSize: 14)
        icon.textAlignment = .center

        let name = UILabel()
        name.text = diff.title
        name.font = .systemFont(ofSize: 10, weight: .semibold)
        name.textColor = Theme.color(\.tx2)
        name.textAlignment = .center

        let elo = UILabel()
        elo.text = diff.eloRange
        elo.font = .monospacedSystemFont(ofSize: 8.5, weight: .regular)
        elo.textColor = Theme.color(\.tx3)
        elo.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, name, elo])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        btn.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 4, bottom: 11, right: 4))
        }

        btn.addAction(UIAction { [weak self] _ in
            self?.presenter.setDifficulty(diff)
            self?.refreshDifficultySelection()
        }, for: .touchUpInside)
        return btn
    }

    private func refreshDifficultySelection() {
        for (idx, btn) in difficultyButtons.enumerated() {
            let isSelected = idx == presenter.selectedDifficulty.rawValue
            btn.backgroundColor = isSelected ? Theme.color(\.accd) : Theme.color(\.s1)
            btn.layer.borderColor = (isSelected ? Theme.color(\.accbrd) : Theme.color(\.brd)).cgColor
            if let name = (btn.subviews.first?.subviews[1] as? UILabel) {
                name.textColor = isSelected ? Theme.color(\.acc) : Theme.color(\.tx2)
            }
        }
    }

    private func makeTag(_ text: String) -> UIView {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: text.uppercased(), attributes: [
            .kern: 0.6,
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: Theme.color(\.tx3)
        ])
        let box = UIView()
        box.layer.borderWidth = 1
        box.layer.borderColor = Theme.color(\.brd2).cgColor
        box.layer.cornerRadius = 4
        box.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
        }
        return box
    }

    private func modeIcon(_ mode: GameMode) -> UIImage? {
        switch mode {
        case .rated:   return UIImage(systemName: "star.fill")
        case .free:    return UIImage(systemName: "clock")
        case .opening: return UIImage(systemName: "text.alignleft")
        }
    }

    // MARK: - PlayViewInput

    public func render() { /* stateful via presenter */ }
}
