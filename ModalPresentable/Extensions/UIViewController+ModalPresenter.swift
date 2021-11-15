/// Расширение UIViewController для ModalPresenter'a
extension UIViewController: ModalPresenter {
	public var isModalPresented: Bool {
        return (transitioningDelegate as? ModalPresentationDelegate) != nil
    }

	public func presentModal(_ viewControllerToPresent: UIViewController & ModalPresentable, completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.modalPresentationCapturesStatusBarAppearance = true
        viewControllerToPresent.transitioningDelegate = ModalPresentationDelegate.defaultInstance
        present(viewControllerToPresent, animated: true, completion: completion)
    }
}
