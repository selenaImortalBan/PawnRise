import Foundation

public protocol PlayViewInput: AnyObject {
    func render()
}

public final class PlayPresenter {
    public weak var view: PlayViewInput?
    public private(set) var selectedDifficulty: Difficulty = .master

    public init() {}

    public func viewDidLoad() { view?.render() }

    public func setDifficulty(_ diff: Difficulty) {
        selectedDifficulty = diff
    }
}
