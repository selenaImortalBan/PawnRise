import Foundation

public struct Move: Codable, Hashable, CustomStringConvertible {
    public let from: Square
    public let to: Square
    public let promotion: PieceKind?
    public let isCastleKingside: Bool
    public let isCastleQueenside: Bool
    public let isEnPassant: Bool

    public init(from: Square,
                to: Square,
                promotion: PieceKind? = nil,
                isCastleKingside: Bool = false,
                isCastleQueenside: Bool = false,
                isEnPassant: Bool = false) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.isCastleKingside = isCastleKingside
        self.isCastleQueenside = isCastleQueenside
        self.isEnPassant = isEnPassant
    }

    public var isCastle: Bool { isCastleKingside || isCastleQueenside }

    /// UCI-style encoding: `e2e4`, `e7e8q`, etc.
    public var uci: String {
        let suffix = promotion.map { String($0.fenLetter) } ?? ""
        return "\(from.algebraic)\(to.algebraic)\(suffix)"
    }

    public var description: String { uci }
}
