import UIKit

/// Single source of truth for colors, fonts, metrics. Mirrors `design.html` 1:1
/// — CSS variables on `:root` map to `Palette.light`, `body.dark` to `Palette.dark`.
public enum ThemeMode: String, CaseIterable {
    case system
    case light
    case dark
}

public final class ThemeManager {

    public static let shared = ThemeManager()

    private let defaultsKey = "pawnrise.themeMode"
    private(set) public var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: defaultsKey)
            applyCurrentAppearance()
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: defaultsKey),
           let stored = ThemeMode(rawValue: raw) {
            self.mode = stored
        } else {
            self.mode = .system
        }
    }

    public func setMode(_ mode: ThemeMode) { self.mode = mode }

    public func toggleLightDark() {
        // Ignores `.system` and flips between light/dark explicitly.
        switch mode {
        case .light: setMode(.dark)
        case .dark:  setMode(.light)
        case .system:
            let current = UITraitCollection.current.userInterfaceStyle
            setMode(current == .dark ? .light : .dark)
        }
    }

    public func applyCurrentAppearance() {
        let style: UIUserInterfaceStyle = {
            switch mode {
            case .system: return .unspecified
            case .light:  return .light
            case .dark:   return .dark
            }
        }()
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

public enum Palette {

    public struct Colors {
        public let bg, s1, s2, s3: UIColor
        public let brd, brd2: UIColor
        public let tx1, tx2, tx3, tx4: UIColor
        public let acc, acc2, accd, accbrd: UIColor
        public let win, wind, winbrd: UIColor
        public let red, redd: UIColor
        public let warn, warnd: UIColor
        public let draw, drawd: UIColor
        public let sqLight, sqDark: UIColor
        public let hl: UIColor
        public let lmLight, lmDark: UIColor
    }

    /// Static maps. We resolve per trait at runtime through `Theme.color(...)`.
    public static let light = Colors(
        bg:      UIColor(hex: 0xFAF7F4),
        s1:      UIColor(hex: 0xF2EDE8),
        s2:      UIColor(hex: 0xE8E0D8),
        s3:      UIColor(hex: 0xDDD3C8),
        brd:     UIColor(hex: 0xE0D6CC),
        brd2:    UIColor(hex: 0xCEC3B8),
        tx1:     UIColor(hex: 0x1A1410),
        tx2:     UIColor(hex: 0x5A4E44),
        tx3:     UIColor(hex: 0x9A8E84),
        tx4:     UIColor(hex: 0xC4BAB0),
        acc:     UIColor(hex: 0x7A4E2A),
        acc2:    UIColor(hex: 0x9A6438),
        accd:    UIColor(hex: 0x7A4E2A, alpha: 0.10),
        accbrd:  UIColor(hex: 0x7A4E2A, alpha: 0.24),
        win:     UIColor(hex: 0x3A7A4A),
        wind:    UIColor(hex: 0x3A7A4A, alpha: 0.10),
        winbrd:  UIColor(hex: 0x3A7A4A, alpha: 0.22),
        red:     UIColor(hex: 0xA03030),
        redd:    UIColor(hex: 0xA03030, alpha: 0.10),
        warn:    UIColor(hex: 0xA06A20),
        warnd:   UIColor(hex: 0xA06A20, alpha: 0.10),
        draw:    UIColor(hex: 0x5878A0),
        drawd:   UIColor(hex: 0x5878A0, alpha: 0.10),
        sqLight: UIColor(hex: 0xC8B882),
        sqDark:  UIColor(hex: 0x5C4220),
        hl:      UIColor(hex: 0x7A4E2A, alpha: 0.35),
        lmLight: UIColor(hex: 0xD2C17D),
        lmDark:  UIColor(hex: 0x73582A)
    )

    public static let dark = Colors(
        bg:      UIColor(hex: 0x161311),
        s1:      UIColor(hex: 0x221E1B),
        s2:      UIColor(hex: 0x2E2925),
        s3:      UIColor(hex: 0x3B3530),
        brd:     UIColor(hex: 0x3B3530),
        brd2:    UIColor(hex: 0x4D4640),
        tx1:     UIColor(hex: 0xF4F0EC),
        tx2:     UIColor(hex: 0xD4C9C0),
        tx3:     UIColor(hex: 0x9A8E84),
        tx4:     UIColor(hex: 0x7D7267),
        acc:     UIColor(hex: 0xD49B6A),
        acc2:    UIColor(hex: 0xB87F50),
        accd:    UIColor(hex: 0xD49B6A, alpha: 0.15),
        accbrd:  UIColor(hex: 0xD49B6A, alpha: 0.30),
        win:     UIColor(hex: 0x5DA66F),
        wind:    UIColor(hex: 0x5DA66F, alpha: 0.15),
        winbrd:  UIColor(hex: 0x5DA66F, alpha: 0.30),
        red:     UIColor(hex: 0xD95A5A),
        redd:    UIColor(hex: 0xD95A5A, alpha: 0.15),
        warn:    UIColor(hex: 0xD4A050),
        warnd:   UIColor(hex: 0xD4A050, alpha: 0.15),
        draw:    UIColor(hex: 0x7DA3D1),
        drawd:   UIColor(hex: 0x7DA3D1, alpha: 0.15),
        sqLight: UIColor(hex: 0xA89972),
        sqDark:  UIColor(hex: 0x4A351A),
        hl:      UIColor(hex: 0xD49B6A, alpha: 0.35),
        lmLight: UIColor(hex: 0xB5A66B),
        lmDark:  UIColor(hex: 0x634B22)
    )
}

/// Namespace for semantic color accessors that resolve per trait collection.
public enum Theme {
    public static func color(_ key: KeyPath<Palette.Colors, UIColor>) -> UIColor {
        UIColor { trait in
            let palette: Palette.Colors = trait.userInterfaceStyle == .dark ? Palette.dark : Palette.light
            return palette[keyPath: key]
        }
    }

    public enum Fonts {
        public static func inter(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: weight)
        }
        public static func mono(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        }
    }
}
