import ModalPresentable
import UIKit

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .white

		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stackView)
		stackView.axis = .vertical
		stackView.distribution = .equalSpacing
		stackView.spacing = 10

		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])

		unowned let uSelf = self
		let elements: [ModalElement] = [
			ModalElement(title: "По умолчанию") {
				uSelf.presentModal(ModalViewController())
			},
			ModalElement(title: "Кастомная") {
				uSelf.presentModal(CustomModalViewController())
			}
		]

		elements.forEach(stackView.addArrangedSubview(_:))
	}
}

class ModalElement: UIView {
	let label = UILabel()
	let action: () -> Void

	override var intrinsicContentSize: CGSize {
		return .init(width: UIView.noIntrinsicMetric, height: label.intrinsicContentSize.height + 25)
	}

	init(title: String, action: @escaping () -> Void) {
		self.action = action
		super.init(frame: .zero)
		label.text = title
		addSubview(label)
		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
		label.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor),
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func tap() {
		action()
	}
}

class ModalViewController: UIViewController, ModalPresentable {
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .brown
	}
}

class CustomModalViewController: UIViewController, ModalPresentable {

	let containerView: ModalContentContainer = {
		let view = ModalContentContainer(height: 50)
		view.backgroundColor = .green
		return view
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .magenta
	}

	var shortFormHeight: ModalHeight {
		return .contentHeight(250)
	}

	var longFormHeight: ModalHeight {
		return .maxHeight
	}

	var allowsRepeatShortForm: Bool {
		return true
	}

	var isUserPerspectiveEnabled: Bool {
		return true
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	var dragIndicatorModel: DragIndicatorModel {
		return .init(offset: 10, height: 25, width: 155, color: .white, position: .onView)
	}

	var modalBackgroundColor: ModalBackgroundColorSpec {
		return .color(.blue)
	}

	var contentContainer: ModalContentContainer? {
		return containerView
	}

	func modalNoticeChangeYOffset(yState: StateY) {
		print("yPos: \(yState)")
	}
}
