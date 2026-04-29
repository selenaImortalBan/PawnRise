import UIKit
import SnapKit

public final class AnalysisViewController: UIViewController {

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
        stack.addArrangedSubview(buildBoard())
        stack.addArrangedSubview(buildEvalStrip())
        stack.addArrangedSubview(buildPanel())
        stack.addArrangedSubview(buildSuggest())
        stack.addArrangedSubview(UIView.spacer(height: 24))
    }

    private func buildHeader() -> UIView {
        let wrapper = UIView()
        let title = UILabel()
        title.text = "Розбір"
        title.font = .systemFont(ofSize: 26, weight: .semibold)
        title.textColor = Theme.color(\.tx1)
        let sub = UILabel()
        sub.text = "● ШІ-аналіз завершено"
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

    private func buildBoard() -> UIView {
        let wrapper = UIView()
        // Large preview board rendered the same way as the live board but frozen.
        let board = ChessBoardView()
        board.setBoard(Board.startingPosition.applying(exampleMove1).applying(exampleMove2), lastMove: exampleMove2)
        board.isUserInteractionEnabled = false

        wrapper.addSubview(board)
        board.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(board.snp.width)
        }
        return wrapper
    }

    private var exampleMove1: Move { Move(from: Square(file: 4, rank: 1), to: Square(file: 4, rank: 3)) }
    private var exampleMove2: Move { Move(from: Square(file: 2, rank: 6), to: Square(file: 2, rank: 4)) }

    private func buildEvalStrip() -> UIView {
        let wrapper = UIView()
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .center

        let tokens: [(String, String)] = [
            ("1.e4", "best"), ("c5", "normal"), ("2.Nf3", "best"), ("d6", "normal"),
            ("3.d4", "inac"), ("cxd4", "normal"), ("4.Bc4", "err"), ("Nf6", "normal"),
            ("5.Nc3", "best")
        ]
        for token in tokens { row.addArrangedSubview(makeEvalToken(text: token.0, kind: token.1)) }

        scroll.addSubview(row)
        row.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            make.height.equalTo(scroll)
        }
        wrapper.addSubview(scroll)
        scroll.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(28)
        }
        return wrapper
    }

    private func makeEvalToken(text: String, kind: String) -> UIView {
        let label = UILabel()
        let color: UIColor
        let bg: UIColor
        switch kind {
        case "best":
            color = Theme.color(\.win); bg = Theme.color(\.wind)
            label.text = "\(text) ✓"
        case "inac":
            color = Theme.color(\.warn); bg = Theme.color(\.warnd)
            label.text = "\(text) ?!"
        case "err":
            color = Theme.color(\.red); bg = Theme.color(\.redd)
            label.text = "\(text) ??"
        default:
            color = Theme.color(\.tx3); bg = Theme.color(\.s1)
            label.text = text
        }
        label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        label.textColor = color
        let box = UIView()
        box.backgroundColor = bg
        box.layer.cornerRadius = 4
        box.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6))
        }
        return box
    }

    private func buildPanel() -> UIView {
        let wrapper = UIView()
        let card = UIView()
        card.backgroundColor = Theme.color(\.s1)
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.color(\.brd).cgColor

        let title = UILabel()
        title.text = "Аналіз PawnRise AI"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = Theme.color(\.tx1)
        let sub = UILabel()
        sub.text = "Rapid 15+10 · Майстер (1924)"
        sub.font = .systemFont(ofSize: 10)
        sub.textColor = Theme.color(\.tx3)
        let header = UIStackView(arrangedSubviews: [title, sub])
        header.axis = .vertical
        header.spacing = 2

        func cell(label: String, value: String, color: UIColor) -> UIView {
            let lbl = UILabel()
            lbl.text = label.uppercased()
            lbl.font = .systemFont(ofSize: 9, weight: .semibold)
            lbl.textColor = Theme.color(\.tx3)
            let val = UILabel()
            val.text = value
            val.font = .monospacedSystemFont(ofSize: 20, weight: .medium)
            val.textColor = color
            let stack = UIStackView(arrangedSubviews: [lbl, val])
            stack.axis = .vertical
            stack.spacing = 2
            return stack
        }
        let grid = UIStackView(arrangedSubviews: [
            cell(label: "Точність",  value: "84%", color: Theme.color(\.win)),
            cell(label: "Блундерів", value: "1",   color: Theme.color(\.red)),
            cell(label: "Неточн.",   value: "3",   color: Theme.color(\.tx1))
        ])
        grid.axis = .horizontal
        grid.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [header, grid])
        stack.axis = .vertical
        stack.spacing = 12

        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }

        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }

    private func buildSuggest() -> UIView {
        let wrapper = UIView()
        let card = UIView()
        card.backgroundColor = Theme.color(\.accd)
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = Theme.color(\.accbrd).cgColor

        let title = UILabel()
        title.text = "ШІ пропонує задачі"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = Theme.color(\.tx1)
        let sub = UILabel()
        sub.numberOfLines = 0
        sub.text = "Блундер на ході 4. 3 задачі вже підготовлено."
        sub.font = .systemFont(ofSize: 11)
        sub.textColor = Theme.color(\.tx3)

        let button = PrimaryButton(title: "Вирішити задачі",
                                   icon: UIImage(systemName: "play.fill"))
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [title, sub, button])
        stack.axis = .vertical
        stack.spacing = 8
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }
        wrapper.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return wrapper
    }
}
