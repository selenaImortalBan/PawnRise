import UIKit
import SnapKit

public final class GameViewController: UIViewController, GamePresenterOutput {

    private let presenter: GamePresenter

    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let topBarTitle = UILabel()
    private let topBarSub = UILabel()
    private let liveBadge = UIView()
    private let botRow = PlayerRowView()
    private let userRow = PlayerRowView()
    private let board = ChessBoardView()
    private let subBar = UIView()
    private let evalBar = EvalBarView()
    private let moveStrip = MoveStripView()
    private let hintButton = ActionButton(system: "lightbulb")
    private let drawButton = ActionButton(system: "xmark")
    private let resignButton = ActionButton(system: "flag")
    private let chatView = ChatView()

    public init(mode: GameMode, difficulty: Difficulty, opening: Opening?) {
        self.presenter = GamePresenter(
            mode: mode,
            difficulty: difficulty,
            opening: opening
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.color(\.bg)
        presenter.output = self
        build()
        presenter.viewDidLoad()
        observeKeyboard()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Build

    private func build() {
        // Scroll + content stack → single column layout that matches the mockup.
        view.addSubview(scroll)
        scroll.showsVerticalScrollIndicator = false
        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        scroll.addSubview(content)
        content.axis = .vertical
        content.spacing = 0
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scroll)
        }

        content.addArrangedSubview(buildTopBar())
        content.addArrangedSubview(wrap(botRow))
        content.addArrangedSubview(buildBoardWrapper())
        content.addArrangedSubview(buildSubBar())
        content.addArrangedSubview(wrap(userRow))
        content.addArrangedSubview(buildChatSection())

        botRow.configure(PlayerRowView.Configuration(glyph: "♟", name: "PawnRise AI", elo: 1924))
        userRow.configure(PlayerRowView.Configuration(glyph: "♙", name: "Гравець", elo: 1847))
        botRow.setClock(seconds: 180, ticking: false)
        userRow.setClock(seconds: 180, ticking: true)

        board.delegate = self
        chatView.delegate = self
    }

