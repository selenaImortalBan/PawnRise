import Foundation

/// Generates chat messages from the coach based on the current game state,
/// selected mode and the most recent move. No external service required —
/// everything is a deterministic heuristic grounded in the local engine.
public final class CoachEngine {

    public struct Context {
        public let mode: GameMode
        public let difficulty: Difficulty
        public let opening: Opening?

        public init(mode: GameMode, difficulty: Difficulty, opening: Opening?) {
            self.mode = mode
            self.difficulty = difficulty
            self.opening = opening
        }
    }

    private let context: Context
    private var userBookPly = 0     // number of plies user has matched the book
    private var botBookPly  = 0

    public init(context: Context) {
        self.context = context
    }

    // MARK: - Public API

    /// Initial greeting shown right after the game starts.
    public func greeting() -> [ChatMessage] {
        switch context.mode {
        case .rated:
            return [
                ChatMessage(sender: .coach,
                            text: "Партію розпочато. Слідкую за кожним ходом — будуть підказки та розбір помилок.",
                            tone: .info),
                ChatMessage(sender: .coach,
                            text: "Запитай «Найкращий хід?», «Оціни позицію» або «План гри» — відповім на основі аналізу.",
                            tone: .hint)
            ]
        case .free:
            return [
                ChatMessage(sender: .coach,
                            text: "Вільна гра. Жодного тиску, тренуйся спокійно — підказки завжди зі мною.",
                            tone: .info)
            ]
        case .opening:
            guard let opening = context.opening else {
                return [ChatMessage(sender: .coach,
                                    text: "Почнімо тренування дебютів. Я звірятиму твої ходи з теорією.",
                                    tone: .info)]
            }
            var messages: [ChatMessage] = [
                ChatMessage(sender: .coach,
                            text: "\(opening.displayName) · \(opening.eco). \(opening.summary)",
                            tone: .info),
                ChatMessage(sender: .coach,
                            text: "Грай головну лінію — я підкажу, якщо зійдеш з теорії.",
                            tone: .hint)
            ]
            if let firstIdea = opening.ideas.first {
                messages.append(ChatMessage(sender: .coach, text: firstIdea, tone: .hint))
            }
            return messages
        }
    }

    /// Runs after every move. Returns any coach messages that should pop up.
    public func reactions(after move: Move,
                          san: String,
                          boardBefore: Board,
                          boardAfter: Board,
                          movedBy color: PieceColor) -> [ChatMessage] {
        var messages: [ChatMessage] = []
        let prefix = "Хід \(boardBefore.fullmoveNumber)"
        let isUser = color == .white        // White = player in this MVP

        // Opening-line check.
        if context.mode == .opening, let opening = context.opening {
            messages.append(contentsOf: openingReaction(
                move: move, san: san,
                boardBefore: boardBefore, boardAfter: boardAfter,
                opening: opening, movedBy: color, prefix: prefix
            ))
        }

        // Move-quality verdict — only for the human.
        if isUser {
            messages.append(contentsOf: moveQuality(move: move, san: san,
                                                    boardBefore: boardBefore, prefix: prefix))
        }

        // Check indicator (brief, single line).
        if MoveGenerator.isInCheck(boardAfter.sideToMove, on: boardAfter) {
            messages.append(ChatMessage(sender: .coach,
                                        text: "Шах! Король у небезпеці — знаходь захист уважно.",
                                        tone: .warning, movePrefix: prefix))
        }
        return messages
    }

    /// Handles free-form questions from the user's chat input.
    public func reply(to userText: String, board: Board) -> ChatMessage {
        let query = userText.lowercased()
        if query.contains("оці") || query.contains("eval") || query.contains("позиц") {
            let cp = Evaluator.evaluate(board)
            let side = cp > 0 ? "білих" : (cp < 0 ? "чорних" : "рівна")
            let advantage = cp == 0 ? "Позиція рівна." :
                "Перевага на боці \(side): \(formatCP(cp))."
            return ChatMessage(sender: .coach, text: advantage, tone: .info)
        }
        if query.contains("найкра") || query.contains("best") {
            if let best = ChessBot.bestMove(for: board, depth: 3) {
                let san = SAN.encode(best, on: board)
                return ChatMessage(sender: .coach,
                                   text: "Зараз найкраще \(san) — дає найкращу оцінку за моїми розрахунками.",
                                   tone: .hint)
            }
            return ChatMessage(sender: .coach, text: "Немає легальних ходів.", tone: .warning)
        }
        if query.contains("слаб") || query.contains("weak") {
            let enemy = board.sideToMove.opposite
            var targets: [String] = []
            for i in 0..<64 {
                guard let p = board.squares[i], p.color == enemy else { continue }
                let sq = Square(unchecked: i)
                if MoveGenerator.isSquareAttacked(sq, by: board.sideToMove, on: board) {
                    targets.append("\(p.glyph)\(sq.algebraic)")
                }
                if targets.count >= 4 { break }
            }
            let listed = targets.isEmpty ? "немає явних мішеней" : targets.joined(separator: ", ")
            return ChatMessage(sender: .coach,
                               text: "Атаковані фігури суперника: \(listed).",
                               tone: .info)
        }
        if query.contains("план") || query.contains("plan") {
            if let opening = context.opening {
                let idea = opening.ideas.randomElement() ?? opening.ideas[0]
                return ChatMessage(sender: .coach,
                                   text: "У цьому дебюті: \(idea)",
                                   tone: .hint)
            }
            return ChatMessage(sender: .coach,
                               text: "Розвивай легкі фігури, контролюй центр, рокіруй — і готуй активний план.",
                               tone: .hint)
        }
        return ChatMessage(sender: .coach,
                           text: "Хороше питання. Спробуй «Найкращий хід?», «Оціни позицію», «План гри».",
                           tone: .info)
    }

