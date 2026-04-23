import UIKit
import SnapKit

public final class PuzzlesViewController: UIViewController {

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.color(\.bg)
        build()
    }

    private func build() {
        view.addSubview(scroll)
        scroll.showsVerticalScrollIndicator = false
        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        scroll.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 14
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scroll)
        }

        stack.addArrangedSubview(buildHeader())
        stack.addArrangedSubview(buildStreak())
        stack.addArrangedSubview(buildCategories())
        stack.addArrangedSubview(buildRecommended())
        stack.addArrangedSubview(UIView.spacer(height: 24))
    }

    private func buildHeader() -> UIView {
        let wrapper = UIView()
        let title = UILabel()
        title.text = "Задачі"
        title.font = .systemFont(ofSize: 26, weight: .semibold)
        title.textColor = Theme.color(\.tx1)
        let sub = UILabel()
        sub.text = "Тактика · Дебюти · Ендшпіль"
        sub.font = .systemFont(ofSize: 12)
        sub.textColor = Theme.color(\.tx3)
        let stack = UIStackView(arrangedSubviews: [title, sub])
        stack.axis = .vertical
        stack.spacing = 3
        wrapper.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 18, bottom: 0, right: 18))
        }
        return wrapper
    }

    private func buildStreak() -> UIView {
        let wrapper = UIView()
        let card = UIView()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.color(\.brd).cgColor

        let flash = UILabel()
        flash.text = "⚡"
        flash.font = .systemFont(ofSize: 22)

        let header = UILabel()
        header.attributedText = NSAttributedString(string: "СЕРІЯ ДНІВ", attributes: [
            .kern: 1.4,
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: Theme.color(\.tx3)
        ])

        let bars = UIStackView()
        bars.axis = .horizontal
        bars.spacing = 4
        for i in 0..<7 {
            let bar = UIView()
            bar.backgroundColor = i < 6 ? Theme.color(\.acc) : Theme.color(\.brd2)
            bar.layer.cornerRadius = 1.5
            bar.snp.makeConstraints { make in
                make.width.equalTo(20)
                make.height.equalTo(3)
            }
            bars.addArrangedSubview(bar)
        }

        let leftStack = UIStackView(arrangedSubviews: [header, bars])
        leftStack.axis = .vertical
        leftStack.alignment = .leading
        leftStack.spacing = 7

        let number = UILabel()
        number.text = "7"
        number.font = .monospacedSystemFont(ofSize: 28, weight: .medium)
        number.textColor = Theme.color(\.acc)

        let days = UILabel()
        days.text = "днів"
        days.font = .systemFont(ofSize: 10, weight: .regular)
        days.textColor = Theme.color(\.tx3)

        let rightStack = UIStackView(arrangedSubviews: [number, days])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 1

        let row = UIStackView(arrangedSubviews: [flash, leftStack, UIView(), rightStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14

        card.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }

    private func buildCategories() -> UIView {
        let wrapper = UIView()
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8

        let categories: [(String, String, String, String)] = [
            ("star", "Звичайні",      "Тактика без прив'язки", "542"),
            ("text.alignleft", "За дебютом", "Пастки твоїх дебютів",  "186"),
            ("clock", "Задача дня",   "Щоденна від ШІ",         "★"),
            ("triangle", "Слабкі місця", "ШІ знайшов помилки",     "AI")
        ]
        var row: UIStackView!
        for (idx, cat) in categories.enumerated() {
            if idx % 2 == 0 {
                row = UIStackView(); row.axis = .horizontal; row.spacing = 8
                row.distribution = .fillEqually
                grid.addArrangedSubview(row)
            }
            row.addArrangedSubview(makeCategoryCell(iconName: cat.0, name: cat.1, desc: cat.2, badge: cat.3))
        }

        wrapper.addSubview(grid)
        grid.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }

    private func makeCategoryCell(iconName: String, name: String, desc: String, badge: String) -> UIView {
        let cell = UIControl()
        cell.backgroundColor = Theme.color(\.s1)
        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        cell.layer.borderColor = Theme.color(\.brd).cgColor

        let iconWrap = UIView()
        iconWrap.backgroundColor = Theme.color(\.accd)
        iconWrap.layer.cornerRadius = 8
        iconWrap.snp.makeConstraints { make in make.size.equalTo(32) }
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = Theme.color(\.acc)
        icon.contentMode = .scaleAspectFit
        iconWrap.addSubview(icon)
        icon.snp.makeConstraints { make in make.center.equalToSuperview(); make.size.equalTo(16) }

        let title = UILabel()
        title.text = name
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = Theme.color(\.tx1)

        let subtitle = UILabel()
        subtitle.text = desc
        subtitle.font = .systemFont(ofSize: 10, weight: .light)
        subtitle.textColor = Theme.color(\.tx3)
        subtitle.numberOfLines = 2

        let badgeLabel = UILabel()
        badgeLabel.text = badge
        badgeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        badgeLabel.textColor = Theme.color(\.acc)

        let stack = UIStackView(arrangedSubviews: [iconWrap, title, subtitle, badgeLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading

        cell.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }
        return cell
    }

    private func buildRecommended() -> UIView {
        let wrapper = UIView()
        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 7

        let header = UILabel()
        header.attributedText = NSAttributedString(string: "★  РЕКОМЕНДОВАНО", attributes: [
            .kern: 0.6,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: Theme.color(\.tx3)
        ])
        list.addArrangedSubview(header)

        let puzzles: [(String, String, Int, String)] = [
            ("Сицилійська пастка", "Мат в 2 · Дебют · Чорні", 1740, "Нова"),
            ("Жертва ферзя",        "Тактика · Middlegame",     2050, "Нова"),
            ("Каро-Канн: вилка",   "Задача за дебютом",        1620, "Дебют"),
            ("Ендшпіль тури",       "Техніка · Ендшпіль",       1520, "✓")
        ]
        for p in puzzles {
            list.addArrangedSubview(makePuzzleRow(name: p.0, meta: p.1, elo: p.2, status: p.3))
        }

        wrapper.addSubview(list)
        list.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }

    private func makePuzzleRow(name: String, meta: String, elo: Int, status: String) -> UIView {
        let row = UIView()
        row.backgroundColor = Theme.color(\.s1)
        row.layer.cornerRadius = 10
        row.layer.borderWidth = 1
        row.layer.borderColor = Theme.color(\.brd).cgColor

        let mini = UILabel()
        mini.text = "♞"
        mini.font = .systemFont(ofSize: 18)
        mini.textAlignment = .center
        mini.backgroundColor = Theme.color(\.s2)
        mini.textColor = Theme.color(\.tx2)
        mini.layer.cornerRadius = 5
        mini.layer.masksToBounds = true
        mini.snp.makeConstraints { make in make.size.equalTo(32) }

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 12.5, weight: .semibold)
        nameLabel.textColor = Theme.color(\.tx1)
        let metaLabel = UILabel()
        metaLabel.text = meta
        metaLabel.font = .systemFont(ofSize: 10.5, weight: .light)
        metaLabel.textColor = Theme.color(\.tx3)

        let info = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        info.axis = .vertical
        info.spacing = 2

        let eloLabel = UILabel()
        eloLabel.text = "\(elo)"
        eloLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        eloLabel.textColor = Theme.color(\.tx3)
        let statusLabel = UILabel()
        statusLabel.text = status
        statusLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        statusLabel.textColor = status == "✓" ? Theme.color(\.win) : Theme.color(\.acc)

        let rightStack = UIStackView(arrangedSubviews: [eloLabel, statusLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [mini, info, rightStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        row.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 14))
        }
        return row
    }
}
