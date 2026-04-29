import Foundation

/// Minimalist negamax + αβ search. Runs on a background queue so the UI never
/// stalls. Difficulty controls `searchDepth` and the `noise` factor that lets
/// the bot purposely pick slightly worse moves at lower tiers to feel human.
public final class ChessBot {

    public let difficulty: Difficulty
    private let queue = DispatchQueue(label: "pawnrise.bot", qos: .userInitiated)

    public init(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    public func pickMove(for board: Board, completion: @escaping (Move?) -> Void) {
        let depth = difficulty.searchDepth
        let noise = difficulty.noise
        queue.async {
            let move = Self.search(board: board, depth: depth, noise: noise)
            DispatchQueue.main.async { completion(move) }
        }
    }

    public static func bestMove(for board: Board, depth: Int) -> Move? {
        search(board: board, depth: max(1, depth), noise: 0)
    }

    /// Score difference (in centipawns) for the side that just moved.
    public static func scoreDelta(beforeMove board: Board,
                                  move: Move,
                                  searchDepth: Int = 2) -> Int {
        let mover = board.sideToMove
        let bestBefore = -negamax(board, depth: searchDepth, alpha: -infinity, beta: infinity,
                                  colorSign: mover == .white ? 1 : -1)
        let afterBoard = board.applying(move)
        let playedScore = -negamax(afterBoard, depth: searchDepth - 1, alpha: -infinity, beta: infinity,
                                   colorSign: afterBoard.sideToMove == .white ? 1 : -1)
        // Relative to the side that moved — positive = good, negative = mistake.
        return playedScore - bestBefore
    }

    // MARK: - Search core

    private static let infinity = 1_000_000

    private static func search(board: Board, depth: Int, noise: Double) -> Move? {
        let moves = MoveGenerator.legalMoves(for: board)
        guard !moves.isEmpty else { return nil }
        let sign = board.sideToMove == .white ? 1 : -1

        var scored: [(Move, Int)] = []
        scored.reserveCapacity(moves.count)
        for move in moves {
            let child = board.applying(move)
            let score = -negamax(child, depth: depth - 1,
                                 alpha: -infinity, beta: infinity,
                                 colorSign: -sign)
            scored.append((move, score))
        }
        scored.sort { $0.1 > $1.1 }

        // "Noise" makes the bot pick one of the top-k moves to emulate weaker play.
        let topCount = max(1, Int(ceil(Double(scored.count) * noise)))
        let pool = Array(scored.prefix(max(1, topCount)))
        return pool.randomElement()?.0 ?? scored.first?.0
    }

    private static func negamax(_ board: Board,
                                depth: Int,
                                alpha a: Int, beta b: Int,
                                colorSign: Int) -> Int {
        if depth == 0 { return colorSign * Evaluator.evaluate(board) }

        let moves = MoveGenerator.legalMoves(for: board)
        if moves.isEmpty {
            if MoveGenerator.isInCheck(board.sideToMove, on: board) {
                return -infinity + (10 - depth)     // prefer faster mates
            }
            return 0 // stalemate
        }

        var alpha = a
        var best = -infinity
        for move in moves {
            let child = board.applying(move)
            let score = -negamax(child, depth: depth - 1,
                                 alpha: -b, beta: -alpha,
                                 colorSign: -colorSign)
            if score > best { best = score }
            if best > alpha { alpha = best }
            if alpha >= b { break }
        }
        return best
    }
}
