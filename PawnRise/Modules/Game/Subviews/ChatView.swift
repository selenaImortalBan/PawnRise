import UIKit
import SnapKit

public protocol ChatViewDelegate: AnyObject {
    func chatView(_ view: ChatView, didSend text: String)
    func chatView(_ view: ChatView, didTapChip text: String)
    func chatViewDidTapHint(_ view: ChatView)
}

public final class ChatView: UIView {

    public weak var delegate: ChatViewDelegate?

    public private(set) var messages: [ChatMessage] = []
    public private(set) var isThinking: Bool = false

    private let divider = UIView()
    private let dividerLabel = UILabel()
    private let chips = UIStackView()
    private let scroll = UIScrollView()
    private let messageStack = UIStackView()
    private let inputRow = UIView()
    private let input = ExpandingTextView()
    private let sendButton = UIButton(type: .system)
    private let thinkingBubble = ThinkingBubble()

    private let chipSuggestions = [
        "Найкращий хід?", "Оціни позицію", "Слабкі місця", "План гри"
    ]

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        inputRow.layer.borderColor = Theme.color(\.brd).cgColor
    }

    // MARK: - Public API

    public func set(messages: [ChatMessage], animated: Bool) {
        self.messages = messages
        rebuild()
        scrollToBottom(animated: animated)
    }

    public func append(_ message: ChatMessage, animated: Bool) {
        messages.append(message)
        messageStack.addArrangedSubview(makeMessageView(message))
        scrollToBottom(animated: animated)
    }

    public func setThinking(_ thinking: Bool) {
        isThinking = thinking
        thinkingBubble.isHidden = !thinking
        if thinking { thinkingBubble.startAnimating() } else { thinkingBubble.stopAnimating() }
        scrollToBottom(animated: true)
    }

    public func focusInput() { input.becomeFirstResponder() }

    // MARK: - Build

    private func build() {
        divider.backgroundColor = Theme.color(\.brd)
        let dividerLine1 = UIView(); dividerLine1.backgroundColor = Theme.color(\.brd)
        let dividerLine2 = UIView(); dividerLine2.backgroundColor = Theme.color(\.brd)
        dividerLabel.attributedText = NSAttributedString(string: "ШІ АНАЛІЗАТОР", attributes: [
            .kern: 1.0,
            .font: UIFont.systemFont(ofSize: 8.5, weight: .semibold),
            .foregroundColor: Theme.color(\.tx4)
        ])
        dividerLabel.textAlignment = .center
        let dividerStack = UIStackView(arrangedSubviews: [dividerLine1, dividerLabel, dividerLine2])
        dividerStack.axis = .horizontal
        dividerStack.alignment = .center
        dividerStack.spacing = 8
        dividerLine1.snp.makeConstraints { make in make.height.equalTo(1 / UIScreen.main.scale) }
        dividerLine2.snp.makeConstraints { make in make.height.equalTo(1 / UIScreen.main.scale) }
        dividerLine1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dividerLine2.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(dividerStack)
        dividerStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(12)
        }

        // Chip row
        let chipScroll = UIScrollView()
        chipScroll.showsHorizontalScrollIndicator = false
        addSubview(chipScroll)
        chipScroll.snp.makeConstraints { make in
            make.top.equalTo(dividerStack.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
        }
        chips.axis = .horizontal
        chips.spacing = 5
        chips.alignment = .center
        chipScroll.addSubview(chips)
        chips.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
            make.height.equalTo(chipScroll)
        }
        for suggestion in chipSuggestions {
            chips.addArrangedSubview(makeChip(text: suggestion))
        }

        // Scrollable messages
        addSubview(scroll)
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.addSubview(messageStack)
        messageStack.axis = .vertical
        messageStack.spacing = 8
        messageStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 14, bottom: 6, right: 14))
            make.width.equalTo(scroll).offset(-28)
        }

        // Input row
        addSubview(inputRow)
        inputRow.backgroundColor = Theme.color(\.bg)
        inputRow.layer.borderColor = Theme.color(\.brd).cgColor
        inputRow.layer.borderWidth = 1 / UIScreen.main.scale
        inputRow.layer.maskedCorners = []

        input.placeholder = "Запитай тренера…"
        input.backgroundColor = Theme.color(\.s1)
        input.layer.cornerRadius = 18
        input.layer.borderWidth = 1
        input.layer.borderColor = Theme.color(\.brd2).cgColor
        input.textContainerInset = UIEdgeInsets(top: 8, left: 13, bottom: 8, right: 13)
        input.font = .systemFont(ofSize: 12.5)
        input.onSubmit = { [weak self] in self?.handleSend() }

        sendButton.backgroundColor = Theme.color(\.acc)
        sendButton.tintColor = .white
        sendButton.layer.cornerRadius = 16
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.addAction(UIAction { [weak self] _ in self?.handleSend() }, for: .touchUpInside)

        inputRow.addSubview(input)
        inputRow.addSubview(sendButton)
        input.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalTo(inputRow.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.trailing.equalTo(sendButton.snp.leading).offset(-7)
            make.height.greaterThanOrEqualTo(34)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(input)
            make.size.equalTo(32)
        }

        scroll.snp.makeConstraints { make in
            make.top.equalTo(chipScroll.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputRow.snp.top)
        }
        inputRow.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        messageStack.addArrangedSubview(thinkingBubble)
        thinkingBubble.isHidden = true
    }

    private func rebuild() {
        messageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for message in messages {
            messageStack.addArrangedSubview(makeMessageView(message))
        }
        messageStack.addArrangedSubview(thinkingBubble)
        thinkingBubble.isHidden = !isThinking
    }

    private func makeChip(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10.5, weight: .medium)
        label.textColor = Theme.color(\.acc)

        let chip = UIControl()
        chip.backgroundColor = Theme.color(\.accd)
        chip.layer.cornerRadius = 14
        chip.layer.borderWidth = 1
        chip.layer.borderColor = Theme.color(\.accbrd).cgColor
        chip.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        }
        chip.addAction(UIAction { [weak self] _ in
            self?.delegate?.chatView(self!, didTapChip: text)
        }, for: .touchUpInside)
        return chip
    }

    private func makeMessageView(_ message: ChatMessage) -> UIView {
        let container = UIView()
        let bubble = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributed(text: message.text, sender: message.sender, tone: message.tone)

        bubble.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10))
        }

        if message.sender == .coach {
            bubble.backgroundColor = Theme.color(\.s1)
            bubble.layer.borderColor = Theme.color(\.brd).cgColor
            bubble.layer.borderWidth = 1
            bubble.layer.cornerRadius = 10
            bubble.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]

            let avatar = UILabel()
            avatar.text = "♞"
            avatar.font = .systemFont(ofSize: 12)
            avatar.textAlignment = .center
            avatar.backgroundColor = Theme.color(\.accd)
            avatar.textColor = Theme.color(\.acc)
            avatar.layer.cornerRadius = 6
            avatar.layer.masksToBounds = true
            avatar.layer.borderWidth = 1
            avatar.layer.borderColor = Theme.color(\.accbrd).cgColor

            container.addSubview(avatar)
            container.addSubview(bubble)
            avatar.snp.makeConstraints { make in
                make.top.leading.equalToSuperview()
                make.size.equalTo(22)
            }
            bubble.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalTo(avatar.snp.trailing).offset(6)
                make.trailing.lessThanOrEqualToSuperview().offset(-40)
                make.bottom.equalToSuperview().offset(-2)
            }
        } else {
            bubble.backgroundColor = Theme.color(\.acc)
            bubble.layer.cornerRadius = 10
            bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            container.addSubview(bubble)
            bubble.snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().offset(40)
            }
        }

        // Time stamp (tiny helper row)
        if let prefix = message.movePrefix {
            let time = UILabel()
            time.text = prefix
            time.font = .systemFont(ofSize: 9, weight: .regular)
            time.textColor = Theme.color(\.tx4)
            container.addSubview(time)
            time.snp.makeConstraints { make in
                make.top.equalTo(bubble.snp.bottom).offset(2)
                make.bottom.equalToSuperview()
                if message.sender == .coach { make.leading.equalTo(bubble) }
                else                       { make.trailing.equalTo(bubble) }
            }
        }
        return container
    }

    private func attributed(text: String,
                            sender: ChatSender,
                            tone: CoachTone) -> NSAttributedString {
        let baseColor: UIColor = sender == .user ? .white : Theme.color(\.tx2)
        let body = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: baseColor
        ])
        // Bold **...** (Markdown-lite) sections.
        var searchRange = body.string.startIndex..<body.string.endIndex
        while let open = body.string.range(of: "**", range: searchRange),
              let close = body.string.range(of: "**", range: open.upperBound..<body.string.endIndex) {
            let nsStart = body.string.distance(from: body.string.startIndex, to: open.lowerBound)
            let nsEnd = body.string.distance(from: body.string.startIndex, to: close.upperBound)
            let boldRange = body.string.distance(from: open.upperBound, to: close.lowerBound)
            body.replaceCharacters(in: NSRange(location: nsEnd - 2, length: 2), with: "")
            body.replaceCharacters(in: NSRange(location: nsStart, length: 2), with: "")
            body.addAttributes([
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: sender == .user ? .white : Theme.color(\.tx1)
            ], range: NSRange(location: nsStart, length: boldRange))
            let newStart = body.string.index(body.string.startIndex, offsetBy: nsStart + boldRange)
            searchRange = newStart..<body.string.endIndex
        }
        return body
    }

    private func scrollToBottom(animated: Bool) {
        layoutIfNeeded()
        let bottom = max(0, scroll.contentSize.height - scroll.bounds.height)
        scroll.setContentOffset(CGPoint(x: 0, y: bottom), animated: animated)
    }

    private func handleSend() {
        let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input.text = ""
        input.invalidateIntrinsicContentSize()
        delegate?.chatView(self, didSend: text)
    }
}

