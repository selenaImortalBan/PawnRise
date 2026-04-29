import Foundation

public struct GameMetadata {
    public let headerTitle: String
    public let headerSubtitle: String
    public let evaluationCP: Int
    public let userClockSeconds: Int
    public let botClockSeconds: Int
}

public protocol GamePresenterOutput: AnyObject {
    func presenterDidUpdate(state: GameState, metadata: GameMetadata, lastMove: Move?)
    func presenterDidAppendMessage(_ message: ChatMessage)
    func presenterDidSetMessages(_ messages: [ChatMessage])
    func presenterSetThinking(_ thinking: Bool)
    func presenterShouldAnnounceIllegalInput(for move: Move)
}

public final class GamePresenter {

    public weak var output: GamePresenterOutput?

    private let mode: GameMode
    private let difficulty: Difficulty
    private let opening: Opening?

    private var state: GameState
    private let bot: ChessBot
    private let coach: CoachEngine

    private var userSeconds: Int = 180
    private var botSeconds: Int = 180
    private var clockTimer: Timer?

    public init(mode: GameMode, difficulty: Difficulty, opening: Opening?) {
        self.mode = mode
        self.difficulty = difficulty
        self.opening = opening
        self.bot = ChessBot(difficulty: difficulty)
        self.coach = CoachEngine(context: .init(mode: mode, difficulty: difficulty, opening: opening))

        if let opening, mode == .opening {
            var board = Board.startingPosition
            for uci in opening.mainLine.prefix(2) {
                if let move = GamePresenter.uciToMove(uci, on: board) {
                    board = board.applying(move)
                }
            }
            self.state = GameState(board: Board.startingPosition)
        } else {
            self.state = GameState()
        }
    }

    // MARK: - Lifecycle

    public func viewDidLoad() {
        output?.presenterDidSetMessages(coach.greeting())
        emitState(lastMove: nil)
        startClock()
    }

    public func resetGame() {
        state = GameState()
        output?.presenterDidSetMessages(coach.greeting())
        emitState(lastMove: nil)
        userSeconds = 180
        botSeconds = 180
        startClock()
    }

    // MARK: - Interaction

    public func legalMoves(from square: Square) -> [Move] {
        guard state.sideToMove == .white else { return [] }
        return MoveGenerator.legalMoves(from: square, on: state.board)
    }

    public func userMade(_ move: Move) {
        let boardBefore = state.board
        guard state.make(move) else {
            output?.presenterShouldAnnounceIllegalInput(for: move)
            return
        }
        let lastEntry = state.history.last!
        let coachMessages = coach.reactions(after: move,
                                            san: lastEntry.san,
                                            boardBefore: boardBefore,
                                            boardAfter: state.board,
                                            movedBy: .white)
        emitState(lastMove: move)
        coachMessages.forEach { output?.presenterDidAppendMessage($0) }

        if !state.outcome.isFinished {
            scheduleBotMove()
        }
    }

    public func userAsked(_ text: String) {
        let userMessage = ChatMessage(sender: .user, text: text)
        output?.presenterDidAppendMessage(userMessage)
        output?.presenterSetThinking(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            let reply = self.coach.reply(to: text, board: self.state.board)
            self.output?.presenterSetThinking(false)
            self.output?.presenterDidAppendMessage(reply)
        }
    }

    public func requestHint() {
        output?.presenterSetThinking(true)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let board = self.state.board
            let best = ChessBot.bestMove(for: board, depth: 3)
            DispatchQueue.main.async {
                self.output?.presenterSetThinking(false)
                if let best {
                    let san = SAN.encode(best, on: board)
                    self.output?.presenterDidAppendMessage(
                        ChatMessage(sender: .coach,
                                    text: "Підказка: \(san). Це найсильніше за моїми розрахунками.",
                                    tone: .hint)
                    )
                }
            }
        }
    }

    public func offerDraw() {
        state.agreeDraw()
        emitState(lastMove: nil)
    }

    public func resign() {
        state.resign(.white)
        emitState(lastMove: nil)
    }

    // MARK: - Bot

    private func scheduleBotMove() {
        output?.presenterSetThinking(true)
        let delay: TimeInterval = 0.6
        bot.pickMove(for: state.board) { [weak self] move in
            guard let self, let move else {
                self?.output?.presenterSetThinking(false)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.output?.presenterSetThinking(false)
                let boardBefore = self.state.board
                if self.state.make(move) {
                    let entry = self.state.history.last!
                    let messages = self.coach.reactions(after: move,
                                                        san: entry.san,
                                                        boardBefore: boardBefore,
                                                        boardAfter: self.state.board,
                                                        movedBy: .black)
                    self.emitState(lastMove: move)
                    messages.forEach { self.output?.presenterDidAppendMessage($0) }
                }
            }
        }
    }

    // MARK: - Clock

    private func startClock() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, !self.state.outcome.isFinished else { return }
            if self.state.sideToMove == .white { self.userSeconds = max(0, self.userSeconds - 1) }
            else                               { self.botSeconds  = max(0, self.botSeconds - 1) }
            self.emitState(lastMove: self.state.history.last?.move)
        }
    }

    // MARK: - Emit

    private func emitState(lastMove: Move?) {
        let eval = Evaluator.evaluate(state.board)
        let openingName = opening?.displayName ?? "Звичайна партія"
        let metadata = GameMetadata(
            headerTitle: "\(mode.title) · \(difficulty.title)",
            headerSubtitle: "\(openingName) · Хід \(state.board.fullmoveNumber)",
            evaluationCP: eval,
            userClockSeconds: userSeconds,
            botClockSeconds: botSeconds
        )
        output?.presenterDidUpdate(state: state, metadata: metadata, lastMove: lastMove)
    }

    // MARK: - Helpers

    private static func uciToMove(_ uci: String, on board: Board) -> Move? {
        guard uci.count >= 4 else { return nil }
        let fromStr = String(uci.prefix(2))
        let toStr   = String(uci.dropFirst(2).prefix(2))
        guard let from = Square.from(algebraic: fromStr),
              let to = Square.from(algebraic: toStr) else { return nil }
        return MoveGenerator.legalMoves(for: board).first { $0.from == from && $0.to == to }
    }
}