    private func buildTopBar() -> UIView {
        let container = UIView()
        let back = UIButton(type: .system)
        back.backgroundColor = Theme.color(\.s1)
        back.tintColor = Theme.color(\.tx2)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.layer.cornerRadius = 7
        back.layer.borderWidth = 1
        back.layer.borderColor = Theme.color(\.brd).cgColor
        back.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        back.snp.makeConstraints { make in make.size.equalTo(28) }

        topBarTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        topBarTitle.textColor = Theme.color(\.tx1)
        topBarTitle.textAlignment = .center
        topBarSub.font = .systemFont(ofSize: 9)
        topBarSub.textColor = Theme.color(\.tx3)
        topBarSub.textAlignment = .center

        let centerStack = UIStackView(arrangedSubviews: [topBarTitle, topBarSub])
        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerStack.spacing = 1

        liveBadge.backgroundColor = Theme.color(\.wind)
        liveBadge.layer.cornerRadius = 10
        liveBadge.layer.borderWidth = 1
        liveBadge.layer.borderColor = Theme.color(\.winbrd).cgColor
        liveBadge.snp.makeConstraints { make in make.height.equalTo(20) }
        let dot = UIView()
        dot.backgroundColor = Theme.color(\.win)
        dot.layer.cornerRadius = 2
        dot.snp.makeConstraints { make in make.size.equalTo(4) }
        let badgeLabel = UILabel()
        badgeLabel.text = "Аналіз"
        badgeLabel.font = .systemFont(ofSize: 9, weight: .medium)
        badgeLabel.textColor = Theme.color(\.win)
        let badgeStack = UIStackView(arrangedSubviews: [dot, badgeLabel])
        badgeStack.axis = .horizontal
        badgeStack.spacing = 4
        badgeStack.alignment = .center
        liveBadge.addSubview(badgeStack)
        badgeStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7))
        }

        let row = UIStackView(arrangedSubviews: [back, centerStack, liveBadge])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        container.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 14, bottom: 7, right: 14))
        }
        let separator = UIView()
        separator.backgroundColor = Theme.color(\.brd)
        container.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return container
    }

    private func buildBoardWrapper() -> UIView {
        let wrapper = UIView()
        let frame = UIView()
        frame.layer.borderColor = Theme.color(\.brd2).cgColor
        frame.layer.borderWidth = 1
        frame.layer.cornerRadius = 6
        frame.clipsToBounds = true
        frame.addSubview(board)
        board.snp.makeConstraints { make in make.edges.equalToSuperview() }
        wrapper.addSubview(frame)
        frame.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(frame.snp.width)
        }
        return wrapper
    }

    private func buildSubBar() -> UIView {
        let container = UIView()
        evalBar.snp.makeConstraints { make in
            make.width.equalTo(4)
            make.height.greaterThanOrEqualTo(22)
        }
        let actionStack = UIStackView(arrangedSubviews: [hintButton, drawButton, resignButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 4
        hintButton.tintColor = Theme.color(\.win)
        resignButton.tintColor = Theme.color(\.red)

        hintButton.addAction(UIAction { [weak self] _ in self?.presenter.requestHint() }, for: .touchUpInside)
        drawButton.addAction(UIAction { [weak self] _ in self?.presenter.offerDraw() }, for: .touchUpInside)
        resignButton.addAction(UIAction { [weak self] _ in self?.presenter.resign() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [evalBar, moveStrip, actionStack])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        moveStrip.snp.makeConstraints { make in make.height.equalTo(22) }

        container.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }
        return container
    }

    private func buildChatSection() -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(chatView)
        chatView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(340)
        }
        return wrapper
    }

    private func wrap(_ view: UIView) -> UIView {
        let wrapper = UIView()
        wrapper.addSubview(view)
        view.snp.makeConstraints { make in make.edges.equalToSuperview() }
        return wrapper
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismissKeyboardOnTap),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc private func dismissKeyboardOnTap() { view.endEditing(true) }

    // MARK: - GamePresenterOutput

    public func presenterDidUpdate(state: GameState,
                                   metadata: GameMetadata,
                                   lastMove: Move?) {
        topBarTitle.text = metadata.headerTitle
        topBarSub.text = metadata.headerSubtitle
        board.setBoard(state.board, lastMove: lastMove, animated: true)
        moveStrip.render(moves: state.formattedMoves)
        evalBar.update(cp: metadata.evaluationCP)

        userRow.setClock(seconds: metadata.userClockSeconds, ticking: state.sideToMove == .white && !state.outcome.isFinished)
        botRow.setClock(seconds: metadata.botClockSeconds, ticking: state.sideToMove == .black && !state.outcome.isFinished)

        if state.outcome.isFinished {
            presentOutcome(state.outcome)
        }
    }

    public func presenterDidAppendMessage(_ message: ChatMessage) {
        chatView.append(message, animated: true)
    }

    public func presenterDidSetMessages(_ messages: [ChatMessage]) {
        chatView.set(messages: messages, animated: false)
    }

    public func presenterSetThinking(_ thinking: Bool) {
        chatView.setThinking(thinking)
    }

    public func presenterShouldAnnounceIllegalInput(for move: Move) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private var outcomeShown = false
    private func presentOutcome(_ outcome: GameOutcome) {
        guard !outcomeShown else { return }
        outcomeShown = true
        let alert = UIAlertController(title: outcome.localizedTitle,
                                      message: "Партію завершено.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Нова партія", style: .default) { [weak self] _ in
            self?.outcomeShown = false
            self?.presenter.resetGame()
        })
        alert.addAction(UIAlertAction(title: "Закрити", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

extension GameViewController: ChessBoardViewDelegate {
    public func boardView(_ view: ChessBoardView, legalMovesFrom square: Square) -> [Move] {
        presenter.legalMoves(from: square)
    }
    public func boardView(_ view: ChessBoardView, didSelect move: Move) {
        presenter.userMade(move)
    }
    public func boardViewShouldPromptForPromotion(_ view: ChessBoardView) -> Bool { true }
}

extension GameViewController: ChatViewDelegate {
    public func chatView(_ view: ChatView, didSend text: String) {
        presenter.userAsked(text)
    }
    public func chatView(_ view: ChatView, didTapChip text: String) {
        presenter.userAsked(text)
    }
    public func chatViewDidTapHint(_ view: ChatView) {
        presenter.requestHint()
    }
}

// MARK: - Action button

private final class ActionButton: UIButton {
    init(system: String) {
        super.init(frame: .zero)
        backgroundColor = Theme.color(\.s1)
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = Theme.color(\.brd).cgColor
        tintColor = Theme.color(\.tx3)
        setImage(UIImage(systemName: system, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)),
                 for: .normal)
        snp.makeConstraints { make in make.size.equalTo(26) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
