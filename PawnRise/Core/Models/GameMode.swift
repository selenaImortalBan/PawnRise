import Foundation

public enum GameMode: Equatable {
    case rated
    case free
    case opening

    public var title: String {
        switch self {
        case .rated:   return "Рейтингова гра"
        case .free:    return "Вільна гра"
        case .opening: return "Гра за дебютом"
        }
    }

    public var subtitle: String {
        switch self {
        case .rated:   return "ШІ адаптується до рівня. ELO змінюється після кожної партії."
        case .free:    return "Без тиску рейтингу. Підказки ШІ завжди доступні."
        case .opening: return "Обери дебют і грай з тієї позиції. 68 варіантів."
        }
    }

    public var tags: [String] {
        switch self {
        case .rated:   return ["ELO", "AI-аналіз"]
        case .free:    return ["Без рейтингу", "Підказки"]
        case .opening: return ["Теорія", "68 дебютів"]
        }
    }
}