    // MARK: - Opening reaction

    private func openingReaction(move: Move,
                                 san: String,
                                 boardBefore: Board,
                                 boardAfter: Board,
                                 opening: Opening,
                                 movedBy color: PieceColor,
                                 prefix: String) -> [ChatMessage] {
        let expectedIndex: Int = color == .white ? userBookPly : botBookPly
        guard expectedIndex < opening.mainLine.count else { return [] }
        let expected = opening.mainLine[expectedIndex]

        if move.uci == expected {
            if color == .white { userBookPly = expectedIndex + 1 }
            else               { botBookPly  = expectedIndex + 1 }
            let remaining = opening.mainLine.count - (expectedIndex + 1)
            if color == .white {
                let text: String
                if remaining == 0 {
                    text = "Ти пройшов головну лінію повністю — далі гра власним планом."
                } else {
                    text = "У головній лінії. Залишилось \(remaining) ходів теорії — продовжуй у тому ж дусі."
                }
                return [ChatMessage(sender: .coach, text: text,
                                    tone: .praise, movePrefix: prefix)]
            }
            return []
        }

        guard color == .white else { return [] } // ignore bot deviations
        let expectedSAN = expectedMoveSAN(from: boardBefore, uci: expected) ?? expected
        return [
            ChatMessage(sender: .coach,
                        text: "Це вихід з теорії. У **\(opening.displayName)** головна лінія — \(expectedSAN).",
                        tone: .warning, movePrefix: prefix),
            ChatMessage(sender: .coach,
                        text: "Причина: \(opening.ideas.first ?? "теорія бореться саме за ключові центральні поля"). Поговоримо про це — постав питання в чаті.",
                        tone: .hint, movePrefix: prefix)
        ]
    }

    // MARK: - Move quality

    private func moveQuality(move: Move,
                             san: String,
                             boardBefore: Board,
                             prefix: String) -> [ChatMessage] {
        // Raw delta vs. best engine move (from the mover's perspective).
        let delta = ChessBot.scoreDelta(beforeMove: boardBefore, move: move, searchDepth: 2)
        switch delta {
        case ..<(-300):
            return [ChatMessage(sender: .coach,
                                text: "Блундер! Хід \(san) сильно псує позицію (\(formatCP(delta))). Перевір тактичні мотиви.",
                                tone: .warning, movePrefix: prefix)]
        case -300 ..< -120:
            return [ChatMessage(sender: .coach,
                                text: "Помилка: \(san) веде до \(formatCP(delta)). Був кращий план — можемо розібрати.",
                                tone: .warning, movePrefix: prefix)]
        case -120 ..< -40:
            return [ChatMessage(sender: .coach,
                                text: "Неточність \(san). Нічого страшного, але знайдеться сильніший хід. Попроси «Найкращий хід?».",
                                tone: .hint, movePrefix: prefix)]
        case 80...:
            return [ChatMessage(sender: .coach,
                                text: "Хороший хід — \(san). Позиція покращилась на \(formatCP(delta)).",
                                tone: .praise, movePrefix: prefix)]
        default:
            return []
        }
    }

    private func expectedMoveSAN(from board: Board, uci: String) -> String? {
        guard uci.count >= 4 else { return nil }
        let fromStr = String(uci.prefix(2))
        let toStr   = String(uci.dropFirst(2).prefix(2))
        guard let from = Square.from(algebraic: fromStr),
              let to   = Square.from(algebraic: toStr) else { return nil }
        let promo: PieceKind? = uci.count == 5 ? {
            switch uci.last {
            case "q": return .queen
            case "r": return .rook
            case "b": return .bishop
            case "n": return .knight
            default:  return nil
            }
        }() : nil
        let candidate = MoveGenerator.legalMoves(for: board).first {
            $0.from == from && $0.to == to && $0.promotion == promo
        }
        return candidate.map { SAN.encode($0, on: board) }
    }

    private func formatCP(_ cp: Int) -> String {
        let pawns = Double(cp) / 100.0
        let sign = cp >= 0 ? "+" : "−"
        return "\(sign)\(String(format: "%.1f", abs(pawns)))"
    }
}
