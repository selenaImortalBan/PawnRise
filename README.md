# PawnRise ♞

An iOS chess coach app. A bot plays against you while a second AI coach watches
every move and gives annotated feedback through a chat UI. Ideal for learning
openings: pick an opening, play through it, and the coach will explain exactly
where you deviated and what the theoretical continuation should have been.

## Features

- **Three game modes**
  - *Рейтингова гра* — your ELO changes after every match.
  - *Вільна гра* — casual, no rating, coach hints always on.
  - *Гра за дебютом* — pick an opening and play it out; the coach nudges you
    whenever you leave the main line.
- **Four difficulty tiers** — Учень / Воїн / Майстер / ГМ.
- **Full chess engine in Swift** — legal move generation, castling, en passant,
  promotion, check/checkmate/stalemate, 50-move & threefold-repetition draws.
- **Heuristic bot** — material + PST evaluation with depth tuned per tier.
- **Opening book** with annotated lines for Sicilian, Caro-Kann, Italian, Ruy
  Lopez, French, Queen's Gambit.
- **Chat coach** — context-aware: reacts to blunders, opening deviations and
  tactical opportunities; user can ask follow-up questions.
- **Light & dark themes** that mirror the design mockup 1:1.

## Architecture

Classic **MVP** (Model–View–Presenter) on UIKit, layout with **SnapKit**, no
storyboards except `LaunchScreen`.

```
PawnRise/
├── App/           # AppDelegate, SceneDelegate, RootCoordinator
├── Core/
│   ├── Chess/     # Board, Move, MoveGenerator, FEN, GameState
│   ├── Bot/       # ChessBot (minimax + αβ), BotStrength
│   ├── Coach/     # CoachEngine, OpeningBook, ChatMessage
│   └── Models/    # GameMode, Difficulty, Opening
├── Design/        # Theme (colors, fonts), palette mirroring the HTML mockup
├── Common/        # Shared UI components (buttons, cards, tab bar)
└── Modules/
    ├── Home/      # HomeView + HomePresenter + HomeViewController
    ├── Play/
    ├── Game/      # ChessBoardView, ChatView, EvalBar, MoveStrip
    ├── Puzzles/
    └── Analysis/
```

## Getting started

### Requirements

- Xcode 15.3+
- iOS 16.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate the Xcode project

```bash
xcodegen generate
open PawnRise.xcodeproj
```

SnapKit is resolved through Swift Package Manager automatically on first build.

### Run tests

```bash
xcodebuild test \
  -project PawnRise.xcodeproj \
  -scheme PawnRise \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Design reference

The UI is a direct translation of `docs/design.html` (both light and dark
variants). Colors are wired into `Design/Theme.swift` and auto-switch with the
system appearance; a manual toggle is also available from Home.
