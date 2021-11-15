///  Хелпер для консистентности анимаций
struct ModalAnimator {
    /// Константы свойств анимаций
    struct Constants {
        static let defaultTransitionDuration: TimeInterval = 0.5
    }

	static func animate(
		config: ModalPresentable?,
		animations: @escaping ModalPresentable.AnimationBlockType,
		completion: ModalPresentable.AnimationCompletionType? = nil
    ) {
        let transitionDuration = config?.transitionDuration ?? Constants.defaultTransitionDuration
        let springDamping = config?.springDamping ?? 1.0
        let animationOptions = config?.transitionAnimationOptions ?? []

        UIView.animate(
            withDuration: transitionDuration,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: 0,
            options: animationOptions,
            animations: animations,
            completion: completion
        )
    }
}
