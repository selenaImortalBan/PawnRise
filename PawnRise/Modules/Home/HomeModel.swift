import UIKit

public struct HomeModel {

    public struct StatsSummary {
        public let puzzles: Int
        public let puzzleAccuracy: Int
        public let winRate: Int
        public let winDelta: Int
        public let streakDays: Int
    }

    public struct Insight {
        public let title: String
        public let subtitle: String
        public let attributedBody: NSAttributedString
    }

    public enum GameResult { case win, loss, draw }

    public struct RecentGame {
        public let opponent: String
        public let kind: String
        public let opening: String
        public let result: GameResult
        public let delta: String
    }

    public let elo: Int
    public let statsSummary: StatsSummary
    public let insight: Insight
    public let recentGames: [RecentGame]

    public static let mock: HomeModel = {
        let body = NSMutableAttributedString(
            string: "Ти слабшаєш на ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12.5, weight: .light),
                .foregroundColor: Theme.color(\.tx2)
            ]
        )
        body.append(NSAttributedString(string: "15–20 ходах у blitz",
                                       attributes: [
                                        .font: UIFont.systemFont(ofSize: 12.5, weight: .semibold),
                                        .foregroundColor: Theme.color(\.tx1)
                                       ]))
        body.append(NSAttributedString(string: ". Відточи ",
                                       attributes: [
                                        .font: UIFont.systemFont(ofSize: 12.5, weight: .light),
                                        .foregroundColor: Theme.color(\.tx2)
                                       ]))
        body.append(NSAttributedString(string: "тактику в Сицилійській",
                                       attributes: [
                                        .font: UIFont.systemFont(ofSize: 12.5, weight: .semibold),
                                        .foregroundColor: Theme.color(\.tx1)
                                       ]))
        body.append(NSAttributedString(string: " — особливо middlegame.",
                                       attributes: [
                                        .font: UIFont.systemFont(ofSize: 12.5, weight: .light),
                                        .foregroundColor: Theme.color(\.tx2)
                                       ]))

        return HomeModel(
            elo: 1847,
            statsSummary: StatsSummary(puzzles: 342,
                                       puzzleAccuracy: 87,
                                       winRate: 68,
                                       winDelta: 4,
                                       streakDays: 7),
            insight: Insight(title: "Порада тренера",
                             subtitle: "Аналіз 5 останніх партій",
                             attributedBody: body),
            recentGames: [
                RecentGame(opponent: "ШІ · Майстер",     kind: "Blitz", opening: "Сицилійська", result: .win,  delta: "+8"),
                RecentGame(opponent: "ШІ · Гросмейстер", kind: "Rapid", opening: "Каро-Канн",    result: .loss, delta: "−6")
            ]
        )
    }()
}
