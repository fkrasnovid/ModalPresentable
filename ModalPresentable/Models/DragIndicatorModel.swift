/// Модель драг-индикатора
public struct DragIndicatorModel {

    /// Позиция индикатора
    public enum IndicatorPosition {
        case overView
        case onView
    }

    let offset: CGFloat
    let height: CGFloat
    let width: CGFloat
    let color: UIColor
    let position: IndicatorPosition

    var cornerRadius: CGFloat {
        return height / 2.0
    }

	/// Инициализатор модели с параметрами
	/// - Parameters:
	///   - offset: оффсет
	///   - height: высота
	///   - width: ширина
	///   - color: цвет
	///   - position: позиция
	public init(
		offset: CGFloat,
		height: CGFloat,
		width: CGFloat,
		color: UIColor,
		position: IndicatorPosition
	) {
		self.offset = offset
		self.height = height
		self.width = width
		self.color = color
		self.position = position
	}
}
