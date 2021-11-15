extension UIView {
    /// Удобное получение экземпляра PanContainerView
    var panContainerView: PanContainerView? {
        return subviews.first { $0 is PanContainerView } as? PanContainerView
    }

	/// Удобное получение экземпляра DimmedView
    var dimmedView: DimmedView? {
        return subviews.first { $0 is DimmedView } as? DimmedView
    }

	/// Удобное получение экземпляра ModalContentContainer
	var modalContentContainer: ModalContentContainer? {
		return subviews.first { $0 is ModalContentContainer } as? ModalContentContainer
	}
}
