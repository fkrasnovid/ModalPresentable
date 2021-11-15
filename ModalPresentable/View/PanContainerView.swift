/// Враппер презентованного представления для омниканальных модификаций
final class PanContainerView: UIView {
    private weak var proxy: UIView?

    init(presentedView: UIView, frame: CGRect) {
        super.init(frame: frame)
        addSubview(presentedView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Используйте init(presentedView: UIView, frame: CGRect)")
    }

    /// Переопределение обработки эвента
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if
			let modalContentContainer = superview?.dimmedView?.modalContentContainer,
			let touchedContainer = modalContentContainer.hitTest(convert(point, to: modalContentContainer), with: event)
		{
			return touchedContainer
		}

		if let touchedSelf = super.hitTest(convert(point, to: self), with: event) {
			return touchedSelf
		}

		if let touchedProxy = proxy?.hitTest(convert(point, to: proxy), with: event) {
            return touchedProxy
        }

        return super.hitTest(point, with: event)
    }
}

// MARK: - SetProxy

extension PanContainerView {
	func setProxyView(_ view: UIView?) {
        proxy = view
    }
}
