import RxSwift
import Foundation
import UIKit

final class PresentationCoordinator<VC>: Disposable where VC: UIViewController {
	weak var parent: UIViewController?
	weak var child: VC?
	let animated: Bool

	init(child: VC, barButtonItem: UIBarButtonItem, animated: Bool) {
		self.child = child
		self.animated = animated
		queue.async {
			let semaphore = DispatchSemaphore(value: 0)
			DispatchQueue.main.async {
				let parent = UIViewController.top()
				self.parent = parent
				if let popoverPresentationController = child.popoverPresentationController {
					popoverPresentationController.barButtonItem = barButtonItem
				}
				parent.present(child, animated: animated) {
					semaphore.signal()
				}
			}
			semaphore.wait()
		}
	}

	init(child: VC, sourceView: UIView?, animated: Bool) {
		self.child = child
		self.animated = animated
		queue.async {
			let semaphore = DispatchSemaphore(value: 0)
			DispatchQueue.main.async {
				let parent = UIViewController.top()
				self.parent = parent
				if let popoverPresentationController = child.popoverPresentationController,
				   let sourceView = sourceView {
					popoverPresentationController.sourceView = sourceView
					popoverPresentationController.sourceRect = sourceView.bounds
				}
				parent.present(child, animated: animated) {
					semaphore.signal()
				}
			}
			semaphore.wait()
		}
	}

	func dispose() {
		remove(parent: parent, child: child, animated: animated)
	}
}

func remove(parent: UIViewController?, child: UIViewController?, animated: Bool) {
	queue.async { [weak parent, weak child, animated] in
		let semaphore = DispatchSemaphore(value: 0)
		DispatchQueue.main.async {
			guard let parent = parent, let child = child else { semaphore.signal(); return }
			if parent.presentedViewController === child && !child.isBeingDismissed {
				parent.dismiss(animated: animated) {
					semaphore.signal()
				}
			}
		}
		semaphore.wait()
	}
}

private extension UIViewController {
	static func top() -> UIViewController {
		guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else { fatalError("No view controller present in app?") }
		var result = rootViewController
		while let vc = result.presentedViewController, !vc.isBeingDismissed {
			result = vc
		}
		return result
	}
}
