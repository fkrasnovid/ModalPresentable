/// Основной интерфейс конфигурации представления
public protocol ModalPresentable: AnyObject {
	/// Скроллвью для перехвата делегата и валидной работы скролла
	/// - Значение по умолчанию: nil
    var panScrollable: UIScrollView? { get }

    /// Контроллер для проксирования юзер эвентов
	/// - Значение по умолчанию: nil
    var panProxy: UIViewController? { get }

    /// Оффсет между верхом экрана и верхом модального контейнера
	/// - Значение по умолчанию: topLayoutGuide.length + 21.0
    var topOffset: CGFloat { get }

    /// Высота модального контейнера "свернутого" состояния
	/// - Примечание: Значение имеет ограничение .max, если превышается допустимое значение
	/// - Значение по умолчанию: longFormHeight
    var shortFormHeight: ModalHeight { get }

    /// Высота модального контейнера "развернутого" состояния
	/// - Примечание: Значение имеет ограничение .max, если превышается допустимое значение
	/// - Значение по умолчанию: .max
    var longFormHeight: ModalHeight { get }

    /// Закругление углов, используется если shouldRoundTopCorners = true
	/// - Значение по умолчанию: 16.0
    var cornerRadius: CGFloat { get }

    /// Значение демпфера при переключении свернутого/развернутого состояния
	/// - Значение по умолчанию: 0.8
    var springDamping: CGFloat { get }

    /// Значение скорости анимации проявления представления, включая первоначальное появление
	/// - Значение по умолчанию: 0.5
    var transitionDuration: Double { get }

    /// Параметры используемые при выполнении анимаций, переходов
	/// - Значение по умолчанию: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    var transitionAnimationOptions: UIView.AnimationOptions { get }

    /// Настройка цвета фона за модальным представлением
	/// - Примечание: Используется в самом начале перехода
	/// - Значение по умолчанию: .color(UIColor.black.withAlphaComponent(0.7))
    var modalBackgroundColor: ModalBackgroundColorSpec { get }

    /// Кастомные scrollIndicatorInsets
	/// - Примечание: Чтобы обновить insets необходимо вызвать modalSetNeedsLayoutUpdate()
	/// - Значение по умолчанию:
	/// let top = shouldRoundTopCorners ? cornerRadius : 0
	/// return UIEdgeInsets(top: CGFloat(top), left: 0, bottom: bottomLayoutOffset, right: 0)
    var scrollIndicatorInsets: UIEdgeInsets { get }

	/// Флаг определяет должен ли скроллинг быть ограничен longFormHeight
	/// - Примечание: return false скроллинг ограничивается высотой .max
	/// - Значение по умолчанию: true
    var anchorModalToLongForm: Bool { get }

    /// Флаг определяет должен ли скроллинг плавно переходит от модального представления в полноэкранный
	/// если скролл-лимит был достигнут
	/// - Значение по умолчанию: false, если scrollView = nil и высота содержимого не превышает высоту longForm
    var allowsExtendedScrolling: Bool { get }

    /// Флаг определяет разрешение swipe to dismiss для текущего представления
	/// - Примечание: return false для возврата в состояние shortForm вместо dismiss
	/// - Значение по умолчанию: true
    var allowsDragToDismiss: Bool { get }

    /// Флаг определяет разрешение tap to dissmiss по затемненной области представления
	/// - Значение по умолчанию: true
    var allowsTapToDismiss: Bool { get }

    /// Флаг определяет разрешение возвращаться в свернутую форму
	/// - Значение по умолчанию: false
    var allowsRepeatShortForm: Bool { get }

    /// Флаг определяет разрешение юзер эвентов в контейнере представления
	/// - Примечание: return false для форварда всех эвентов в presentingViewController
	/// - Значение по умолчанию: true
    var isUserInteractionEnabled: Bool { get }

    /// Флаг определяет разрешение использование вибрации при презентации представления
	/// - Значение по умолчанию: true
    var isHapticFeedbackEnabled: Bool { get }

    /// Флаг определяет разрешение перспективы представления
	/// - Значение по умолчанию: false
    var isUserPerspectiveEnabled: Bool { get }

    /// Флаг определяет разрешение использовать закругление верхних углов представления
	/// - Значение по умолчанию: true
    var shouldRoundTopCorners: Bool { get }

	/// Флаг определяет разрешение добавлять тени верхних углов представления
	/// - Значение по умолчанию: true
    var shouldShadowTopCorners: Bool { get }

    /// Флаг определяет должен ли быть отображен индикатор скролла на модальном представлении
	/// - Значение по умолчанию: true
    var showDragIndicator: Bool { get }

    /// Модель драг индикатора
	/// - Значение по умолчанию: DragIndicatorModel.defaultModel
    var dragIndicatorModel: DragIndicatorModel { get }

	/// Контейнер, который следует за модальным представлением
	/// - Значение по умолчанию: nil
	var contentContainer: ModalContentContainer? { get }

    /// Должно ли модальное представление реагировать на UIPanGestureRecognizer
	/// - Значение по умолчанию: true
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool

    /// Уведомляет когда состояние жеста поменялось на began или changed
	/// - Примечание: Этот метод дает делегату возможность подготовиться для изменения состояния представления
	/// - Реализация по умолчанию не предусмотрена
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer)

    /// Спрашивает должны ли жесты быть приоритизированы
	/// - Примечание: Можно определить место откуда начался жест
	/// 	если false, мы опираемся на реализацию UIKit'a со всеми вытекающими ¯\_(ツ)_/¯
	///  - Значение по умолчанию: false
    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool

    /// Спрашивает, должно ли представление перейти в новое состояние
	/// - Значение по умолчанию: true
    func shouldTransition(to state: PresentationState) -> Bool

    /// Уведомляет о том, что предсталение собирается перейти в новое состояние
	/// - Реализация по умолчанию не предусмотрена
    func willTransition(to state: PresentationState)

    /// Уведомляет о том, что представление будет dismissed
	/// - Реализация по умолчанию не предусмотрена
    func modalWillDismiss()

    /// Уведомляет после того как представление dismissed
	/// - Реализация по умолчанию не предусмотрена
    func modalDidDismiss()

	/// Уведомление о изменении Y позиции
	///
	/// - Note: Реализация по умолчанию не предусмотрена
	///
	/// - Parameter yPos: текущее значение Y
	func modalNoticeChangeYOffset(yState: StateY)
}
