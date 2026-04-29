import UIKit
import SnapKit

public protocol ChessBoardViewDelegate: AnyObject {
    /// Delegate should return legal moves from `square` for the current side.
    func boardView(_ view: ChessBoardView, legalMovesFrom square: Square) -> [Move]
    func boardView(_ view: ChessBoardView, didSelect move: Move)
    func boardViewShouldPromptForPromotion(_ view: ChessBoardView) -> Bool
}

/// Renders a chess position and handles user interaction (tap-select + tap-move).
/// Pure UIKit, uses SnapKit for layout. The board is aligned with the white
/// player at the bottom (rank 1) to match the HTML mockup.
public final class ChessBoardView: UIView {

    public weak var delegate: ChessBoardViewDelegate?

    public private(set) var board: Board = .startingPosition
    public private(set) var lastMove: Move?

    private var squareViews: [SquareView] = []
    private var selectedSquare: Square?
    private var highlightedTargets: Set<Square> = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        buildGrid()
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        layer.borderColor = Theme.color(\.brd2).resolvedColor(with: traitCollection).cgColor
        refresh()
    }

    private func buildGrid() {
        layer.borderWidth = 1
        layer.borderColor = Theme.color(\.brd2).cgColor
        layer.cornerRadius = 6
        clipsToBounds = true

        for rank in stride(from: 7, through: 0, by: -1) {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                let view = SquareView(square: sq)
                view.isUserInteractionEnabled = true
                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                view.addGestureRecognizer(tap)
                addSubview(view)
                squareViews.append(view)
            }
        }
        refresh()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let side = bounds.width / 8
        for view in squareViews {
            let sq = view.square
            // Row 0 of the view grid represents rank 7 (top). To keep addresses simple
            // we just compute position from the square directly.
            let x = CGFloat(sq.file) * side
            let y = CGFloat(7 - sq.rank) * side
            view.frame = CGRect(x: x, y: y, width: side, height: side)
            view.pieceLabel.font = .systemFont(ofSize: side * 0.68)
        }
    }

    // MARK: - Public API

    public func setBoard(_ board: Board, lastMove: Move?, animated: Bool = false) {
        self.board = board
        self.lastMove = lastMove
        selectedSquare = nil
        highlightedTargets = []
        refresh(animated: animated)
    }

    public func clearSelection() {
        selectedSquare = nil
        highlightedTargets = []
        refresh()
    }

    // MARK: - Interaction

    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        guard let squareView = gr.view as? SquareView else { return }
        handleSelection(at: squareView.square)
    }

    private func handleSelection(at square: Square) {
        // If we already had a selection and this tap lands on a target → make the move.
        if let from = selectedSquare {
            let moves = delegate?.boardView(self, legalMovesFrom: from) ?? []
            let promotions = moves.filter { $0.to == square && $0.promotion != nil }
            if !promotions.isEmpty,
               delegate?.boardViewShouldPromptForPromotion(self) == true {
                presentPromotionChooser(for: promotions)
                return
            }
            if let move = moves.first(where: { $0.to == square && $0.promotion == nil }) {
                delegate?.boardView(self, didSelect: move)
                return
            }
            if !promotions.isEmpty, let first = promotions.first {
                delegate?.boardView(self, didSelect: first)
                return
            }
        }
        // Otherwise try to select this square (must have a piece of the side to move).
        if let piece = board[square], piece.color == board.sideToMove {
            selectedSquare = square
            let moves = delegate?.boardView(self, legalMovesFrom: square) ?? []
            highlightedTargets = Set(moves.map { $0.to })
        } else {
            selectedSquare = nil
            highlightedTargets = []
        }
        refresh()
    }

    private func presentPromotionChooser(for moves: [Move]) {
        let alert = UIAlertController(title: "Перетворення пішака",
                                      message: "Обери фігуру",
                                      preferredStyle: .actionSheet)
        let kinds: [(String, PieceKind)] = [
            ("Ферзь ♛", .queen), ("Тура ♜", .rook),
            ("Слон ♝", .bishop), ("Кінь ♞", .knight)
        ]
        for (title, kind) in kinds {
            guard let move = moves.first(where: { $0.promotion == kind }) else { continue }
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.delegate?.boardView(self, didSelect: move)
            })
        }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        if let root = self.window?.rootViewController {
            (root.presentedViewController ?? root).present(alert, animated: true)
        }
    }

    // MARK: - Rendering

    private func refresh(animated: Bool = false) {
        let apply = {
            for view in self.squareViews {
                view.render(piece: self.board[view.square],
                            isLight: (view.square.file + view.square.rank).isMultiple(of: 2) == false,
                            isSelected: view.square == self.selectedSquare,
                            isHighlightedTarget: self.highlightedTargets.contains(view.square),
                            isLastMove: view.square == self.lastMove?.from || view.square == self.lastMove?.to)
            }
        }
        if animated {
            UIView.transition(with: self, duration: 0.12, options: [.beginFromCurrentState, .allowUserInteraction],
                              animations: apply)
        } else {
            apply()
        }
    }
}

private final class SquareView: UIView {

    let square: Square
    let pieceLabel = UILabel()
    private let dot = UIView()

    init(square: Square) {
        self.square = square
        super.init(frame: .zero)
        addSubview(pieceLabel)
        pieceLabel.textAlignment = .center
        pieceLabel.snp.makeConstraints { make in make.edges.equalToSuperview() }

        addSubview(dot)
        dot.backgroundColor = Theme.color(\.acc)
        dot.layer.cornerRadius = 5
        dot.alpha = 0.55
        dot.isHidden = true
        dot.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(10)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(piece: Piece?,
                isLight: Bool,
                isSelected: Bool,
                isHighlightedTarget: Bool,
                isLastMove: Bool) {
        // Base color
        let baseColor: UIColor
        if isLastMove {
            baseColor = isLight ? Theme.color(\.lmLight) : Theme.color(\.lmDark)
        } else {
            baseColor = isLight ? Theme.color(\.sqLight) : Theme.color(\.sqDark)
        }
        backgroundColor = baseColor
        if isSelected {
            backgroundColor = Theme.color(\.hl)
            layer.borderColor = Theme.color(\.acc).cgColor
            layer.borderWidth = 2
        } else {
            layer.borderWidth = 0
        }

        pieceLabel.text = piece?.glyph
        pieceLabel.textColor = (piece?.color == .white)
            ? UIColor(white: 1.0, alpha: 1)
            : UIColor(white: 0.08, alpha: 1)

        dot.isHidden = !isHighlightedTarget || piece != nil
        // If the target square contains an enemy piece, show a ring instead.
        if isHighlightedTarget && piece != nil {
            layer.borderWidth = 2
            layer.borderColor = Theme.color(\.acc).cgColor
        }
    }
}
