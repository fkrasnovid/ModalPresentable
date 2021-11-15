/**
	ModalPresentationController - это средний уровень между presentingViewController и presentedViewController

	Он контролирует координацию между отдельными переходами, а также
	обеспечивает абстракцию того, как представление представлено и отображено

	Конфигурация и лаяут представления определяются протоколом ModalPresentable
	В соответствии с протоколом ModalPresentable представление определяет свою конфигурацию
 */
class ModalPresentationController: UIPresentationController {

    // MARK: - Constants

    struct Constants {
        static let snapMovementSensitivity = CGFloat(0.7)
        static let maxEyePerspective = CGFloat(-1 / 15.0)
		static let contentContainerOffset = CGFloat(10.0)
		static let contentContainerDisplacement = CGFloat(300.0)
		static let maxYdisplacementLimit: CGFloat = 15.0
    }

    // MARK: - Private property

    /// Флаг отслеживания анимации представления
    private var isPresentedViewAnimating = false

    /**
		Флаг опледеляющий должен ли скроллинг плавно
		переходить из модального представления как только будет превышен лимит скролла
     */
    private var extendsPanScrolling = true

    /**
		Флаг для определения того, следует ли ограничивать скроллинг longFormHeight
		return false, чтобы ограничение скролла было .max высотой
     */
    private var anchorModalToLongForm = true

    /// Y content offset представления
    private var scrollViewYOffset: CGFloat = 0.0

    /// Наблюдатель для смещения содержимого Scrollview
    private var scrollObserver: NSKeyValueObservation?

    /// Значение Y для состояния представления свернутого состояния
    private var shortFormYPosition: CGFloat = 0

    /// Значение Y для состояния представления развернутого состояния
    private var longFormYPosition: CGFloat = 0

    /// Последнее значение Y для состояния представления
    private var lastFormYPosition: CGFloat = 0

    /// Значение Y для состояния представления формы при отображении клавиатуры
    private var keyboardShownYPosition: CGFloat?

    /// Оффсет клавиатуры
    private var keyboardOffset: CGFloat?

    /// Значение bottom content inset когда клавиатура не отображается
    private var standardOffset: CGFloat?

    /// Значение дополнительного паддинга, когда отображается клавиатура
    private var keyboardPadding: CGFloat = 20.0

    /// Положение якоря Y на основе anchorModalToLongForm
    private var anchoredYPosition: CGFloat {
        let defaultTopOffset = presentable?.topOffset ?? 0
        return anchorModalToLongForm ? longFormYPosition : defaultTopOffset
    }

    /// Вычисление на максимальной ли высоте представление
    private var scrollToMax: Bool {
        return longFormYPosition >= presentedView.frame.origin.y
    }

    /// Объект конфигурации для ModalPresentationController
    private var presentable: ModalPresentable? {
        return presentedViewController as? ModalPresentable
    }

    /// Перспектива представления свернутого состояния
    private var shortFormPerspective: CATransform3D {
        var contentTransform: CATransform3D = CATransform3DIdentity
        contentTransform.m34 = 0.0
        return CATransform3DTranslate(contentTransform, 0, 0, -2)
    }

    /// Перспектива представления развернутого состояния
    private var longFormPerspective: CATransform3D {
        var contentTransform: CATransform3D = CATransform3DIdentity
        contentTransform.m34 = Constants.maxEyePerspective
        return CATransform3DTranslate(contentTransform, 0, 0, -2)
    }

	/// Флаг определяет привязанно ли представление
    var isPresentedViewAnchored: Bool {
        if !isPresentedViewAnimating
            && extendsPanScrolling
            && presentedView.frame.minY.rounded() <= anchoredYPosition.rounded() {
            return true
        }
        return false
    }

    // MARK: - Views

    /// BackgroundView-оверлей на представлении
    private lazy var backgroundView: DimmedView = {
		let view = buildDimmedView()
        view.didTapHandler = { [weak self] in
            if self?.presentable?.allowsTapToDismiss == true {
                self?.presentedViewController.dismiss(animated: true)
            }
        }
        return view
    }()

    /// Враппер представления для возможности омниканальных модификаций
    private lazy var panContainerView: PanContainerView = {
        let frame = containerView?.frame ?? .zero
        let container = PanContainerView(presentedView: presentedViewController.view, frame: frame)
        container.setProxyView(presentable?.panProxy?.view)
        return container
    }()

