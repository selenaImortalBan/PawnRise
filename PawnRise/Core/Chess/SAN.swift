import Foundation

/// Standard Algebraic Notation encoder (enough for display: `e4`, `Nf3`, `O-O`,
/// `exd5`, `Qxh7+`, `Nbd7`, etc.). Parsing is intentionally omitted — we only
/// consume SAN for rendering and for looking up opening-book moves by UCI.
public enum SAN {

    public static func encode(_ move: Move, on board: Board) -> String {
        if move.isCastleKingside  { return appendSuffix("O-O", move: move, on: board) }
        if move.isCastleQueenside { return appendSuffix("O-O-O", move: move, on: board) }

        guard let moving = board[move.from] else { return move.uci }
        let isCapture = board[move.to] != nil || move.isEnPassant

        var text = ""
        switch moving.kind {
        case .pawn:
            if isCapture {
                let fileChar = "abcdefgh"[String.Index(utf16Offset: move.from.file, in: "abcdefgh")]
                text += "\(fileChar)x"
            }
            text += move.to.algebraic
            if let promo = move.promotion {
                text += "=\(String(promo.fenLetter).uppercased())"
            }
        default:
            text += String(moving.kind.fenLetter).uppercased()
            text += disambiguator(for: move, moving: moving, on: board)
            if isCapture { text += "x" }
            text += move.to.algebraic
        }

        return appendSuffix(text, move: move, on: board)
    }

    private static func disambiguator(for move: Move,
                                      moving: Piece,
                                      on board: Board) -> String {
        // Find other same-kind same-color pieces whose legal moves also land on `move.to`.
        var candidates: [Square] = []
        for i in 0..<64 {
            guard let piece = board.squares[i],
                  piece.color == moving.color,
                  piece.kind == moving.kind else { continue }
            let sq = Square(unchecked: i)
            if sq == move.from { continue }
            let moves = MoveGenerator.legalMoves(from: sq, on: board)
            if moves.contains(where: { $0.to == move.to }) {
                candidates.append(sq)
            }
        }
        guard !candidates.isEmpty else { return "" }

        let sameFile = candidates.contains { $0.file == move.from.file }
        let sameRank = candidates.contains { $0.rank == move.from.rank }
        if !sameFile { return String("abcdefgh"[String.Index(utf16Offset: move.from.file, in: "abcdefgh")]) }
        if !sameRank { return "\(move.from.rank + 1)" }
        return move.from.algebraic
    }

    private static func appendSuffix(_ text: String, move: Move, on board: Board) -> String {
        let next = board.applying(move)
        let opponent = board.sideToMove.opposite
        let isCheck = MoveGenerator.isInCheck(opponent, on: next)
        guard isCheck else { return text }
        let oppLegal = MoveGenerator.legalMoves(for: next)
        return oppLegal.isEmpty ? "\(text)#" : "\(text)+"
    }
}
