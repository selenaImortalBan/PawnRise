import Foundation

/// Lightweight static evaluation in centipawns from White's point of view.
/// Enough to drive a short-depth search and to score move quality for the coach.
public enum Evaluator {

    // Piece-square tables. Values are positive for white; we mirror for black.
    private static let pawnPST: [Int] = [
         0,  0,  0,   0,   0,   0,  0,  0,
         5, 10, 10, -20, -20,  10, 10,  5,
         5, -5,-10,   0,   0, -10, -5,  5,
         0,  0,  0,  20,  20,   0,  0,  0,
         5,  5, 10,  25,  25,  10,  5,  5,
        10, 10, 20,  30,  30,  20, 10, 10,
        50, 50, 50,  50,  50,  50, 50, 50,
         0,  0,  0,   0,   0,   0,  0,  0
    ]
    private static let knightPST: [Int] = [
        -50,-40,-30,-30,-30,-30,-40,-50,
        -40,-20,  0,  5,  5,  0,-20,-40,
        -30,  5, 10, 15, 15, 10,  5,-30,
        -30,  0, 15, 20, 20, 15,  0,-30,
        -30,  5, 15, 20, 20, 15,  5,-30,
        -30,  0, 10, 15, 15, 10,  0,-30,
        -40,-20,  0,  0,  0,  0,-20,-40,
        -50,-40,-30,-30,-30,-30,-40,-50
    ]
    private static let bishopPST: [Int] = [
        -20,-10,-10,-10,-10,-10,-10,-20,
        -10,  5,  0,  0,  0,  0,  5,-10,
        -10, 10, 10, 10, 10, 10, 10,-10,
        -10,  0, 10, 10, 10, 10,  0,-10,
        -10,  5,  5, 10, 10,  5,  5,-10,
        -10,  0,  5, 10, 10,  5,  0,-10,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -20,-10,-10,-10,-10,-10,-10,-20
    ]
    private static let rookPST: [Int] = [
         0,  0,  5, 10, 10,  5,  0,  0,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
         5, 10, 10, 10, 10, 10, 10,  5,
         0,  0,  0,  0,  0,  0,  0,  0
    ]
    private static let queenPST: [Int] = [
        -20,-10,-10, -5, -5,-10,-10,-20,
        -10,  0,  5,  0,  0,  0,  0,-10,
        -10,  5,  5,  5,  5,  5,  0,-10,
          0,  0,  5,  5,  5,  5,  0, -5,
         -5,  0,  5,  5,  5,  5,  0, -5,
        -10,  0,  5,  5,  5,  5,  0,-10,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -20,-10,-10, -5, -5,-10,-10,-20
    ]
    private static let kingPST: [Int] = [
         20, 30, 10,  0,  0, 10, 30, 20,
         20, 20,  0,  0,  0,  0, 20, 20,
        -10,-20,-20,-20,-20,-20,-20,-10,
        -20,-30,-30,-40,-40,-30,-30,-20,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30
    ]

    public static func evaluate(_ board: Board) -> Int {
        var score = 0
        for i in 0..<64 {
            guard let piece = board.squares[i] else { continue }
            // For black pieces, mirror the PST index vertically.
            let pstIndex = piece.color == .white ? i : (56 - (i / 8) * 8 + i % 8)
            let pst = pst(for: piece.kind)[pstIndex]
            let delta = piece.kind.materialValue + pst
            score += piece.color == .white ? delta : -delta
        }
        return score
    }

    private static func pst(for kind: PieceKind) -> [Int] {
        switch kind {
        case .pawn:   return pawnPST
        case .knight: return knightPST
        case .bishop: return bishopPST
        case .rook:   return rookPST
        case .queen:  return queenPST
        case .king:   return kingPST
        }
    }
}
