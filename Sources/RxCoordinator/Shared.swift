import UIKit

let queue = DispatchQueue(label: "ScenePresentationHandler")

func pop(navigation: UINavigationController?, controller: UIViewController?, animated: Bool) {
	queue.async { [weak navigation, weak controller] in
		DispatchQueue.main.async {
			if let controller = controller, let navigation = navigation, let index = navigation.viewControllers.firstIndex(of: controller), index > 0 {
				navigation.popToViewController(navigation.viewControllers[index - 1], animated: true)
			}
		}
	}
}
