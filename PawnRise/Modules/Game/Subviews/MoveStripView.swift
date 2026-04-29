import UIKit
import SnapKit

public final class MoveStripView: UIView {

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func render(moves: [(number: Int, white: String, black: String?)]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let lastIndex = moves.count - 1
        for (idx, entry) in moves.enumerated() {
            let isLast = idx == lastIndex
            stack.addArrangedSubview(makeToken("\(entry.number).", isNumber: true, isLast: false))
            stack.addArrangedSubview(makeToken(entry.white, isNumber: false, isLast: isLast && entry.black == nil))
            if let black = entry.black {
                stack.addArrangedSubview(makeToken(black, isNumber: false, isLast: isLast))
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let end = CGPoint(x: max(0, self.scroll.contentSize.width - self.scroll.bounds.width), y: 0)
            self.scroll.setContentOffset(end, animated: true)
        }
    }

    private func build() {
        addSubview(scroll)
        scroll.showsHorizontalScrollIndicator = false
        scroll.snp.makeConstraints { make in make.edges.equalToSuperview() }

        scroll.addSubview(stack)
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scroll)
        }
    }

    private func makeToken(_ text: String, isNumber: Bool, isLast: Bool) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .monospacedSystemFont(ofSize: 9, weight: isLast ? .medium : .regular)

        if isNumber {
            label.textColor = Theme.color(\.tx4)
            return wrapper(label, background: .clear, border: nil)
        }
        if isLast {
            label.textColor = Theme.color(\.acc)
            return wrapper(label, background: Theme.color(\.s1), border: Theme.color(\.accbrd))
        }
        label.textColor = Theme.color(\.tx3)
        return wrapper(label, background: Theme.color(\.s1), border: Theme.color(\.brd))
    }

    private func wrapper(_ label: UILabel, background: UIColor, border: UIColor?) -> UIView {
        let box = UIView()
        box.backgroundColor = background
        box.layer.cornerRadius = 3
        if let border {
            box.layer.borderColor = border.cgColor
            box.layer.borderWidth = 1
        }
        box.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5))
        }
        return box
    }
}
