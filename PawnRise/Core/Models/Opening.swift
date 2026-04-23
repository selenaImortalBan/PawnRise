import Foundation

/// Chess opening definition used both by the "by-opening" game mode and by the
/// coach to detect deviations from the main line.
public struct Opening: Hashable, Identifiable {
    public let id: String            // e.g. "sicilian-najdorf"
    public let displayName: String   // e.g. "Сицилійська · Найдорф"
    public let eco: String           // e.g. "B90"
    /// Main-line moves encoded as UCI (`e2e4`, `c7c5`, ...).
    public let mainLine: [String]
    public let summary: String
    /// Key ideas shown to the player in chat when the opening starts.
    public let ideas: [String]

    public init(id: String,
                displayName: String,
                eco: String,
                mainLine: [String],
                summary: String,
                ideas: [String]) {
        self.id = id
        self.displayName = displayName
        self.eco = eco
        self.mainLine = mainLine
        self.summary = summary
        self.ideas = ideas
    }
}

public enum OpeningCatalog {

    public static let all: [Opening] = [
        Opening(
            id: "sicilian-najdorf",
            displayName: "Сицилійська · Найдорф",
            eco: "B90",
            mainLine: ["e2e4", "c7c5", "g1f3", "d7d6", "d2d4", "c5d4", "f3d4", "g8f6", "b1c3", "a7a6"],
            summary: "Найгостріший захист проти 1.e4. Чорні борються за d5 і готують контргру по чорних полях.",
            ideas: [
                "Розвивай коня на c3 та займай центр ходом e4 / d4.",
                "Стеж за темою Nd5: якщо суперник нехтує полем, стрибай туди конем.",
                "Не дозволяй b7–b5 без контргри на крайньому фланзі."
            ]
        ),
        Opening(
            id: "italian",
            displayName: "Італійська партія",
            eco: "C50",
            mainLine: ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "f8c5", "c2c3", "g8f6", "d2d3"],
            summary: "Класичний іспано-італійський сетап. Акуратна боротьба за центр з атакою на f7.",
            ideas: [
                "Слон на c4 націлений на f7 — використовуй при можливості.",
                "Готуй c3-d4 у потрібний момент.",
                "Рокіруй якомога швидше: короткий король — активні важкі фігури."
            ]
        ),
        Opening(
            id: "ruy-lopez",
            displayName: "Іспанська партія",
            eco: "C65",
            mainLine: ["e2e4", "e7e5", "g1f3", "b8c6", "f1b5", "a7a6", "b5a4", "g8f6", "e1g1"],
            summary: "Один з найстаріших і найглибших дебютів. Тиск на c6 і контроль центру через d4.",
            ideas: [
                "Не поспішай міняти на c6 — слон b5 рідко втрачає темп.",
                "Готуй план c3 + d4 з тиском на e5.",
                "Чорним небезпечний Marshall Attack — май у запасі 8.a4 або 8.h3."
            ]
        ),
        Opening(
            id: "french",
            displayName: "Французький захист",
            eco: "C11",
            mainLine: ["e2e4", "e7e6", "d2d4", "d7d5", "b1c3", "g8f6", "e4e5", "f6d7"],
            summary: "Чорні свідомо віддають простір у центрі заради солідної структури.",
            ideas: [
                "Блокуй центр ходом e5 і шукай атаку на королівському фланзі.",
                "Перевага у просторі → активні фігури, не розмінюй легких фігур просто так.",
                "Стеж за проривом c5 — типовий контргра-удар чорних."
            ]
        ),
        Opening(
            id: "caro-kann",
            displayName: "Каро-Канн",
            eco: "B10",
            mainLine: ["e2e4", "c7c6", "d2d4", "d7d5", "b1c3", "d5e4", "c3e4", "b8d7"],
            summary: "Солідний захист з акуратною пішаковою структурою. Чорні уникають слабкостей.",
            ideas: [
                "Чорний слон c8 має вийти на f5 / g4 до ходу e6.",
                "Білі мають простір — грай на випередження з Ne4–Ng3 або Bd3.",
                "Пам'ятай про гострі лінії з Ng5 проти 4...Nd7."
            ]
        ),
        Opening(
            id: "queens-gambit",
            displayName: "Ферзевий гамбіт",
            eco: "D35",
            mainLine: ["d2d4", "d7d5", "c2c4", "e7e6", "b1c3", "g8f6", "c4d5", "e6d5"],
            summary: "Білі тиснуть на центр через розмін на d5. Карлсбадська структура — типовий мітл-гейм.",
            ideas: [
                "Плануй мінорітарну атаку на ферзевому фланзі (b4–b5).",
                "Слон на f4/g5 натискає на важливі чорні поля.",
                "Чорним важливо розвинути слона c8 — тематично через b6/Bb7."
            ]
        )
    ]

    public static func opening(byId id: String) -> Opening? { all.first { $0.id == id } }
}
