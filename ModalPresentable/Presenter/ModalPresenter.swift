/// Интерфейс для объектов, которые будет представлять контроллер представления как Modal
public protocol ModalPresenter: AnyObject {

    /// Флаг возвращает true если текущее представление использует ModalPresentationDelegate
    var isModalPresented: Bool { get }

    /// Презентует представление которое поддерживает ModalPresentable протокол
    func presentModal(_ viewControllerToPresent: ModalPresentable.LayoutType, completion: (() -> Void)?)
}

extension ModalPresenter {
    func presentModal(_ viewControllerToPresent: ModalPresentable.LayoutType, completion: (() -> Void)? = nil) {
        presentModal(viewControllerToPresent, completion: completion)
    }
}
