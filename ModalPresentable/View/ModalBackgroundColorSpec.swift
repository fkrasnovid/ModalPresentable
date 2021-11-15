/// Возможные конфигурации цвета
public enum ModalBackgroundColorSpec {
	/// Конфигурация с цветом
    case color(UIColor)
	/// Конфигурация со стилем блюра
    case blur(UIBlurEffect.Style)
	/// Конфигурация с прозрачностью
    case clear
}
