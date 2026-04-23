import UIKit
import SnapKit

/// Custom tab bar that mirrors the HTML mockup: equal-width pills with
/// top border separators, a small accent underline under the active icon.
/// Uses plain `UIViewController`s as tabs (no `UINavigationController` wrapper)
/// because each screen pushes its own modal for deeper flows.
final class RootTabBarController: UIViewController {

    struct Tab {
        let title: String
        let icon: UIImage
        let viewController: UIViewController
    }

    private(set) var tabs: [Tab] = []
    private var currentIndex: Int = 0

    private let container = UIView()
    private let bar = UIView()
    private var buttons: [TabButton] = []

    var selectedIndex: Int {
        get { currentIndex }
        set { selectTab(at: newValue) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.color(\.bg)
        buildLayout()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        bar.layer.borderColor = Theme.color(\.brd).resolvedColor(with: traitCollection).cgColor
    }

    func setTabs(_ viewControllers: [UIViewController]) {
        precondition(viewControllers.count == 4, "Expected 4 tabs matching the design")
        let specs: [(String, String)] = [
            ("Дім",    "house.fill"),
            ("Грати",  "play.fill"),
            ("Задачі", "puzzlepiece.extension.fill"),
            ("Розбір", "chart.line.uptrend.xyaxis")
        ]
        self.tabs = zip(specs, viewControllers).map { spec, vc in
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let image = UIImage(systemName: spec.1, withConfiguration: config) ?? UIImage()
            return Tab(title: spec.0, icon: image, viewController: vc)
        }
        buildButtons()
        selectTab(at: 0)
    }

    private func buildLayout() {
        view.addSubview(container)
        view.addSubview(bar)

        container.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bar.snp.top)
        }

        bar.backgroundColor = Theme.color(\.s1)
        bar.layer.borderWidth = 1
        bar.layer.borderColor = Theme.color(\.brd).cgColor
        bar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(72 + view.safeAreaInsets.bottom)
        }
    }

    private func buildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        bar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(72)
        }

        for (i, tab) in tabs.enumerated() {
            let button = TabButton(title: tab.title, image: tab.icon)
            button.onTap = { [weak self] in self?.selectTab(at: i) }
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
    }

    private func selectTab(at index: Int) {
        guard (0..<tabs.count).contains(index) else { return }
        let target = tabs[index].viewController

        // Remove the current child.
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        // Add the new child.
        addChild(target)
        container.addSubview(target.view)
        target.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        target.didMove(toParent: self)

        currentIndex = index
        for (i, b) in buttons.enumerated() {
            b.setSelected(i == index, animated: true)
        }
    }
}

private final class TabButton: UIControl {

    var onTap: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let underline = UIView()

    init(title: String, image: UIImage) {
        super.init(frame: .zero)
        titleLabel.text = title.uppercased()
        imageView.image = image
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        layer.borderColor = Theme.color(\.brd).resolvedColor(with: traitCollection).cgColor
    }

    private func build() {
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Theme.color(\.tx4)

        titleLabel.font = .systemFont(ofSize: 9, weight: .medium)
        titleLabel.textColor = Theme.color(\.tx4)
        titleLabel.textAlignment = .center

        underline.backgroundColor = Theme.color(\.acc)
        underline.layer.cornerRadius = 1
        underline.alpha = 0

        layer.borderWidth = 1
        layer.borderColor = Theme.color(\.brd).cgColor

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(underline)

        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(22)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        underline.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(-2)
            make.centerX.equalToSuperview()
            make.width.equalTo(18)
            make.height.equalTo(2)
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTap() { onTap?() }

    func setSelected(_ isOn: Bool, animated: Bool) {
        let duration = animated ? 0.18 : 0
        UIView.animate(withDuration: duration) {
            self.imageView.tintColor = isOn ? Theme.color(\.acc) : Theme.color(\.tx4)
            self.titleLabel.textColor = isOn ? Theme.color(\.acc) : Theme.color(\.tx4)
            self.underline.alpha = isOn ? 1 : 0
        }
    }
}
