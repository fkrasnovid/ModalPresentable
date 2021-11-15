extension UIScrollView {
    /// Определяет скроллится ли scrollView
    var isScrolling: Bool {
        return isDragging && !isDecelerating || isTracking
    }
}
