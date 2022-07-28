import RxSwift
import UIKit

class ShowCoordinator<VC>: Disposable where VC: UIViewController {
	weak var controller: VC?

	init(parent: UIViewController?, child: VC, sender: Any?, show: ((UIViewController, Any?) -> Void)?) {
		self.controller = child
		show?(child, sender)
	}

	func dispose() {
		pop(navigation: controller?.navigationController, controller: controller, animated: true)
	}
}
