import UIKit
import SnapKit

/// MVP View for the Home screen. Pure UIKit, layout via SnapKit, delegates
/// interactions to its `HomePresenter`.
public final class HomeViewController: UIViewController, HomeViewInput {

    public typealias Action = () -> Void

    private let presenter: HomePresenter
    private let onStartGame: Action
    private let onGoToPlay: Action
    private let onOpenPuzzles: Action
    private let onOpenAnalysis: Action

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    public init(onStartGame: @escaping Action,
                onGoToPlay: @escaping Action,
                onOpenPuzzles: @escaping Action,
                onOpenAnalysis: @escaping Action,
                presenter: HomePresenter = HomePresenter()) {
        self.onStartGame = onStartGame
        self.onGoToPlay = onGoToPlay
        self.onOpenPuzzles = onOpenPuzzles
        self.onOpenAnalysis = onOpenAnalysis
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

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(scroll)
        scroll.showsVerticalScrollIndicator = false
        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        scroll.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 0
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scroll)
        }

        stack.addArrangedSubview(buildHeader())
        stack.addArrangedSubview(buildHero())
        stack.addArrangedSubview(buildStats(summary: presenter.model.statsSummary))
        stack.addArrangedSubview(buildInsight(presenter.model.insight))
        let dayTitle = SectionLabel(text: "Задача дня")
        dayTitle.snp.makeConstraints { _ in }
        let dayWrapper = UIView()
        dayWrapper.addSubview(dayTitle)
        dayTitle.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 10, right: 18))
        }
        stack.addArrangedSubview(dayWrapper)
        stack.addArrangedSubview(buildPuzzleOfDay())
        stack.addArrangedSubview(buildRecentGames())
        stack.addArrangedSubview(UIView.spacer(height: 18))
    }

    private func buildHeader() -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.color(\.bg)

        let logo = UIView()
        logo.backgroundColor = Theme.color(\.accd)
        logo.layer.cornerRadius = 9
        logo.layer.borderColor = Theme.color(\.accbrd).cgColor
        logo.layer.borderWidth = 1
        logo.snp.makeConstraints { make in make.size.equalTo(36) }

        let logoGlyph = UILabel()
        logoGlyph.text = "♞"
        logoGlyph.font = .systemFont(ofSize: 22, weight: .regular)
        logoGlyph.textColor = Theme.color(\.acc)
        logoGlyph.textAlignment = .center
        logo.addSubview(logoGlyph)
        logoGlyph.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let name = UILabel()
        name.text = "PawnRise"
        name.font = .systemFont(ofSize: 17, weight: .semibold)
        name.textColor = Theme.color(\.tx1)

        let sub = UILabel()
        sub.text = "AI Chess Coach"
        sub.font = .systemFont(ofSize: 10, weight: .regular)
        sub.textColor = Theme.color(\.tx3)

        let titleStack = UIStackView(arrangedSubviews: [name, sub])
        titleStack.axis = .vertical
        titleStack.spacing = 1

        let elo = UILabel()
        elo.text = "\(presenter.model.elo)"
        elo.font = .monospacedSystemFont(ofSize: 20, weight: .medium)
        elo.textColor = Theme.color(\.acc)

        let eloLabel = UILabel()
        eloLabel.text = "РЕЙТИНГ"
        eloLabel.font = .systemFont(ofSize: 9, weight: .medium)
        eloLabel.textColor = Theme.color(\.tx3)

        let eloStack = UIStackView(arrangedSubviews: [elo, eloLabel])
        eloStack.axis = .vertical
        eloStack.alignment = .trailing
        eloStack.spacing = 2

        let leftStack = UIStackView(arrangedSubviews: [logo, titleStack])
        leftStack.axis = .horizontal
        leftStack.spacing = 10
        leftStack.alignment = .center

        let rowStack = UIStackView(arrangedSubviews: [leftStack, UIView(), eloStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center

        container.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 18, bottom: 14, right: 18))
        }

        let separator = UIView()
        separator.backgroundColor = Theme.color(\.brd)
        container.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        // Long-press on the logo toggles the theme — useful during design QA.
        let long = UILongPressGestureRecognizer(target: self, action: #selector(toggleTheme))
        logo.isUserInteractionEnabled = true
        logo.addGestureRecognizer(long)

        return container
    }

    @objc private func toggleTheme() { ThemeManager.shared.toggleLightDark() }

    private func buildHero() -> UIView {
        let wrapper = UIView()
        wrapper.snp.makeConstraints { _ in }

        let card = UIView()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 14
        card.layer.borderColor = Theme.color(\.brd).cgColor
        card.layer.borderWidth = 1

        let tag = UILabel()
        tag.attributedText = NSAttributedString(string: "— AI ТРЕНЕР", attributes: [
            .kern: 1.6,
            .foregroundColor: Theme.color(\.acc),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ])

        let title = UILabel()
        title.numberOfLines = 0
        let titleAttr = NSMutableAttributedString(string: "Грай. Вчись.\n", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: Theme.color(\.tx1)
        ])
        titleAttr.append(NSAttributedString(string: "Перемагай.", attributes: [
            .font: UIFont.italicSystemFont(ofSize: 22),
            .foregroundColor: Theme.color(\.acc)
        ]))
        title.attributedText = titleAttr

        let body = UILabel()
        body.numberOfLines = 0
        body.text = "Один ШІ грає проти тебе — інший аналізує кожен хід і дає підказки в реальному часі."
        body.font = .systemFont(ofSize: 13, weight: .light)
        body.textColor = Theme.color(\.tx3)

        let primary = PrimaryButton(title: "Грати зараз",
                                    icon: UIImage(systemName: "play.fill"))
        primary.addAction(UIAction { [weak self] _ in self?.onStartGame() }, for: .touchUpInside)

        let ghost = GhostButton(title: "Режими")
        ghost.addAction(UIAction { [weak self] _ in self?.onGoToPlay() }, for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [primary, ghost, UIView()])
        btnStack.axis = .horizontal
        btnStack.spacing = 9

        let inner = UIStackView(arrangedSubviews: [tag, title, body, btnStack])
        inner.axis = .vertical
        inner.spacing = 12
        inner.setCustomSpacing(18, after: body)
        card.addSubview(inner)
        inner.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18))
        }

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }
        return wrapper
    }

    private func buildStats(summary: HomeModel.StatsSummary) -> UIView {
        func cell(label: String, value: String, change: String, valueColor: UIColor, changeColor: UIColor) -> UIView {
            let cell = UIView()
            cell.backgroundColor = Theme.color(\.s1)
            cell.layer.cornerRadius = 10
            cell.layer.borderColor = Theme.color(\.brd).cgColor
            cell.layer.borderWidth = 1

            let lbl = UILabel()
            lbl.attributedText = NSAttributedString(string: label.uppercased(), attributes: [
                .kern: 1.2,
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: Theme.color(\.tx3)
            ])

            let val = UILabel()
            val.text = value
            val.font = .monospacedSystemFont(ofSize: 22, weight: .medium)
            val.textColor = valueColor

            let chg = UILabel()
            chg.text = change
            chg.font = .systemFont(ofSize: 10, weight: .regular)
            chg.textColor = changeColor

            let stack = UIStackView(arrangedSubviews: [lbl, val, chg])
            stack.axis = .vertical
            stack.spacing = 4
            cell.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 12, bottom: 13, right: 12))
            }
            return cell
        }

        let cells = [
            cell(label: "Задачі",   value: "\(summary.puzzles)",  change: "\(summary.puzzleAccuracy)% точн.",
                 valueColor: Theme.color(\.tx1), changeColor: Theme.color(\.tx3)),
            cell(label: "Перемоги", value: "\(summary.winRate)%", change: "↑ +\(summary.winDelta)%",
                 valueColor: Theme.color(\.win), changeColor: Theme.color(\.win)),
            cell(label: "Серія",    value: "\(summary.streakDays)", change: "днів",
                 valueColor: Theme.color(\.tx1), changeColor: Theme.color(\.tx3))
        ]

        let stack = UIStackView(arrangedSubviews: cells)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8

        let wrapper = UIView()
        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 14, right: 16))
        }
        return wrapper
    }

    private func buildInsight(_ insight: HomeModel.Insight) -> UIView {
        let wrapper = UIView()
        let card = UIView()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 12
        card.layer.borderColor = Theme.color(\.brd).cgColor
        card.layer.borderWidth = 1

        let accent = UIView()
        accent.backgroundColor = Theme.color(\.acc)
        card.addSubview(accent)
        accent.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(2)
        }

        let iconWrap = UIView()
        iconWrap.backgroundColor = Theme.color(\.accd)
        iconWrap.layer.cornerRadius = 7
        iconWrap.layer.borderWidth = 1
        iconWrap.layer.borderColor = Theme.color(\.accbrd).cgColor
        iconWrap.snp.makeConstraints { make in make.size.equalTo(30) }
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.tintColor = Theme.color(\.acc)
        icon.contentMode = .scaleAspectFit
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(14)
        }

        let title = UILabel()
        title.text = insight.title
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = Theme.color(\.tx1)

        let sub = UILabel()
        sub.text = "●  \(insight.subtitle)"
        sub.font = .systemFont(ofSize: 10, weight: .regular)
        sub.textColor = Theme.color(\.tx3)

        let header = UIStackView(arrangedSubviews: [iconWrap, {
            let s = UIStackView(arrangedSubviews: [title, sub])
            s.axis = .vertical
            s.spacing = 2
            return s
        }()])
        header.axis = .horizontal
        header.spacing = 10
        header.alignment = .top

        let body = UILabel()
        body.numberOfLines = 0
        body.attributedText = insight.attributedBody

        let stack = UIStackView(arrangedSubviews: [header, body])
        stack.axis = .vertical
        stack.spacing = 8

        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 15))
        }

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 14, right: 16))
        }
        return wrapper
    }

    private func buildPuzzleOfDay() -> UIView {
        let wrapper = UIView()
        let card = UIView()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 14
        card.layer.borderColor = Theme.color(\.brd).cgColor
        card.layer.borderWidth = 1
        card.layer.masksToBounds = true

        let header = UIView()
        let titleRow = UIStackView()
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = Theme.color(\.acc)
        star.contentMode = .scaleAspectFit
        star.snp.makeConstraints { make in make.size.equalTo(11) }
        let title = UILabel()
        title.attributedText = NSAttributedString(string: "МАТ У 2 ХОДИ", attributes: [
            .kern: 0.8,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: Theme.color(\.tx1)
        ])
        titleRow.addArrangedSubview(star)
        titleRow.addArrangedSubview(title)

        let rank = UILabel()
        rank.text = "1740"
        rank.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        rank.textColor = Theme.color(\.tx3)

        let topStack = UIStackView(arrangedSubviews: [titleRow, UIView(), rank])
        topStack.axis = .horizontal
        topStack.alignment = .center
        header.addSubview(topStack)
        topStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 9, right: 14))
        }

        let board = PreviewBoardView()
        board.snp.makeConstraints { make in make.height.equalTo(132) }

        let footer = UIView()
        let info = UILabel()
        info.text = "Сицилійська · Чорні ходять"
        info.font = .systemFont(ofSize: 11, weight: .light)
        info.textColor = Theme.color(\.tx3)

        let solve = UILabel()
        solve.attributedText = NSAttributedString(string: "ВИРІШИТИ  ▶", attributes: [
            .kern: 0.8,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: Theme.color(\.acc)
        ])

        let footStack = UIStackView(arrangedSubviews: [info, UIView(), solve])
        footStack.axis = .horizontal
        footStack.alignment = .center
        footer.addSubview(footStack)
        footStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }

        let border1 = UIView(); border1.backgroundColor = Theme.color(\.brd)
        let border2 = UIView(); border2.backgroundColor = Theme.color(\.brd)

        let stack = UIStackView(arrangedSubviews: [header, border1, board, border2, footer])
        stack.axis = .vertical
        border1.snp.makeConstraints { make in make.height.equalTo(1 / UIScreen.main.scale) }
        border2.snp.makeConstraints { make in make.height.equalTo(1 / UIScreen.main.scale) }
        card.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(openPuzzlesTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 14, right: 16))
        }
        return wrapper
    }

    @objc private func openPuzzlesTap() { onOpenPuzzles() }

    private func buildRecentGames() -> UIView {
        let wrapper = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 7

        let header = UIView()
        let title = UILabel()
        title.text = "Останні партії"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = Theme.color(\.tx1)

        let link = UIButton(type: .system)
        link.setTitle("Розбір →", for: .normal)
        link.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        link.tintColor = Theme.color(\.acc)
        link.addAction(UIAction { [weak self] _ in self?.onOpenAnalysis() }, for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [title, UIView(), link])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        header.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 10, right: 18))
        }
        stack.addArrangedSubview(header)

        for (idx, game) in presenter.model.recentGames.enumerated() {
            let row = UIView()
            row.backgroundColor = Theme.color(\.s1)
            row.layer.cornerRadius = 10
            row.layer.borderColor = Theme.color(\.brd).cgColor
            row.layer.borderWidth = 1

            let glyph = UILabel()
            glyph.text = idx.isMultiple(of: 2) ? "♞" : "♜"
            glyph.font = .systemFont(ofSize: 16)
            glyph.textColor = Theme.color(\.tx1)
            glyph.snp.makeConstraints { make in make.size.equalTo(32) }
            glyph.textAlignment = .center
            glyph.backgroundColor = Theme.color(\.s2)
            glyph.layer.cornerRadius = 5
            glyph.layer.masksToBounds = true

            let opponent = UILabel()
            opponent.text = game.opponent
            opponent.font = .systemFont(ofSize: 12.5, weight: .semibold)
            opponent.textColor = Theme.color(\.tx1)

            let meta = UILabel()
            meta.text = "\(game.kind) · \(game.opening)"
            meta.font = .systemFont(ofSize: 10.5, weight: .light)
            meta.textColor = Theme.color(\.tx3)

            let info = UIStackView(arrangedSubviews: [opponent, meta])
            info.axis = .vertical
            info.spacing = 2

            let badge = UILabel()
            let badgeText: String
            let badgeColor: UIColor
            let badgeBG: UIColor
            let border: UIColor
            switch game.result {
            case .win:  badgeText = "ПЕРЕМОГА"; badgeColor = Theme.color(\.win); badgeBG = Theme.color(\.wind); border = Theme.color(\.winbrd)
            case .loss: badgeText = "ПОРАЗКА";  badgeColor = Theme.color(\.red); badgeBG = Theme.color(\.redd); border = Theme.color(\.red).withAlphaComponent(0.2)
            case .draw: badgeText = "НІЧИЯ";    badgeColor = Theme.color(\.draw); badgeBG = Theme.color(\.drawd); border = Theme.color(\.draw).withAlphaComponent(0.2)
            }
            badge.attributedText = NSAttributedString(string: "  \(badgeText)  ", attributes: [
                .kern: 0.5,
                .font: UIFont.systemFont(ofSize: 9.5, weight: .semibold),
                .foregroundColor: badgeColor
            ])
            badge.backgroundColor = badgeBG
            badge.layer.cornerRadius = 5
            badge.layer.borderWidth = 1
            badge.layer.borderColor = border.cgColor
            badge.layer.masksToBounds = true
            badge.setContentHuggingPriority(.required, for: .horizontal)

            let delta = UILabel()
            delta.text = game.delta
            delta.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
            delta.textColor = game.result == .win ? Theme.color(\.win) : Theme.color(\.tx3)

            let rightStack = UIStackView(arrangedSubviews: [badge, delta])
            rightStack.axis = .vertical
            rightStack.alignment = .trailing
            rightStack.spacing = 2

            let rowStack = UIStackView(arrangedSubviews: [glyph, info, rightStack])
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.spacing = 12

            row.addSubview(rowStack)
            rowStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 14))
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(openAnalysisTap))
            row.isUserInteractionEnabled = true
            row.addGestureRecognizer(tap)

            let rowWrapper = UIView()
            rowWrapper.addSubview(row)
            row.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            }
            stack.addArrangedSubview(rowWrapper)
        }

        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0))
        }
        return wrapper
    }

    @objc private func openAnalysisTap() { onOpenAnalysis() }

    // MARK: - HomeViewInput

    public func render() { /* single-shot rendering in viewDidLoad */ }
}

public extension UIView {
    static func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.snp.makeConstraints { make in make.height.equalTo(height) }
        return v
    }
    static func spacer(width: CGFloat) -> UIView {
        let v = UIView()
        v.snp.makeConstraints { make in make.width.equalTo(width) }
        return v
    }
}
