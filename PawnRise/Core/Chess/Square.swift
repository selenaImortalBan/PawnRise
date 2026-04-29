import Foundation

/// A square on an 8x8 board encoded as a flat index 0...63.
/// Index 0  = a1 (white's queenside rook start).
/// Index 63 = h8.
public struct Square: Codable, Hashable, CustomStringConvertible {
    public let index: Int8

    public init?(index: Int) {
        guard (0..<64).contains(index) else { return nil }
        self.index = Int8(index)
    }

    public init(unchecked index: Int) {
        self.index = Int8(index)
    }

    public init(file: Int, rank: Int) {
        precondition((0..<8).contains(file) && (0..<8).contains(rank),
                     "file/rank out of range: \(file),\(rank)")
        self.index = Int8(rank * 8 + file)
    }

    public var file: Int { Int(index) % 8 }
    public var rank: Int { Int(index) / 8 }

    /// Algebraic notation (`e4`, `a1`, ...).
    public var algebraic: String {
        let fileChar = "abcdefgh"[String.Index(utf16Offset: file, in: "abcdefgh")]
        return "\(fileChar)\(rank + 1)"
    }

    public var description: String { algebraic }

    public static func from(algebraic s: String) -> Square? {
        guard s.count == 2,
              let f = s.first?.lowercased().first,
              let r = s.last,
              let fileIdx = "abcdefgh".firstIndex(of: f),
              let rankValue = Int(String(r)), (1...8).contains(rankValue) else { return nil }
        return Square(file: "abcdefgh".distance(from: "abcdefgh".startIndex, to: fileIdx),
                      rank: rankValue - 1)
    }

    public func offset(file df: Int, rank dr: Int) -> Square? {
        let nf = file + df, nr = rank + dr
        guard (0..<8).contains(nf), (0..<8).contains(nr) else { return nil }
        return Square(file: nf, rank: nr)
    }
}

public extension Collection where Element == Square {
    var algebraicList: String { map { $0.algebraic }.joined(separator: " ") }
}