    /// Вью индикатора скролла
    private lazy var dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = presentable?.dragIndicatorModel.color
        view.layer.cornerRadius = presentable?.dragIndicatorModel.cornerRadius ?? 0.0
        return view
    }()

	/// Интерактивный контейнер над представлением
    private lazy var contentContainer: ModalContentContainer? = {
		return presentable?.contentContainer
    }()

	/// Интерактивный контейнер над представлением
    private lazy var shadowContainer: UIView = {
		let view = UIView(
			frame: CGRect(x: 0.0, y: 1000.0, width: UIScreen.main.bounds.size.width, height: 10.0)
		)
		return view
    }()

    /// Переопределенное свойство, чтобы вернуть враппер
    override var presentedView: UIView {
        return panContainerView
    }

    /// Вью с которого показано представление
    private lazy var presentingView: UIView = {
        return presentingViewController.view
    }()

    // MARK: - Gesture Recognizers

    /// Жест скролла
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(didPanOnPresentedView(_ :)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        return gesture
    }()

    // MARK: - Deinit

    deinit {
        scrollObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle override

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        configureViewLayout()
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        layoutBackgroundView(in: containerView)
        layoutPresentedView(in: containerView)
		layoutButtonContainer()
        configureScrollViewInsets()

        guard let coordinator = presentedViewController.transitionCoordinator else {
            backgroundView.dimState = .max
            return
        }

		coordinator.animate(alongsideTransition: { _ in
			self.presentable?.modalNoticeChangeYOffset(yState: .force(self.lastFormYPosition))
			self.backgroundView.dimState = .max
			self.contentContainer?.alpha = 1.0
			self.layoutShadowContainer()
            self.makePerspectiveRoundedCorner()
			self.presentedViewController.setNeedsStatusBarAppearanceUpdate()
            self.presentedViewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
		})
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
		if completed { return }
		backgroundView.removeFromSuperview()
    }

    override func dismissalTransitionWillBegin() {
        presentable?.modalWillDismiss()

        guard let coordinator = presentedViewController.transitionCoordinator else {
            backgroundView.dimState = .off
			restorePerspective()
            return
        }

        /// Драг индикатор может отображаться за границами, прячем, чтобы избежать визульных артефактов с ним
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.dragIndicatorView.alpha = 0.0
			self?.contentContainer?.alpha = 0.0
            self?.backgroundView.dimState = .off
			self?.shadowContainer.removeFromSuperview()
            self?.restorePerspective()
            self?.presentingViewController.setNeedsStatusBarAppearanceUpdate()
			self?.presentingViewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
		if !completed { return }
		/// Принудительное возвращение перспективы из-за возможных эвентовых коллизий
		restorePerspective()
		presentable?.modalDidDismiss()
	}

    /// Обновление размера представления
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self, let presentable = self.presentable else { return }

            self.adjustPresentedViewFrame()
            if presentable.shouldRoundTopCorners {
                self.addRoundedCorners(to: self.presentedView)
            }
        })
    }
}

// MARK: - Public Methods

extension ModalPresentationController {

    /// Переход к состоянию
    func transition(to state: PresentationState, animationBlock: (() -> Void)? = nil, completionBlock: (() -> Void)? = nil) {
		if presentable?.shouldTransition(to: .longForm) == false && presentable?.shouldTransition(to: .shortForm) == false {
			assertionFailure("shouldTransition не может возвращать false для двух состояний!")
		}
		guard presentable?.shouldTransition(to: state) == true else {
			transition(to: state == .longForm ? .shortForm : .longForm, animationBlock: animationBlock, completionBlock: completionBlock)
			return
		}
        presentable?.willTransition(to: state)

        switch state {
        case .shortForm:
            snap(toYPosition: shortFormYPosition, animationBlock: animationBlock, completionBlock: completionBlock)
        case .longForm:
            snap(toYPosition: longFormYPosition, animationBlock: animationBlock, completionBlock: completionBlock)
        }
    }

