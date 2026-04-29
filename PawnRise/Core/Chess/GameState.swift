import Foundation

public enum GameOutcome: Equatable {
    case inProgress
    case checkmate(winner: PieceColor)
    case stalemate
    case drawFiftyMove
    case drawThreefold
    case drawInsufficientMaterial
    case resignation(winner: PieceColor)
    case drawAgreement
    case timeout(winner: PieceColor)

    public var isFinished: Bool {
        if case .inProgress = self { return false }
        return true
    }

    public var localizedTitle: String {
        switch self {
        case .inProgress:                return "У грі"
        case .checkmate(let w):          return w == .white ? "Мат — білі перемогли" : "Мат — чорні перемогли"
        case .stalemate:                 return "Пат — нічия"
        case .drawFiftyMove:             return "Нічия за правилом 50 ходів"
        case .drawThreefold:             return "Нічия за трикратним повторенням"
        case .drawInsufficientMaterial:  return "Нічия — недостатньо матеріалу"
        case .resignation(let w):        return w == .white ? "Чорні здалися" : "Білі здалися"
        case .drawAgreement:             return "Нічия за згодою"
        case .timeout(let w):            return w == .white ? "Час чорних вийшов" : "Час білих вийшов"
        }
    }
}

public struct HistoryEntry: Hashable {
    public let move: Move
    public let boardBefore: Board
    public let san: String
}

public final class GameState {

    public private(set) var board: Board
    public private(set) var history: [HistoryEntry] = []
    public private(set) var outcome: GameOutcome = .inProgress

    public init(board: Board = .startingPosition) {
        self.board = board
        recalcOutcome()
    }

    public var sideToMove: PieceColor { board.sideToMove }

    public var legalMoves: [Move] {
        outcome.isFinished ? [] : MoveGenerator.legalMoves(for: board)
    }

    @discardableResult
    public func make(_ move: Move) -> Bool {
        guard !outcome.isFinished else { return false }
        let legal = MoveGenerator.legalMoves(for: board)
        guard legal.contains(move) else { return false }
        let san = SAN.encode(move, on: board)
        let before = board
        board = board.applying(move)
        history.append(HistoryEntry(move: move, boardBefore: before, san: san))
        recalcOutcome()
        return true
    }

    public func resign(_ color: PieceColor) {
        outcome = .resignation(winner: color.opposite)
    }

    public func agreeDraw() { outcome = .drawAgreement }

    /// Pairs of SAN strings grouped by move number for the move strip UI.
    public var formattedMoves: [(number: Int, white: String, black: String?)] {
        var rows: [(Int, String, String?)] = []
        for (i, entry) in history.enumerated() {
            if i % 2 == 0 {
                rows.append((i / 2 + 1, entry.san, nil))
            } else {
                let last = rows.removeLast()
                rows.append((last.0, last.1, entry.san))
            }
        }
        return rows
    }

    private func recalcOutcome() {
        if board.halfmoveClock >= 100 {
            outcome = .drawFiftyMove; return
        }
        if isInsufficientMaterial(board) {
            outcome = .drawInsufficientMaterial; return
        }
        let legal = MoveGenerator.legalMoves(for: board)
        if legal.isEmpty {
            if MoveGenerator.isInCheck(board.sideToMove, on: board) {
                outcome = .checkmate(winner: board.sideToMove.opposite)
            } else {
                outcome = .stalemate
            }
            return
        }
        // Threefold: compare positions ignoring clocks.
        let repetition = history.reduce(into: [String: Int]()) { acc, entry in
            acc[positionKey(entry.boardBefore), default: 0] += 1
        }
        let currentKey = positionKey(board)
        if (repetition[currentKey] ?? 0) + 1 >= 3 {
            outcome = .drawThreefold; return
        }
        outcome = .inProgress
    }

    private func positionKey(_ b: Board) -> String {
        FEN.encode(b).split(separator: " ").prefix(4).joined(separator: " ")
    }

    private func isInsufficientMaterial(_ b: Board) -> Bool {
        var pieces: [Piece] = []
        for square in b.squares where square != nil { pieces.append(square!) }
        pieces.removeAll { $0.kind == .king }
        if pieces.isEmpty { return true }
        if pieces.count == 1, pieces[0].kind == .bishop || pieces[0].kind == .knight { return true }
        if pieces.count == 2, pieces.allSatisfy({ $0.kind == .bishop }),
           pieces[0].color != pieces[1].color { return true }
        return false
    }
}
