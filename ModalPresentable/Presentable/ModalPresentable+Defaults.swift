/// Реализация по-умолчанию для ModalPresentable где Self: UIViewController
public extension ModalPresentable where Self: UIViewController {
    var panScrollable: UIScrollView? {
        return nil
    }

    var panProxy: UIViewController? {
        return nil
    }

    var topOffset: CGFloat {
        return topLayoutOffset + 21.0
    }

    var shortFormHeight: ModalHeight {
        return longFormHeight
    }

    var longFormHeight: ModalHeight {
        guard let scrollView = panScrollable else { return .maxHeight }
        /// вызывается один раз во время презентации и сохраняется
        scrollView.layoutIfNeeded()
        return .contentHeight(scrollView.contentSize.height)
    }

    var cornerRadius: CGFloat {
        return 16.0
    }

    var springDamping: CGFloat {
        return 0.8
    }

    var transitionDuration: Double {
        return ModalAnimator.Constants.defaultTransitionDuration
    }

    var transitionAnimationOptions: UIView.AnimationOptions {
        return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }

    var modalBackgroundColor: ModalBackgroundColorSpec {
        return .color(UIColor.black.withAlphaComponent(0.7))
    }

    var scrollIndicatorInsets: UIEdgeInsets {
        let top = shouldRoundTopCorners ? cornerRadius : 0
        return UIEdgeInsets(top: CGFloat(top), left: 0, bottom: bottomLayoutOffset, right: 0)
    }

    var anchorModalToLongForm: Bool {
        return true
    }

    var allowsExtendedScrolling: Bool {
        guard let scrollView = panScrollable else { return false }
        scrollView.layoutIfNeeded()
        return scrollView.contentSize.height > (scrollView.frame.height - bottomLayoutOffset)
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    var allowsTapToDismiss: Bool {
        return true
    }

    var allowsRepeatShortForm: Bool {
        return false
    }

    var isUserInteractionEnabled: Bool {
        return true
    }

    var isHapticFeedbackEnabled: Bool {
        return true
    }

    var isUserPerspectiveEnabled: Bool {
        return false
    }

    var shouldRoundTopCorners: Bool {
        return isModalPresented
    }

	var shouldShadowTopCorners: Bool {
		return true
	}

    var showDragIndicator: Bool {
        return shouldRoundTopCorners
    }

    var dragIndicatorModel: DragIndicatorModel {
		return DragIndicatorModel.defaultModel
    }

	var contentContainer: ModalContentContainer? {
		return nil
	}

    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return true
    }

    func shouldTransition(to state: PresentationState) -> Bool {
        return true
    }

    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }

    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {}
    func willTransition(to state: PresentationState) {}
    func modalWillDismiss() {}
    func modalDidDismiss() {}
	func modalNoticeChangeYOffset(yState: StateY) {}
}

extension DragIndicatorModel {
	static var defaultModel: DragIndicatorModel {
		return DragIndicatorModel(
			offset: 8.0,
			height: 4,
			width: 35.0,
			color: UIColor(red: 0.796, green: 0.804, blue: 0.8, alpha: 0.5),
			position: .onView
		)
	}
}