    /// Обновление с отключенным обзервом скролла
    func performUpdates(_ updates: () -> Void) {
        guard let scrollView = presentable?.panScrollable else { return }

        // Остановка скролл обзерва
        scrollObserver?.invalidate()
        scrollObserver = nil

        // Выполнение обновлений
        updates()

        // Восстановление скролл обзерва
        trackScrolling(scrollView)
        observe(scrollView: scrollView)
    }

    /// Обновление лаяута основанное на значениях в ModalPresentable протоколе
    func setNeedsLayoutUpdate() {
        configureViewLayout()
        adjustPresentedViewFrame()
        observe(scrollView: presentable?.panScrollable)
        configureScrollViewInsets()
    }

    /// Наблюдение за клавиатурой
    func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }
}

// MARK: - Presented View Layout Configuration

private extension ModalPresentationController {

    /// Добавление представления в контейнер
    func layoutPresentedView(in containerView: UIView) {
        guard let presentable = presentable else { return }

        containerView.addSubview(presentedView)
        containerView.addGestureRecognizer(panGestureRecognizer)

        if presentable.showDragIndicator {
            addDragIndicatorView(to: presentedView)
        }
        if presentable.shouldRoundTopCorners {
            addRoundedCorners(to: presentedView)
        }

        setNeedsLayoutUpdate()
        adjustPanContainerBackgroundColor()
    }

    /// Редуцируем высоту presentedView чтобы она была снизу экрана
    func adjustPresentedViewFrame() {
        guard let frame = containerView?.frame else { return }

        let adjustedSize = CGSize(width: frame.size.width, height: frame.size.height - anchoredYPosition)
        let panFrame = panContainerView.frame
        panContainerView.frame.size = frame.size

        if ![shortFormYPosition, longFormYPosition].contains(panFrame.origin.y) {
            // Если контейнер в валидной позиции, нет необходимости корректировать позицию
            // Возможны некоторые рассинхронизирования в позиции
            let yPosition = panFrame.origin.y - panFrame.height + frame.height
            presentedView.frame.origin.y = max(yPosition, anchoredYPosition)
        }
        panContainerView.frame.origin.x = frame.origin.x
        presentedViewController.view.frame = CGRect(origin: .zero, size: adjustedSize)
    }

    /// Добавление цвета в контейнер чтобы избежать пробела внизу во время превоначального проявления
    func adjustPanContainerBackgroundColor() {
        panContainerView.backgroundColor = presentedViewController.view.backgroundColor
            ?? presentable?.panScrollable?.backgroundColor
    }

    /// Добавление бекраунд вью
    func layoutBackgroundView(in containerView: UIView) {
		containerView.addSubview(backgroundView)
		backgroundView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor),
			backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		])
    }

	/// Добавление контейнера с кнопками
    func layoutButtonContainer() {
		guard let contentContainer = contentContainer else { return }
		contentContainer.alpha = 0.0
        backgroundView.addSubview(contentContainer)
		adjustContentContainer(toYPosition: lastFormYPosition)
    }

	/// Добавление контейнера с тенью
    func layoutShadowContainer() {
		guard presentable?.shouldShadowTopCorners == true else { return }
        backgroundView.addSubview(shadowContainer)
		shadowContainer.layer.shadowColor = UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 0.16).cgColor
		shadowContainer.layer.shadowRadius = 20
		shadowContainer.layer.shadowOpacity = 1.0
		shadowContainer.layer.shadowPath = roundPath.cgPath
		shadowContainer.layer.shouldRasterize = true
		shadowContainer.layer.rasterizationScale = UIScreen.main.scale
		adjustShadowContainer(toYPosition: lastFormYPosition)
    }

    /// Добавление драг индикатора
    func addDragIndicatorView(to view: UIView) {
		guard let model = presentable?.dragIndicatorModel else { assertionFailure("presentable == nil"); return }

		view.addSubview(dragIndicatorView)
		dragIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        switch model.position {
        case .onView:
			NSLayoutConstraint.activate([
				dragIndicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: model.offset)
			])

        case .overView:
			NSLayoutConstraint.activate([
				view.bottomAnchor.constraint(equalTo: dragIndicatorView.bottomAnchor, constant: model.offset)
			])
        }

		NSLayoutConstraint.activate([
			dragIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			dragIndicatorView.widthAnchor.constraint(equalToConstant: model.width),
			dragIndicatorView.heightAnchor.constraint(equalToConstant: model.height)
		])
    }

    /// Рассчитывание и сохранение точек привязки
    func configureViewLayout() {
        guard let layoutPresentable = presentedViewController as? ModalPresentable.LayoutType else { return }

        shortFormYPosition = layoutPresentable.shortFormYPos
        longFormYPosition = layoutPresentable.longFormYPos
        anchorModalToLongForm = layoutPresentable.anchorModalToLongForm
        extendsPanScrolling = layoutPresentable.allowsExtendedScrolling
        lastFormYPosition = shortFormYPosition

        containerView?.isUserInteractionEnabled = layoutPresentable.isUserInteractionEnabled
    }

    /// Настройка scrollView insets
    func configureScrollViewInsets() {
        guard let scrollView = presentable?.panScrollable, !scrollView.isScrolling else { return }

        /// Выключение вертикального индикатора до старта скролла (Избегаем артефакты)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollIndicatorInsets = presentable?.scrollIndicatorInsets ?? .zero

        /// Установка подходящего contentInset
		scrollView.contentInset.bottom = presentingViewController.view.safeAreaInsets.bottom

        /// Из-за ручной корректировки handleScrollViewTopBounce
        scrollView.contentInsetAdjustmentBehavior = .never
    }
}

