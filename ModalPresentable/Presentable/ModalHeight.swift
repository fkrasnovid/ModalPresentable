/// Описание возможных состояний высоты модального контейнера
public enum ModalHeight: Equatable {

    /// Максимальная высота (+ topOffset)
    case maxHeight

    /// Максимальная высота с указанным top inset, значение 0 === .maxHeight
    case maxHeightWithTopInset(CGFloat)

    /// Устанавливает заданную высоту
    case contentHeight(CGFloat)

    /// Устанавливает заданную высоту и игнорирует bottomSafeAreaInset
    case contentHeightIgnoringSafeArea(CGFloat)

    /// Устанавливает высоту основываясь на intrinsicSize
    case intrinsicHeight
}
