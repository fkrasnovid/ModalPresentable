/**
	Только для внутреннего использования, в паблик выносить нельзя)
	Расширение-хелпер для хендла лаяута в ModalPresentationController
 */
extension ModalPresentable where Self: UIViewController {
	/// Каст контроллера к ModalPresentationController для доступа к свойствам и методам
    var presentedVC: ModalPresentationController? {
        return presentationController as? ModalPresentationController
    }

    /// Top safe area inset
    var topLayoutOffset: CGFloat {
		guard let rootVC = rootViewController else { return 0.0 }
        return rootVC.view.safeAreaInsets.top
    }

    /// Bottom safe area inset
    var bottomLayoutOffset: CGFloat {
		guard let rootVC = rootViewController else { return 0 }
		return rootVC.view.safeAreaInsets.bottom
    }

    /// Возвращает Y значение свернутого состояния
    var shortFormYPos: CGFloat {
        let shortFormYPos = topMargin(from: shortFormHeight) + topOffset
        // свернутое состояние не должно превышать развернутое
        return max(shortFormYPos, longFormYPos)
    }

    /**
		Возвращает Y значение развернутого состояния

		- Примечание: Ограничивает это значение до максимально возможной высоты
			чтобы контент не отображался за пределами просмотра
     */
    var longFormYPos: CGFloat {
        return max(topMargin(from: longFormHeight), topMargin(from: .maxHeight)) + topOffset
    }

    /**
		Использование конейнера для относительного позиционирования frame вью
		Настраивается в ModalPresentationController'e
     */
    var bottomYPos: CGFloat {
        guard let container = presentedVC?.containerView else { return view.bounds.height }
        return container.bounds.size.height - topOffset
    }

    /// Конвертация модального отступа в значение позиции Y, рассчитывается сверху
    func topMargin(from: ModalHeight) -> CGFloat {
        switch from {
        case .maxHeight:
            return 0.0
        case let .maxHeightWithTopInset(inset):
            return inset
        case let .contentHeight(height):
            return bottomYPos - (height + bottomLayoutOffset)
        case let .contentHeightIgnoringSafeArea(height):
            return bottomYPos - height
        case .intrinsicHeight:
            view.layoutIfNeeded()
            var margin: CGFloat = 0
            let targetSize = CGSize(
                width: (presentedVC?.containerView?.bounds ?? UIScreen.main.bounds).width,
                height: UIView.layoutFittingCompressedSize.height
            )
            let intrinsicHeight = view.systemLayoutSizeFitting(targetSize).height
            
            margin += bottomYPos - (intrinsicHeight + bottomLayoutOffset)
            if view.safeAreaInsets.bottom != bottomLayoutOffset {
                margin -= bottomLayoutOffset
            }
            return margin
        }
    }

    /// Получение rootViewController'a
    private var rootViewController: UIViewController? {
		if #available(iOS 13, *) {
			return UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
		} else {
			return UIApplication.shared.keyWindow?.rootViewController
		}
    }
}
