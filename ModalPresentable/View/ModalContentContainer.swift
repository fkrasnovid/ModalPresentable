/// Контейнер который прилипает к модальному представлению
public final class ModalContentContainer: UIView {
	/// Инициализатор
	/// - Parameter height: высота контейнера
	public init(height: CGFloat) {
		super.init(frame: CGRect(
			x: 0.0,
			y: 1500.0, // Для первоначального проявления offscreen
			width: UIScreen.main.bounds.size.width,
			height: height
			)
		)
		self.backgroundColor = .clear
	}

	@available(*, unavailable)
	public override init(frame: CGRect) {
		fatalError("Используйте init(height: CGFloat)")
	}

	@available(*, unavailable)
	public init() {
		fatalError("Используйте init(height: CGFloat)")
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("Используйте init(height: CGFloat)")
	}
}
