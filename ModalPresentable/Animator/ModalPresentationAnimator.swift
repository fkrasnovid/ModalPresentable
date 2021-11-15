/// Сущность которая обрабатывает анимацию представления
class ModalPresentationAnimator: NSObject {

    // MARK: - Properties

    /// Стиль перехода
    private let transitionStyle: ModalTransitionStyle

    /// Генератор вибраций
	private lazy var feedbackGenerator: UISelectionFeedbackGenerator? = {
		let generator = UISelectionFeedbackGenerator()
		generator.prepare()
		return generator
	}()

    // MARK: - Initializers

    required init(transitionStyle: ModalTransitionStyle) {
        self.transitionStyle = transitionStyle
        super.init()
    }
}

// MARK: - UIViewControllerContextTransitioning

private extension ModalPresentationAnimator {
    /// Анимация проявления
    func animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from)
        else { return }

        let presentable = modalLayoutType(from: transitionContext)

        /// Вызывается viewWillAppear и viewWillDisappear
        fromVC.beginAppearanceTransition(false, animated: true)

        /// Изначально представление в свернутом состоянии
        let yPos: CGFloat = presentable?.shortFormYPos ?? 0.0

        /// Используем panView как presentingView, если уже существует в containerView
        let panView: UIView = transitionContext.containerView.panContainerView ?? toVC.view

        /// Перемещаем представление за экран (offscreen) - снизу
        panView.frame = transitionContext.finalFrame(for: toVC)
        panView.frame.origin.y = transitionContext.containerView.frame.height

        /// Вибрация
        if presentable?.isHapticFeedbackEnabled == true {
			feedbackGenerator?.selectionChanged()
        }

        ModalAnimator.animate(config: presentable, animations: {
            panView.frame.origin.y = yPos
        }, completion:{ [weak self] didComplete in
            /// Вызывается viewDidAppear и viewDidDisappear
            fromVC.endAppearanceTransition()
            transitionContext.completeTransition(didComplete)
            self?.feedbackGenerator = nil
        })
    }

    /// Анимация ухода с экрана
    func animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from)
        else { return }

        /// Вызывается viewWillAppear и viewWillDisappear
        toVC.beginAppearanceTransition(true, animated: true)

        let presentable = modalLayoutType(from: transitionContext)
        let panView: UIView = transitionContext.containerView.panContainerView ?? fromVC.view

        ModalAnimator.animate(config: presentable, animations: {
            panView.frame.origin.y = transitionContext.containerView.frame.height
        }, completion:{ didComplete in
            /// Вызывается viewDidAppear и viewDidDisappear
            toVC.endAppearanceTransition()
            transitionContext.completeTransition(didComplete)
        })
    }

    /// Если предсталение существует в контексте - извлекаем
    private func modalLayoutType(from context: UIViewControllerContextTransitioning) -> ModalPresentable.LayoutType? {
        switch transitionStyle {
        case .presentation:
            return context.viewController(forKey: .to) as? ModalPresentable.LayoutType
        case .dismissal:
            return context.viewController(forKey: .from) as? ModalPresentable.LayoutType
        }
    }
}

// MARK: - UIViewControllerAnimatedTransitioning Delegate

extension ModalPresentationAnimator: UIViewControllerAnimatedTransitioning {

    /// Возвращает продолжительность перехода
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let context = transitionContext,
            let presentable = modalLayoutType(from: context)
        else { return ModalAnimator.Constants.defaultTransitionDuration }
        return presentable.transitionDuration
    }

    /// Выполняет анимацию на основе стиля перехода
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transitionStyle {
        case .presentation:
            animatePresentation(transitionContext: transitionContext)
        case .dismissal:
            animateDismissal(transitionContext: transitionContext)
        }
    }
}