// MARK: - Pan Gesture Event Handler

private extension ModalPresentationController {
    /// Обязательная функция для обработки жестов
    @objc
    func didPanOnPresentedView(_ recognizer: UIPanGestureRecognizer) {
        guard
            shouldRespond(to: recognizer),
            let containerView = containerView
        else {
            recognizer.setTranslation(.zero, in: recognizer.view)
            return
        }

        switch recognizer.state {
        case .began, .changed:

            respond(to: recognizer)

            /// Отображем перспективу
            makePerspective(toYPosition: presentedView.frame.origin.y)

			/// Обработка позиции конейнера
			adjustContentContainer(toYPosition: presentedView.frame.origin.y)

            /// Если представление выходит за longForm лимит - рассматривается как переход состояния
            if presentedView.frame.origin.y == anchoredYPosition && extendsPanScrolling {
                presentable?.willTransition(to: .longForm)
            }

        default:
            /// Использование сенсы чтобы ограничить привязку
            let velocity = recognizer.velocity(in: presentedView)

            if isVelocityWithinSensitivityRange(velocity.y) {

                /// Если сенса находится в допустимом диапазоне - переход состояния
				if velocity.y < 0 {
                    transition(to: .longForm)

                } else if (nearest(
                    to: presentedView.frame.minY,
                    inValues: [longFormYPosition, containerView.bounds.height]) == longFormYPosition
                    && presentedView.frame.minY < shortFormYPosition)
                    && presentable?.allowsRepeatShortForm == true
                    || presentable?.allowsDragToDismiss == false {
                    transition(to: .shortForm)

                } else {
                    presentedViewController.dismiss(animated: true)
                }

            } else {
                /// Использование containerView.bounds.height
                /// чтобы определить насколько близко к низу экрана находится представление
                let position = nearest(
                    to: presentedView.frame.minY,
                    inValues: [containerView.bounds.height, shortFormYPosition, longFormYPosition]
                )

                if position == longFormYPosition {
                    transition(to: .longForm)

                } else if position == shortFormYPosition
                    && lastFormYPosition == shortFormYPosition
                    || presentable?.allowsRepeatShortForm == true  {
                    transition(to: .shortForm)

                } else if position == shortFormYPosition
                    && presentable?.allowsDragToDismiss == false
                    && presentable?.allowsRepeatShortForm == true {
                    transition(to: .shortForm)

                } else if presentable?.allowsDragToDismiss == false {
                    /// Тот случай, когда довели контроллера до самого низа
                    transition(to: .shortForm)
                } else {
                    presentedViewController.dismiss(animated: true)
                }
            }
        }
    }

    /**
		Определяет, должно ли представление реагировать на жесты

		Если представление уже перетаскивают и делегат return false,
		игнорируем до перехода в статус .began

		- Примечание: Это единственный раз, когда отменяется режим распознавания жестов
     */
    func shouldRespond(to panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard
            presentable?.shouldRespond(to: panGestureRecognizer) == true ||
                !(panGestureRecognizer.state == .began || panGestureRecognizer.state == .cancelled)
        else {
            panGestureRecognizer.isEnabled = false
            panGestureRecognizer.isEnabled = true
            return false
        }
        return !shouldFail(panGestureRecognizer: panGestureRecognizer)
    }

