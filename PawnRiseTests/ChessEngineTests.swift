import XCTest
@testable import PawnRise

final class ChessEngineTests: XCTestCase {

    func testStartingPositionHas20LegalMoves() {
        let board = Board.startingPosition
        let moves = MoveGenerator.legalMoves(for: board)
        XCTAssertEqual(moves.count, 20)
    }

    func testFoolsMateIsCheckmate() {
        let game = GameState()
        XCTAssertTrue(game.make(Move(from: Square.from(algebraic: "f2")!, to: Square.from(algebraic: "f3")!)))
        XCTAssertTrue(game.make(Move(from: Square.from(algebraic: "e7")!, to: Square.from(algebraic: "e5")!)))
        XCTAssertTrue(game.make(Move(from: Square.from(algebraic: "g2")!, to: Square.from(algebraic: "g4")!)))
        XCTAssertTrue(game.make(Move(from: Square.from(algebraic: "d8")!, to: Square.from(algebraic: "h4")!)))
        if case .checkmate(let winner) = game.outcome {
            XCTAssertEqual(winner, .black)
        } else {
            XCTFail("Expected checkmate")
        }
    }

    func testCastlingKingside() {
        guard let board = FEN.parse("r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4") else {
            return XCTFail("FEN parse failed")
        }
        let castle = Move(from: Square.from(algebraic: "e1")!,
                          to: Square.from(algebraic: "g1")!,
                          isCastleKingside: true)
        let moves = MoveGenerator.legalMoves(for: board)
        XCTAssertTrue(moves.contains(castle))
        let after = board.applying(castle)
        XCTAssertEqual(after[Square.from(algebraic: "g1")!]?.kind, .king)
        XCTAssertEqual(after[Square.from(algebraic: "f1")!]?.kind, .rook)
    }

    func testEnPassant() {
        guard let board = FEN.parse("rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3") else {
            return XCTFail("FEN parse failed")
        }
        let move = Move(from: Square.from(algebraic: "e5")!,
                        to: Square.from(algebraic: "d6")!,
                        isEnPassant: true)
        XCTAssertTrue(MoveGenerator.legalMoves(for: board).contains(move))
        let after = board.applying(move)
        XCTAssertNil(after[Square.from(algebraic: "d5")!])
        XCTAssertEqual(after[Square.from(algebraic: "d6")!]?.kind, .pawn)
    }

    func testPromotion() {
        guard let board = FEN.parse("8/P7/8/8/8/8/8/4k2K w - - 0 1") else {
            return XCTFail("FEN parse failed")
        }
        let moves = MoveGenerator.legalMoves(for: board).filter {
            $0.from == Square.from(algebraic: "a7")! && $0.to == Square.from(algebraic: "a8")!
        }
        XCTAssertEqual(Set(moves.compactMap { $0.promotion }), Set([.queen, .rook, .bishop, .knight]))
    }

    func testInsufficientMaterial() {
        guard let board = FEN.parse("8/8/8/8/8/8/8/k6K w - - 0 1") else {
            return XCTFail("FEN parse failed")
        }
        let game = GameState(board: board)
        XCTAssertEqual(game.outcome, .drawInsufficientMaterial)
    }

    func testFENRoundtrip() {
        let initial = "r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
        guard let parsed = FEN.parse(initial) else { return XCTFail() }
        XCTAssertEqual(FEN.encode(parsed), initial)
    }

    func testSANBasicMoves() {
        let board = Board.startingPosition
        let e4 = Move(from: Square.from(algebraic: "e2")!, to: Square.from(algebraic: "e4")!)
        XCTAssertEqual(SAN.encode(e4, on: board), "e4")
        let nf3 = Move(from: Square.from(algebraic: "g1")!, to: Square.from(algebraic: "f3")!)
        XCTAssertEqual(SAN.encode(nf3, on: board), "Nf3")
    }

    func testOpeningCatalogHasMainLines() {
        XCTAssertFalse(OpeningCatalog.all.isEmpty)
        for opening in OpeningCatalog.all {
            XCTAssertFalse(opening.mainLine.isEmpty, "\(opening.id) must have a main line")
            // Every main line move should be legal from the starting position step-by-step.
            var board = Board.startingPosition
            for uci in opening.mainLine {
                guard let move = ChessEngineTests.parse(uci: uci, on: board) else {
                    return XCTFail("Opening \(opening.id): unable to parse \(uci)")
                }
                XCTAssertTrue(MoveGenerator.legalMoves(for: board).contains(move),
                              "Opening \(opening.id) move \(uci) is not legal")
                board = board.applying(move)
            }
        }
    }

    private static func parse(uci: String, on board: Board) -> Move? {
        guard uci.count >= 4,
              let from = Square.from(algebraic: String(uci.prefix(2))),
              let to = Square.from(algebraic: String(uci.dropFirst(2).prefix(2)))
        else { return nil }
        let promotion: PieceKind? = uci.count == 5 ? {
            switch uci.last {
            case "q": return .queen
            case "r": return .rook
            case "b": return .bishop
            case "n": return .knight
            default:  return nil
            }
        }() : nil
        return MoveGenerator.legalMoves(for: board)
            .first { $0.from == from && $0.to == to && $0.promotion == promotion }
    }
}
