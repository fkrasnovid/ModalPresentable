/// Делегат для модальных представлений
final class ModalPresentationDelegate: NSObject {
    static var defaultInstance = ModalPresentationDelegate()
}

extension ModalPresentationDelegate: UIViewControllerTransitioningDelegate {
    /// Возвращает настроенный аниматор для показа
    func animationController(
		forPresented presented: UIViewController,
		presenting: UIViewController,
		source: UIViewController
	) -> UIViewControllerAnimatedTransitioning? {
        return ModalPresentationAnimator(transitionStyle: .presentation)
    }

    /// Возвращает настроенный аниматор для скрытия
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalPresentationAnimator(transitionStyle: .dismissal)
    }

    /// Возвращает представление для координации переходов
    func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source: UIViewController
	) -> UIPresentationController? {
        let controller = ModalPresentationController(presentedViewController: presented, presenting: presenting)
        controller.delegate = self
        return controller
    }
}

extension ModalPresentationDelegate: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    /// Скрывает представление
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}