    func respond(to panGestureRecognizer: UIPanGestureRecognizer) {
        presentable?.willRespond(to: panGestureRecognizer)

		if presentedView.frame.origin.y
			< shortFormYPosition - Constants.maxYdisplacementLimit
			&& presentable?.shouldTransition(to: .longForm) == false
		{ return }

        var yDisplacement = panGestureRecognizer.translation(in: presentedView).y

        /// Если presentedView не призяванна к развернутому состоянию, уменьшаем рейт до лимита
        if presentedView.frame.origin.y < longFormYPosition {
            yDisplacement /= 2.0
        }

        adjust(toYPosition: presentedView.frame.origin.y + yDisplacement)

        panGestureRecognizer.setTranslation(.zero, in: presentedView)
    }

    /**
		Определяет, следует ли отказывать в распознавателе жестов на основании определенных условий

		Мы не можем выполнить распознавание жестов представления, если мы активно скроллим в scrollView
		Это позволяет пользователю перетаскивать весь контроллер вида из области касания scrollView
     */
    func shouldFail(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        /**
			Разрешить пользователям API отменять внутренние условия и
			решить, должен ли распознаватель жестов иметь приоритет

			Это единственный раз, когда отменяется распознаватель panScrollable,
			с целью убедиться, что мы больше не отслеживаем scrollView
         */
        guard !shouldPrioritize(panGestureRecognizer: panGestureRecognizer) else {
            presentable?.panScrollable?.panGestureRecognizer.isEnabled = false
            presentable?.panScrollable?.panGestureRecognizer.isEnabled = true
            return false
        }

        guard
            isPresentedViewAnchored,
            let scrollView = presentable?.panScrollable,
            scrollView.contentOffset.y > 0
        else { return false }

        let loc = panGestureRecognizer.location(in: presentedView)
        return (scrollView.frame.contains(loc) || scrollView.isScrolling)
    }

    /**
		Определяет, должен ли panGestureRecognizer представления иметь
		приоритет над встроенным scrollView panGestureRecognizer
     */
    func shouldPrioritize(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return panGestureRecognizer.state == .began &&
            presentable?.shouldPrioritize(panModalGestureRecognizer: panGestureRecognizer) == true
    }

    /// Проверка сенсы на допустимый диапазон
    func isVelocityWithinSensitivityRange(_ velocity: CGFloat) -> Bool {
        return (abs(velocity) - (1000 * (1 - Constants.snapMovementSensitivity))) > 0
    }

    func snap(toYPosition yPos: CGFloat, animationBlock: (() -> Void)? = nil, completionBlock: (() -> Void)? = nil) {
        lastFormYPosition = yPos
        ModalAnimator.animate(config: presentable, animations: { [weak self] in
			self?.isPresentedViewAnimating = true
            self?.adjust(toYPosition: yPos)
            self?.adjustPerspective(toYPosition: yPos)
            animationBlock?()
        }, completion: { [weak self] didComplete in
            completionBlock?()
            self?.isPresentedViewAnimating = !didComplete
        })
    }

    /// Устанавливает положение Y presentedView и настраивает backgroundView
    func adjust(toYPosition yPos: CGFloat) {

		presentedView.frame.origin.y = max(yPos, anchoredYPosition - Constants.maxYdisplacementLimit)

		adjustContentContainer(toYPosition: presentedView.frame.origin.y)
		adjustShadowContainer(toYPosition: presentedView.frame.origin.y)
		presentable?.modalNoticeChangeYOffset(yState: isPresentedViewAnimating ? .force(yPos) : .pan(yPos))
        guard presentedView.frame.origin.y > shortFormYPosition && presentable?.allowsDragToDismiss == true else {
            backgroundView.dimState = .max
            return
        }

        let yDisplacementFromShortForm = presentedView.frame.origin.y - shortFormYPosition

        /// Расчет процента затемнения на основе Y позиции
        backgroundView.dimState = .percent(1.0 - (yDisplacementFromShortForm / presentedView.frame.height))
    }

