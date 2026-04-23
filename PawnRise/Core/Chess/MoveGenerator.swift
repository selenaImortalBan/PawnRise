import Foundation

/// Generates legal moves for a given `Board`. Not the fastest implementation
/// possible — correctness is the priority. For move search the bot can cache
/// results since `Board` is `Hashable`.
public enum MoveGenerator {

    private static let knightOffsets: [(Int, Int)] = [
        (1, 2), (2, 1), (2, -1), (1, -2),
        (-1, -2), (-2, -1), (-2, 1), (-1, 2)
    ]
    private static let bishopDirs: [(Int, Int)] = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    private static let rookDirs:   [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    private static let kingDirs:   [(Int, Int)] = bishopDirs + rookDirs

    // MARK: - Public API

    public static func legalMoves(for board: Board) -> [Move] {
        pseudoLegalMoves(for: board).filter { move in
            let next = board.applying(move)
            guard let kingSq = next.kingSquare(of: board.sideToMove) else { return false }
            return !isSquareAttacked(kingSq, by: board.sideToMove.opposite, on: next)
        }
    }

    public static func legalMoves(from square: Square, on board: Board) -> [Move] {
        legalMoves(for: board).filter { $0.from == square }
    }

    public static func isInCheck(_ color: PieceColor, on board: Board) -> Bool {
        guard let kingSq = board.kingSquare(of: color) else { return false }
        return isSquareAttacked(kingSq, by: color.opposite, on: board)
    }

    /// True if `target` is attacked by any piece of `color` on `board`.
    public static func isSquareAttacked(_ target: Square, by color: PieceColor, on board: Board) -> Bool {
        // Pawn attacks
        let pawnDir = color == .white ? 1 : -1
        for df in [-1, 1] {
            if let from = target.offset(file: df, rank: -pawnDir),
               let piece = board[from],
               piece.color == color, piece.kind == .pawn {
                return true
            }
        }
        // Knight attacks
        for (df, dr) in knightOffsets {
            if let from = target.offset(file: df, rank: dr),
               let piece = board[from], piece.color == color, piece.kind == .knight {
                return true
            }
        }
        // Sliders (bishop/queen diagonals, rook/queen straights)
        for (df, dr) in bishopDirs {
            if slidingAttacker(from: target, df: df, dr: dr, on: board,
                               acceptKinds: [.bishop, .queen], color: color) { return true }
        }
        for (df, dr) in rookDirs {
            if slidingAttacker(from: target, df: df, dr: dr, on: board,
                               acceptKinds: [.rook, .queen], color: color) { return true }
        }
        // King (adjacency)
        for (df, dr) in kingDirs {
            if let from = target.offset(file: df, rank: dr),
               let piece = board[from], piece.color == color, piece.kind == .king {
                return true
            }
        }
        return false
    }

    private static func slidingAttacker(from square: Square,
                                        df: Int, dr: Int,
                                        on board: Board,
                                        acceptKinds: Set<PieceKind>,
                                        color: PieceColor) -> Bool {
        var current = square
        while let next = current.offset(file: df, rank: dr) {
            if let piece = board[next] {
                return piece.color == color && acceptKinds.contains(piece.kind)
            }
            current = next
        }
        return false
    }

    // MARK: - Pseudo-legal generation

    public static func pseudoLegalMoves(for board: Board) -> [Move] {
        var moves: [Move] = []
        let side = board.sideToMove
        for i in 0..<64 {
            guard let piece = board.squares[i], piece.color == side else { continue }
            let sq = Square(unchecked: i)
            switch piece.kind {
            case .pawn:   generatePawnMoves(from: sq, piece: piece, board: board, into: &moves)
            case .knight: generateStepMoves(offsets: knightOffsets, from: sq, piece: piece, board: board, into: &moves)
            case .bishop: generateSlidingMoves(dirs: bishopDirs, from: sq, piece: piece, board: board, into: &moves)
            case .rook:   generateSlidingMoves(dirs: rookDirs,   from: sq, piece: piece, board: board, into: &moves)
            case .queen:  generateSlidingMoves(dirs: kingDirs,   from: sq, piece: piece, board: board, into: &moves)
            case .king:   generateKingMoves(from: sq, piece: piece, board: board, into: &moves)
            }
        }
        return moves
    }

    private static func generateStepMoves(offsets: [(Int, Int)],
                                          from sq: Square,
                                          piece: Piece,
                                          board: Board,
                                          into moves: inout [Move]) {
        for (df, dr) in offsets {
            guard let target = sq.offset(file: df, rank: dr) else { continue }
            if let occupying = board[target], occupying.color == piece.color { continue }
            moves.append(Move(from: sq, to: target))
        }
    }

    private static func generateSlidingMoves(dirs: [(Int, Int)],
                                             from sq: Square,
                                             piece: Piece,
                                             board: Board,
                                             into moves: inout [Move]) {
        for (df, dr) in dirs {
            var current = sq
            while let next = current.offset(file: df, rank: dr) {
                if let occupying = board[next] {
                    if occupying.color != piece.color {
                        moves.append(Move(from: sq, to: next))
                    }
                    break
                }
                moves.append(Move(from: sq, to: next))
                current = next
            }
        }
    }

    private static func generatePawnMoves(from sq: Square,
                                          piece: Piece,
                                          board: Board,
                                          into moves: inout [Move]) {
        let dir = piece.color == .white ? 1 : -1
        let startRank = piece.color == .white ? 1 : 6
        let promotionRank = piece.color == .white ? 7 : 0

        // Single push
        if let one = sq.offset(file: 0, rank: dir), board[one] == nil {
            if one.rank == promotionRank {
                for promo in [PieceKind.queen, .rook, .bishop, .knight] {
                    moves.append(Move(from: sq, to: one, promotion: promo))
                }
            } else {
                moves.append(Move(from: sq, to: one))
                // Double push
                if sq.rank == startRank,
                   let two = sq.offset(file: 0, rank: 2 * dir),
                   board[two] == nil {
                    moves.append(Move(from: sq, to: two))
                }
            }
        }

        // Captures (+ promotions, + en passant)
        for df in [-1, 1] {
            guard let target = sq.offset(file: df, rank: dir) else { continue }
            if let occupying = board[target], occupying.color != piece.color {
                if target.rank == promotionRank {
                    for promo in [PieceKind.queen, .rook, .bishop, .knight] {
                        moves.append(Move(from: sq, to: target, promotion: promo))
                    }
                } else {
                    moves.append(Move(from: sq, to: target))
                }
            } else if let ep = board.enPassantTarget, ep == target {
                moves.append(Move(from: sq, to: target, isEnPassant: true))
            }
        }
    }

    private static func generateKingMoves(from sq: Square,
                                          piece: Piece,
                                          board: Board,
                                          into moves: inout [Move]) {
        generateStepMoves(offsets: kingDirs, from: sq, piece: piece, board: board, into: &moves)

        let rank = piece.color == .white ? 0 : 7
        guard sq == Square(file: 4, rank: rank) else { return }
        // King is attacked? Castling illegal.
        if isSquareAttacked(sq, by: piece.color.opposite, on: board) { return }

        let kingSide  = piece.color == .white ? Board.CastlingRights.whiteKing  : .blackKing
        let queenSide = piece.color == .white ? Board.CastlingRights.whiteQueen : .blackQueen

        if board.castlingRights.contains(kingSide) {
            let f5 = Square(file: 5, rank: rank)
            let f6 = Square(file: 6, rank: rank)
            if board[f5] == nil, board[f6] == nil,
               !isSquareAttacked(f5, by: piece.color.opposite, on: board),
               !isSquareAttacked(f6, by: piece.color.opposite, on: board) {
                moves.append(Move(from: sq, to: f6, isCastleKingside: true))
            }
        }
        if board.castlingRights.contains(queenSide) {
            let f1 = Square(file: 1, rank: rank)
            let f2 = Square(file: 2, rank: rank)
            let f3 = Square(file: 3, rank: rank)
            if board[f1] == nil, board[f2] == nil, board[f3] == nil,
               !isSquareAttacked(f3, by: piece.color.opposite, on: board),
               !isSquareAttacked(f2, by: piece.color.opposite, on: board) {
                moves.append(Move(from: sq, to: f2, isCastleQueenside: true))
            }
        }
    }
}
