import XCTest
@testable import PawnRise

final class CoachEngineTests: XCTestCase {

    func testOpeningDeviationTriggersWarning() {
        let opening = OpeningCatalog.opening(byId: "sicilian-najdorf")!
        let engine = CoachEngine(context: .init(mode: .opening,
                                                difficulty: .master,
                                                opening: opening))
        // First move in main line = e2e4. User plays d2d4 instead.
        let board = Board.startingPosition
        let wrongMove = Move(from: Square.from(algebraic: "d2")!,
                             to: Square.from(algebraic: "d4")!)
        let next = board.applying(wrongMove)
        let messages = engine.reactions(after: wrongMove,
                                        san: "d4",
                                        boardBefore: board,
                                        boardAfter: next,
                                        movedBy: .white)
        XCTAssertTrue(messages.contains(where: { $0.tone == .warning }),
                      "Coach should warn about deviating from opening main line")
    }

    func testOpeningInlineStaysSilentOnWarning() {
        let opening = OpeningCatalog.opening(byId: "italian")!
        let engine = CoachEngine(context: .init(mode: .opening, difficulty: .master, opening: opening))
        let e4 = Move(from: Square.from(algebraic: "e2")!,
                      to: Square.from(algebraic: "e4")!)
        let board = Board.startingPosition
        let next = board.applying(e4)
        let messages = engine.reactions(after: e4, san: "e4",
                                        boardBefore: board, boardAfter: next,
                                        movedBy: .white)
        XCTAssertFalse(messages.contains(where: { $0.tone == .warning }),
                       "In-book moves should not trigger warnings")
    }

    func testGreetingIncludesOpeningSummary() {
        let opening = OpeningCatalog.opening(byId: "caro-kann")!
        let engine = CoachEngine(context: .init(mode: .opening,
                                                difficulty: .master,
                                                opening: opening))
        let greeting = engine.greeting()
        XCTAssertTrue(greeting.contains { $0.text.contains("Каро-Канн") })
    }
}
