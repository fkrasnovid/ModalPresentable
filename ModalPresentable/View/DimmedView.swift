/// Вью для оверлея, затемнения etc.
class DimmedView: UIView {
    /// Возможные состояния затемненного вида, работает в паре c ModalBackgroundColorSpec.color и ModalBackgroundColorSpec.blur
    enum DimState: Equatable {
        case max
        case off
        case percent(CGFloat)
    }

    // MARK: - Properties

    /// Состояние затемненного вида
    var dimState: DimState = .off {
        didSet { configureState(dimState) }
    }

    /// Хендлер, который будет вызван при нажатии
    var didTapHandler: (() -> Void)?

    /// Тап жест
    private lazy var tapGesture: UIGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(didTapView))
    }()

    /// Спецификация бекграунда
    private let backgroundSpec: ModalBackgroundColorSpec

    /// Эффектвью
    private var visualEffectView: UIVisualEffectView? = nil

    // MARK: - Initializers

    init(spec: ModalBackgroundColorSpec) {
        self.backgroundSpec = spec
        super.init(frame: .zero)
        self.configure()
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Используйте init(spec: ModalBackgroundColorSpec)")
    }
}

// MARK: - Configure

private extension DimmedView {
    func configure() {
        switch backgroundSpec {
        case let .blur(style):
            configureBlur(with: style)
        case let .color(color):
            alpha = 0.0
            backgroundColor = color
            addGestureRecognizer(tapGesture)
        case .clear:
            alpha = 0.0
            backgroundColor = .clear
            addGestureRecognizer(tapGesture)
        }
    }

    func configureBlur(with style: UIBlurEffect.Style) {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))

		addSubview(effectView)
		effectView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			effectView.topAnchor.constraint(equalTo: topAnchor),
			effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
			effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
			effectView.bottomAnchor.constraint(equalTo: bottomAnchor)
		])

        effectView.addGestureRecognizer(tapGesture)
        effectView.alpha = 0.0
        visualEffectView = effectView
    }

    func configureState(_ state: DimState) {
        switch dimState {
        case .max:
            alpha = 1.0
            visualEffectView?.alpha = 1.0
        case .off:
            alpha = 0.0
            visualEffectView?.alpha = 0.0
        case let .percent(percentage):
            let value = max(0.0, min(1.0, percentage))
            alpha = value
            visualEffectView?.alpha = value
        }
    }
}

// MARK: - Event Handlers

private extension DimmedView {
    @objc
    private func didTapView() {
        didTapHandler?()
    }
}
