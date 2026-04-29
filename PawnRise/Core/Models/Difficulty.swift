import Foundation

public enum Difficulty: Int, CaseIterable {
    case student
    case warrior
    case master
    case grandmaster

    public var title: String {
        switch self {
        case .student:     return "Учень"
        case .warrior:     return "Воїн"
        case .master:      return "Майстер"
        case .grandmaster: return "ГМ"
        }
    }

    public var emoji: String {
        switch self {
        case .student:     return "🌱"
        case .warrior:     return "⚔️"
        case .master:      return "♞"
        case .grandmaster: return "👑"
        }
    }

    public var eloRange: String {
        switch self {
        case .student:     return "400–800"
        case .warrior:     return "1200–1600"
        case .master:      return "1800–2200"
        case .grandmaster: return "2500+"
        }
    }

    /// Search depth for the minimax bot. Deliberately low so the app stays
    /// responsive — a real engine would use iterative deepening + αβ pruning.
    public var searchDepth: Int {
        switch self {
        case .student:     return 1
        case .warrior:     return 2
        case .master:      return 3
        case .grandmaster: return 4
        }
    }

    /// Probability in `[0,1]` of the bot picking a slightly worse move to mimic
    /// human-like imperfection at lower rungs.
    public var noise: Double {
        switch self {
        case .student:     return 0.55
        case .warrior:     return 0.25
        case .master:      return 0.08
        case .grandmaster: return 0.00
        }
    }
}