	/// Устанавливает положение Y buttonContainer
    func adjustContentContainer(toYPosition yPos: CGFloat) {
		guard
			let contentContainer = contentContainer,
			yPos > Constants.contentContainerDisplacement
		else { return }

		contentContainer.frame.origin.y =
			max(yPos, anchoredYPosition) - contentContainer.frame.size.height - Constants.contentContainerOffset
    }

	/// Устанавливает положение Y shadowContainer
    func adjustShadowContainer(toYPosition yPos: CGFloat) {
		guard presentable?.shouldShadowTopCorners == true else { return }
		shadowContainer.frame.origin.y = yPos
    }

    /// Находит ближайшее значение к данному числу из данного массива значений с плавающей запятой
    func nearest(to number: CGFloat, inValues values: [CGFloat]) -> CGFloat {
        guard let nearestVal = values.min(by: { abs(number - $0) < abs(number - $1) }) else { return number }
        return nearestVal
    }
}

// MARK: - User perspective

private extension ModalPresentationController {
    /// Устанавливает закругленные клая для перспективы
    func makePerspectiveRoundedCorner() {
        guard presentable?.isUserPerspectiveEnabled == true else { return }

        addRoundedCorners(to: presentingView)
        adjustPerspective(toYPosition: lastFormYPosition)
    }

    /// Устанавливает перспективу
    func adjustPerspective(toYPosition yPos: CGFloat?) {
        guard
            presentable?.isUserPerspectiveEnabled == true,
            let yPos = yPos
        else { return }
        var transform: CATransform3D!

        if yPos == longFormYPosition && longFormYPosition != shortFormYPosition {
            transform = longFormPerspective
        } else {
            transform = shortFormPerspective
        }

        presentingView.layer.transform = transform
    }

    /// Устанавливает перспективу на основании Y
    func makePerspective(toYPosition yPos: CGFloat) {
        guard presentable?.isUserPerspectiveEnabled == true else { return }

        let middle = (UIScreen.main.bounds.height - longFormYPosition) / 2.0
        guard yPos <= middle else { return }

        let magicEye: CGFloat =
            Constants.maxEyePerspective
            - (Constants.maxEyePerspective / (middle - longFormYPosition))
                * (yPos - longFormYPosition)

		// TODO: - Обновление стиля статус бара на основании перспективы magicEye

        var contentTransform: CATransform3D = CATransform3DIdentity
        contentTransform.m34 = magicEye
        contentTransform = CATransform3DTranslate(contentTransform, 0, 0, -2)

        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveLinear], animations: {
            self.presentingView.layer.transform = contentTransform
        })
    }

    /// Возвращаем перспективу в исходное состояние
    func restorePerspective() {
        guard presentable?.isUserPerspectiveEnabled == true else { return }
        presentingView.layer.transform = shortFormPerspective
    }
}

// MARK: - UIScrollView Observer

private extension ModalPresentationController {
    /**
		Создает и сохраняет наблюдателя scrollView
		Позволяет отслеживать прокрутку без переопределения делегата scrollView
     */
    func observe(scrollView: UIScrollView?) {
        scrollObserver?.invalidate()

        scrollObserver = scrollView?.observe(\.contentOffset, options: .old) { [weak self] scrollView, change in
			guard let self = self else { return }
            /// Если есть два контейнера в одном и том же представлении
            guard self.containerView != nil else { return }
            self.didPanOnScrollView(scrollView, change: change)
        }
    }

    /**
		Обработчик изменения scrollView content offset'a
		Если scrollView прокручен до топа, отключаем скролл индикатор (обходим визуальный артефакт)
     */
    func didPanOnScrollView(_ scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        guard
            !presentedViewController.isBeingDismissed,
            !presentedViewController.isBeingPresented
        else { return }

        if !isPresentedViewAnchored && scrollView.contentOffset.y > 0 {
            /// Удерживаем scrollView на месте, если активно прокручиваем и не обрабатываем топ отскок
            haltScrolling(scrollView)

        } else if scrollView.isScrolling || isPresentedViewAnimating {
            if isPresentedViewAnchored {
                /// Пока не прокручиваем scrollView, сохраняем последний content offset
                trackScrolling(scrollView)
            } else {
                haltScrolling(scrollView)
            }

        } else if presentedViewController.view.isKind(of: UIScrollView.self)
            && !isPresentedViewAnimating && scrollView.contentOffset.y <= 0 {
            handleScrollViewTopBounce(scrollView: scrollView, change: change)
        } else {
            trackScrolling(scrollView)
        }
    }

