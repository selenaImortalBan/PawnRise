import Foundation

public enum PieceColor: Int, Codable, Hashable {
    case white = 0
    case black = 1

    public var opposite: PieceColor { self == .white ? .black : .white }
}

public enum PieceKind: Int, Codable, Hashable, CaseIterable {
    case pawn, knight, bishop, rook, queen, king

    public var materialValue: Int {
        switch self {
        case .pawn:   return 100
        case .knight: return 320
        case .bishop: return 330
        case .rook:   return 500
        case .queen:  return 900
        case .king:   return 20_000
        }
    }

    /// Single ASCII letter used by FEN (uppercase for white).
    public var fenLetter: Character {
        switch self {
        case .pawn:   return "p"
        case .knight: return "n"
        case .bishop: return "b"
        case .rook:   return "r"
        case .queen:  return "q"
        case .king:   return "k"
        }
    }
}

public struct Piece: Codable, Hashable {
    public let color: PieceColor
    public let kind: PieceKind

    public init(_ color: PieceColor, _ kind: PieceKind) {
        self.color = color
        self.kind = kind
    }

    /// Unicode glyph that matches the figures used in the HTML mockup
    /// (filled silhouettes; tinted later by `ChessBoardView`).
    public var glyph: String {
        switch (color, kind) {
        case (.white, .king):   return "♔"
        case (.white, .queen):  return "♕"
        case (.white, .rook):   return "♖"
        case (.white, .bishop): return "♗"
        case (.white, .knight): return "♘"
        case (.white, .pawn):   return "♙"
        case (.black, .king):   return "♚"
        case (.black, .queen):  return "♛"
        case (.black, .rook):   return "♜"
        case (.black, .bishop): return "♝"
        case (.black, .knight): return "♞"
        case (.black, .pawn):   return "♟"
        }
    }

    public var fenChar: Character {
        let letter = kind.fenLetter
        return color == .white ? Character(letter.uppercased()) : letter
    }
}
