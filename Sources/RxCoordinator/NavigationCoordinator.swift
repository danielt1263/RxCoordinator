import RxSwift
import UIKit

class NavigationCoordinator<VC>: Disposable where VC: UIViewController {
	weak var navigation: UINavigationController?
	weak var controller: VC?
	let animated: Bool

	init(navigation: UINavigationController?, controller: VC, animated: Bool) {
		self.navigation = navigation
		self.controller = controller
		self.animated = animated
		navigation?.pushViewController(controller, animated: animated)
	}

	func dispose() {
		pop(navigation: navigation, controller: controller, animated: animated)
	}
}
