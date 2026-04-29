import Foundation

public enum ChatSender: Equatable {
    case coach
    case user
}

public enum CoachTone: Equatable {
    case info
    case praise
    case warning
    case hint
}

public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let sender: ChatSender
    public let text: String
    public let tone: CoachTone
    public let timestamp: Date
    public let movePrefix: String?    // e.g. "Хід 4"

    public init(sender: ChatSender,
                text: String,
                tone: CoachTone = .info,
                movePrefix: String? = nil,
                timestamp: Date = Date()) {
        self.sender = sender
        self.text = text
        self.tone = tone
        self.movePrefix = movePrefix
        self.timestamp = timestamp
    }
}
