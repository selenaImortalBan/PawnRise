import UIKit

/// Thin coordinator that owns the root tab bar and pushes full-screen game flows on top of it.
final class RootCoordinator {

    private let window: UIWindow
    private let tabBar = RootTabBarController()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        // Home tab receives a reference to us so the "Play Now" CTA can launch a game.
        let home = HomeViewController(onStartGame: { [weak self] in
            self?.startGame(mode: .rated, difficulty: .master, opening: nil, presentingFrom: self?.tabBar)
        }, onGoToPlay: { [weak self] in
            self?.tabBar.selectedIndex = 1
        }, onOpenPuzzles: { [weak self] in
            self?.tabBar.selectedIndex = 2
        }, onOpenAnalysis: { [weak self] in
            self?.tabBar.selectedIndex = 3
        })

        let play = PlayViewController(onStart: { [weak self] mode, difficulty, opening in
            self?.startGame(mode: mode, difficulty: difficulty, opening: opening, presentingFrom: self?.tabBar)
        })

        let puzzles = PuzzlesViewController()
        let analysis = AnalysisViewController()

        tabBar.setTabs([home, play, puzzles, analysis])

        window.rootViewController = tabBar
        window.makeKeyAndVisible()
    }

    private func startGame(mode: GameMode,
                           difficulty: Difficulty,
                           opening: Opening?,
                           presentingFrom presenter: UIViewController?) {
        let gameVC = GameViewController(mode: mode, difficulty: difficulty, opening: opening)
        gameVC.modalPresentationStyle = .fullScreen
        presenter?.present(gameVC, animated: true)
    }
}
