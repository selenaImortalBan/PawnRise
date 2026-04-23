import Foundation

/// Immutable-ish chess position. Moves produce a **new** `Board`; the old one is
/// kept in history to drive take-back / analysis.
public struct Board: Codable, Hashable {

    public struct CastlingRights: OptionSet, Codable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let whiteKing  = CastlingRights(rawValue: 1 << 0)
        public static let whiteQueen = CastlingRights(rawValue: 1 << 1)
        public static let blackKing  = CastlingRights(rawValue: 1 << 2)
        public static let blackQueen = CastlingRights(rawValue: 1 << 3)
        public static let all: CastlingRights = [.whiteKing, .whiteQueen, .blackKing, .blackQueen]
    }

    public private(set) var squares: [Piece?]      // 64 entries
    public private(set) var sideToMove: PieceColor
    public private(set) var castlingRights: CastlingRights
    public private(set) var enPassantTarget: Square?
    public private(set) var halfmoveClock: Int     // for 50-move rule
    public private(set) var fullmoveNumber: Int

    public init(squares: [Piece?],
                sideToMove: PieceColor,
                castlingRights: CastlingRights,
                enPassantTarget: Square?,
                halfmoveClock: Int,
                fullmoveNumber: Int) {
        precondition(squares.count == 64, "Board must have 64 squares")
        self.squares = squares
        self.sideToMove = sideToMove
        self.castlingRights = castlingRights
        self.enPassantTarget = enPassantTarget
        self.halfmoveClock = halfmoveClock
        self.fullmoveNumber = fullmoveNumber
    }

    public subscript(square: Square) -> Piece? {
        get { squares[Int(square.index)] }
    }

    public static let startingPosition: Board = {
        FEN.parse("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")!
    }()

    public func kingSquare(of color: PieceColor) -> Square? {
        for (i, p) in squares.enumerated() where p?.color == color && p?.kind == .king {
            return Square(unchecked: i)
        }
        return nil
    }

    /// Returns a new board with the given move applied. Assumes the move is legal.
    public func applying(_ move: Move) -> Board {
        var next = self
        guard let moving = squares[Int(move.from.index)] else { return self }
        let captured = next.squares[Int(move.to.index)]
        let isPawnMove = moving.kind == .pawn
        let isCapture  = captured != nil || move.isEnPassant

        // Move piece (apply promotion if specified).
        next.squares[Int(move.from.index)] = nil
        next.squares[Int(move.to.index)]   = Piece(moving.color, move.promotion ?? moving.kind)

        // En passant capture: remove the pawn behind the destination square.
        if move.isEnPassant {
            let dir = moving.color == .white ? -1 : 1
            if let capturedSquare = move.to.offset(file: 0, rank: dir) {
                next.squares[Int(capturedSquare.index)] = nil
            }
        }

        // Castling: move the matching rook as well.
        if move.isCastleKingside || move.isCastleQueenside {
            let rank = moving.color == .white ? 0 : 7
            if move.isCastleKingside {
                let rookFrom = Square(file: 7, rank: rank)
                let rookTo   = Square(file: 5, rank: rank)
                next.squares[Int(rookTo.index)] = next.squares[Int(rookFrom.index)]
                next.squares[Int(rookFrom.index)] = nil
            } else {
                let rookFrom = Square(file: 0, rank: rank)
                let rookTo   = Square(file: 3, rank: rank)
                next.squares[Int(rookTo.index)] = next.squares[Int(rookFrom.index)]
                next.squares[Int(rookFrom.index)] = nil
            }
        }

        // Update castling rights.
        if moving.kind == .king {
            if moving.color == .white { next.castlingRights.remove([.whiteKing, .whiteQueen]) }
            else                      { next.castlingRights.remove([.blackKing, .blackQueen]) }
        }
        if moving.kind == .rook {
            if move.from == Square(file: 0, rank: 0) { next.castlingRights.remove(.whiteQueen) }
            if move.from == Square(file: 7, rank: 0) { next.castlingRights.remove(.whiteKing) }
            if move.from == Square(file: 0, rank: 7) { next.castlingRights.remove(.blackQueen) }
            if move.from == Square(file: 7, rank: 7) { next.castlingRights.remove(.blackKing) }
        }
        // Rook captured on its starting square also invalidates castling.
        if move.to == Square(file: 0, rank: 0) { next.castlingRights.remove(.whiteQueen) }
        if move.to == Square(file: 7, rank: 0) { next.castlingRights.remove(.whiteKing) }
        if move.to == Square(file: 0, rank: 7) { next.castlingRights.remove(.blackQueen) }
        if move.to == Square(file: 7, rank: 7) { next.castlingRights.remove(.blackKing) }

        // En passant target for next move.
        if moving.kind == .pawn && abs(move.to.rank - move.from.rank) == 2 {
            let dir = moving.color == .white ? 1 : -1
            next.enPassantTarget = move.from.offset(file: 0, rank: dir)
        } else {
            next.enPassantTarget = nil
        }

        // Clocks.
        next.halfmoveClock = (isPawnMove || isCapture) ? 0 : (halfmoveClock + 1)
        if sideToMove == .black { next.fullmoveNumber += 1 }
        next.sideToMove = sideToMove.opposite

        return next
    }
}
