import Foundation

public protocol HomeViewInput: AnyObject {
    func render()
}

public final class HomePresenter {
    public weak var view: HomeViewInput?
    public private(set) var model: HomeModel

    public init(model: HomeModel = HomeModel.mock) {
        self.model = model
    }

    public func viewDidLoad() {
        view?.render()
    }
}