private final class ThinkingBubble: UIView {

    private let dots: [UIView] = (0..<3).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let bubble = UIView()
        bubble.backgroundColor = Theme.color(\.s1)
        bubble.layer.borderColor = Theme.color(\.brd).cgColor
        bubble.layer.borderWidth = 1
        bubble.layer.cornerRadius = 10

        let avatar = UILabel()
        avatar.text = "♞"
        avatar.font = .systemFont(ofSize: 12)
        avatar.textAlignment = .center
        avatar.backgroundColor = Theme.color(\.accd)
        avatar.textColor = Theme.color(\.acc)
        avatar.layer.cornerRadius = 6
        avatar.layer.masksToBounds = true

        addSubview(avatar)
        addSubview(bubble)
        avatar.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(22)
        }
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(avatar.snp.trailing).offset(6)
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(48)
        }

        let dotsStack = UIStackView()
        dotsStack.axis = .horizontal
        dotsStack.spacing = 4
        bubble.addSubview(dotsStack)
        dotsStack.snp.makeConstraints { make in make.center.equalToSuperview() }
        for dot in dots {
            dot.backgroundColor = Theme.color(\.tx4)
            dot.layer.cornerRadius = 2
            dot.snp.makeConstraints { make in make.size.equalTo(4) }
            dotsStack.addArrangedSubview(dot)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func startAnimating() {
        for (i, dot) in dots.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.fromValue = 0
            animation.toValue = -4
            animation.duration = 0.45
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + 0.15 * Double(i)
            dot.layer.add(animation, forKey: "bounce")
        }
    }

    func stopAnimating() { dots.forEach { $0.layer.removeAllAnimations() } }
}

private final class ExpandingTextView: UITextView {

    var placeholder: String = "" { didSet { placeholderLabel.text = placeholder } }
    var onSubmit: (() -> Void)?

    private let placeholderLabel = UILabel()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        delegate = self
        placeholderLabel.textColor = Theme.color(\.tx4)
        placeholderLabel.font = .systemFont(ofSize: 12.5)
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.centerY.equalToSuperview()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged),
                                               name: UITextView.textDidChangeNotification,
                                               object: self)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func textChanged() {
        placeholderLabel.isHidden = !text.isEmpty
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: min(size.height, 70))
    }
}

extension ExpandingTextView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            onSubmit?()
            return false
        }
        return true
    }
}
