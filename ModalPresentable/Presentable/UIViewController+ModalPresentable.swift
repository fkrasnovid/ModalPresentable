/// Расширение ModalPresentable с методами "хелперами"
public extension ModalPresentable where Self: UIViewController {
    typealias AnimationBlockType = () -> Void
    typealias AnimationCompletionType = (Bool) -> Void
    /// Для презентации, объект должен быть UIViewController типом и поддерживать ModalPresentable протокол
    typealias LayoutType = UIViewController & ModalPresentable

    /// Враппер над transition(to state: PresentationState)
    func modalTransition(to state: PresentationState, animationBlock: (() -> Void)? = nil, completionBlock: (() -> Void)? = nil) {
        presentedVC?.transition(to: state, animationBlock: animationBlock, completionBlock: completionBlock)
    }

    /**
		Враппер над setNeedsLayoutUpdate()
		- Примечание: Этот метод необходимо вызывать каждый раз,
			когда меняется любое значение из протокола ModalPresentable
     */
    func modalSetNeedsLayoutUpdate() {
        presentedVC?.setNeedsLayoutUpdate()
    }

    /**
		Метод для обновления с отключенным обзервом скролла
		- Примечание: Операции в scrollView такие как: изменение высоты, вставка/удаление ячеек etc,
				могут привести к "скачку", потому что представление реагирует на изменение offset'a контента
     */
    func modalPerformUpdates(_ updates: () -> Void) {
        presentedVC?.performUpdates(updates)
    }

    /**
		Враппер над функцией в ModalAnimator
		- Примечание: для консистентности анимаций представления
     */
    func modalAnimate(_ animationBlock: @escaping AnimationBlockType, _ completion: AnimationCompletionType? = nil) {
        ModalAnimator.animate(config: self, animations: animationBlock, completion: completion)
    }

    /**
		Враппер на observeKeyboard в ModalPresentationController
		- Примечание: Использовать для поддержки валидной работы с клавиатурой на представлении
    */
    func observeKeyboard() {
        presentedVC?.observeKeyboard()
    }
}