    /// Останавливает прокрутку и закрепляет scrollViewYOffset
    func haltScrolling(_ scrollView: UIScrollView) {
		scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
		scrollView.showsVerticalScrollIndicator = false
    }

    /// Во время прокрутки отслеживает и сохраняет смещение
    func trackScrolling(_ scrollView: UIScrollView) {
        scrollViewYOffset = max(scrollView.contentOffset.y, 0)
        scrollView.showsVerticalScrollIndicator = true
    }

    /**
		Чтобы гарантировать переход между состояниями, обрабатываем отрицательное смещение
		Следуем кривой замедления прокрутки - дает эффект что это одно представление
     */
    func handleScrollViewTopBounce(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        guard let oldYValue = change.oldValue?.y, scrollView.isDecelerating else { return }

        let yOffset = scrollView.contentOffset.y
        let presentedSize = containerView?.frame.size ?? .zero

        presentedView.bounds.size = CGSize(width: presentedSize.width, height: presentedSize.height + yOffset)

        if oldYValue > yOffset {
            presentedView.frame.origin.y = longFormYPosition - yOffset
        } else {
            scrollViewYOffset = 0
            snap(toYPosition: longFormYPosition)
        }

        scrollView.showsVerticalScrollIndicator = false
    }
}

// MARK: - Keyboard Observer

private extension ModalPresentationController {
    @objc
    func keyboardWillShow(notification: Notification) {
        if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            if let scrollView = presentable?.panScrollable, scrollToMax {

                if standardOffset == nil && keyboardOffset == nil {
                    standardOffset = scrollView.contentInset.bottom
                    keyboardOffset = scrollView.contentInset.bottom + keyboardSize.height + keyboardPadding
                }

                var contentInset:UIEdgeInsets = scrollView.contentInset
                contentInset.bottom = keyboardOffset ?? 0
                scrollView.contentInset = contentInset
                scrollView.scrollIndicatorInsets = scrollView.contentInset
                return
            }

            if keyboardShownYPosition == nil {
                keyboardShownYPosition = presentedView.frame.origin.y - keyboardSize.height
            }

            guard let keyboardShownYPosition = keyboardShownYPosition else { return }
            shortFormYPosition = keyboardShownYPosition
            longFormYPosition = keyboardShownYPosition
            snap(toYPosition: keyboardShownYPosition)
        }
    }

    @objc
    func keyboardWillHide(notification: Notification) {
        keyboardShownYPosition = nil

        guard let layoutPresentable = presentedViewController as? ModalPresentable.LayoutType else { return }

        shortFormYPosition = layoutPresentable.shortFormYPos
        longFormYPosition = layoutPresentable.longFormYPos

        if let scrollView = presentable?.panScrollable {
            scrollView.contentInset.bottom = standardOffset ?? 0
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }

        transition(to: .shortForm)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ModalPresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
		_ gestureRecognizer: UIGestureRecognizer,
		shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
	) -> Bool {
        return false
    }

    /// Разрешение одновременного распознования
    func gestureRecognizer(
		_ gestureRecognizer: UIGestureRecognizer,
		shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
	) -> Bool {
        return otherGestureRecognizer.view == presentable?.panScrollable
    }
}

// MARK: - UIBezierPath

private extension ModalPresentationController {

	var roundPath: UIBezierPath {
		return UIBezierPath(
            roundedRect: presentedView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: presentable?.cornerRadius ?? 0, height: presentable?.cornerRadius ?? 0)
        )
	}

    func addRoundedCorners(to view: UIView) {
		let mask = CAShapeLayer()
		mask.path = roundPath.cgPath
		view.layer.mask = mask
    }
}

//MARK: - DimmedViewBuild

private extension ModalPresentationController {
	func buildDimmedView() -> DimmedView {
		guard let presentable = presentable else { return DimmedView(spec: .clear) }
		return DimmedView(spec: presentable.modalBackgroundColor)
	}
}
