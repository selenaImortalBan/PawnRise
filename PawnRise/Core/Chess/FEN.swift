import Foundation

public enum FEN {

    public static func parse(_ fen: String) -> Board? {
        let parts = fen.split(separator: " ")
        guard parts.count >= 4 else { return nil }

        let placement = String(parts[0])
        let turn      = String(parts[1])
        let castling  = String(parts[2])
        let ep        = String(parts[3])
        let halfmove  = parts.count > 4 ? Int(parts[4]) ?? 0 : 0
        let fullmove  = parts.count > 5 ? Int(parts[5]) ?? 1 : 1

        var squares: [Piece?] = Array(repeating: nil, count: 64)
        let ranks = placement.split(separator: "/")
        guard ranks.count == 8 else { return nil }

        for (rowIndex, row) in ranks.enumerated() {
            let rank = 7 - rowIndex
            var file = 0
            for ch in row {
                if let n = Int(String(ch)) { file += n; continue }
                guard let piece = FEN.piece(from: ch) else { return nil }
                guard (0..<8).contains(file) else { return nil }
                squares[rank * 8 + file] = piece
                file += 1
            }
        }

        let side: PieceColor = turn == "w" ? .white : .black

        var rights: Board.CastlingRights = []
        if castling.contains("K") { rights.insert(.whiteKing) }
        if castling.contains("Q") { rights.insert(.whiteQueen) }
        if castling.contains("k") { rights.insert(.blackKing) }
        if castling.contains("q") { rights.insert(.blackQueen) }

        let epSquare: Square? = ep == "-" ? nil : Square.from(algebraic: ep)

        return Board(squares: squares,
                     sideToMove: side,
                     castlingRights: rights,
                     enPassantTarget: epSquare,
                     halfmoveClock: halfmove,
                     fullmoveNumber: fullmove)
    }

    public static func encode(_ board: Board) -> String {
        var rows: [String] = []
        for rowIndex in 0..<8 {
            let rank = 7 - rowIndex
            var row = ""
            var empty = 0
            for file in 0..<8 {
                let square = Square(file: file, rank: rank)
                if let piece = board[square] {
                    if empty > 0 { row += "\(empty)"; empty = 0 }
                    row.append(piece.fenChar)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { row += "\(empty)" }
            rows.append(row)
        }
        let placement = rows.joined(separator: "/")
        let side = board.sideToMove == .white ? "w" : "b"

        var rights = ""
        if board.castlingRights.contains(.whiteKing)  { rights += "K" }
        if board.castlingRights.contains(.whiteQueen) { rights += "Q" }
        if board.castlingRights.contains(.blackKing)  { rights += "k" }
        if board.castlingRights.contains(.blackQueen) { rights += "q" }
        if rights.isEmpty { rights = "-" }

        let ep = board.enPassantTarget?.algebraic ?? "-"
        return "\(placement) \(side) \(rights) \(ep) \(board.halfmoveClock) \(board.fullmoveNumber)"
    }

    private static func piece(from ch: Character) -> Piece? {
        let isWhite = ch.isUppercase
        let color: PieceColor = isWhite ? .white : .black
        switch Character(ch.lowercased()) {
        case "p": return Piece(color, .pawn)
        case "n": return Piece(color, .knight)
        case "b": return Piece(color, .bishop)
        case "r": return Piece(color, .rook)
        case "q": return Piece(color, .queen)
        case "k": return Piece(color, .king)
        default:  return nil
        }
    }
}
