import RxResource
import RxSwift
import UIKit

public extension NSObjectProtocol where Self: UIViewController {
	static func fromStoryboard(storyboardName: String = "", bundle: Bundle? = nil, identifier: String = "") -> Self {
		let storyboard = UIStoryboard(
			name: storyboardName.isEmpty ? String(describing: self) : storyboardName,
			bundle: bundle
		)
		return identifier.isEmpty ?
		storyboard.instantiateInitialViewController() as! Self :
		storyboard.instantiateViewController(withIdentifier: identifier) as! Self
	}
}

public func assignScene<VC, Action>(
	disposeBag: DisposeBag,
	controller: VC,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> (controller: VC, action: Observable<Action>) where VC: UIViewController {
	(controller, wrapAction(disposeBag: disposeBag, controller: controller, configure: configure, remove: { }))
}

public func presentScene<VC, Action>(
	controller: @autoclosure @escaping () -> VC,
	animated: Bool,
	over sourceView: UIView? = nil,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> Observable<Action> where VC: UIViewController {
	Observable.using(
		Resource.build(
			PresentationCoordinator(child: controller(), sourceView: sourceView, animated: animated)
		),
		observableFactory: Resource.createObservable { disposeBag, state in
			guard let child = state.child else { return .empty() }
			return wrapAction(disposeBag: disposeBag, controller: child, configure: configure) { [weak state] in
				remove(parent: state?.parent, child: state?.child, animated: animated) }
		}
	)
}

public func presentScene<VC, Action>(
	controller: @autoclosure @escaping () -> VC,
	animated: Bool,
	over barButtonItem: UIBarButtonItem,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> Observable<Action> where VC: UIViewController {
	Observable.using(
		Resource.build(PresentationCoordinator(
			child: controller(),
			barButtonItem: barButtonItem,
			animated: animated
		)),
		observableFactory: Resource.createObservable { disposeBag, coordinator in
			guard let child = coordinator.child else { return .empty() }
			return wrapAction(disposeBag: disposeBag, controller: child, configure: configure) { [weak coordinator] in
				remove(parent: coordinator?.parent, child: coordinator?.child, animated: animated)

			}
		}
	)
}

public func pushScene<VC, Action>(
	controller: @autoclosure @escaping () -> VC,
	from navigation: UINavigationController?,
	animated: Bool,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> Observable<Action> where VC: UIViewController {
	Observable.using(
		Resource.build(NavigationCoordinator(navigation: navigation, controller: controller(), animated: animated)),
		observableFactory: Resource.createObservable { disposeBag, coordinator in
			guard let controller = coordinator.controller else { return .empty() }
			return wrapAction(disposeBag: disposeBag, controller: controller, configure: configure) { [weak coordinator] in
				pop(navigation: coordinator?.navigation, controller: coordinator?.controller, animated: animated)
			}
		}
	)
}

public func showScene<VC, Action>(
	controller: @autoclosure @escaping () -> VC,
	from parent: UIViewController?,
	sender: Any? = nil,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> Observable<Action> where VC: UIViewController {
	Observable.using(
		Resource.build(ShowCoordinator(
			parent: parent,
			child: controller(),
			sender: sender, show: parent?.show(_:sender:)
		)),
		observableFactory: Resource.createObservable { disposeBag, coordinator in
			guard let controller = coordinator.controller else { return .empty() }
			return wrapAction(disposeBag: disposeBag, controller: controller, configure: configure) { [weak coordinator] in
				pop(navigation: coordinator?.controller?.navigationController, controller: coordinator?.controller, animated: true)
			}
		}
	)
}

public func showDetailScene<VC, Action>(
	controller: @autoclosure @escaping () -> VC,
	from parent: UIViewController?,
	sender: Any? = nil,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>
) -> Observable<Action> where VC: UIViewController {
	Observable.using(
		Resource.build(ShowCoordinator(
			parent: parent,
			child: controller(),
			sender: sender,
			show: parent?.showDetailViewController(_:sender:)
		)),
		observableFactory: Resource.createObservable { disposeBag, coordinator in
			guard let controller = coordinator.controller else { return .empty() }
			return wrapAction(disposeBag: disposeBag, controller: controller, configure: configure) { [weak coordinator] in
				pop(navigation: coordinator?.controller?.navigationController, controller: coordinator?.controller, animated: true)
			}
		}
	)
}

private func wrapAction<VC, Action>(
	disposeBag: DisposeBag,
	controller: VC,
	configure: @escaping (DisposeBag, VC) -> Observable<Action>,
	remove: @escaping () -> Void
) -> Observable<Action> where VC: UIViewController {
	let action = Observable.merge(controller.rx.viewDidLoad, controller.isViewLoaded ? .just(()) : .empty())
		.take(1)
		.flatMap { [weak controller] () -> Observable<Action> in
			guard let controller = controller else { return .empty() }
			return configure(disposeBag, controller)
		}
		.do(
			onError: { _ in remove() },
			onCompleted: { remove() }
		)
		.take(until: controller.rx.deallocating)
		.publish()
	action.connect()
		.disposed(by: disposeBag)
	return action
}

private extension Reactive where Base: UIViewController {
	var viewDidLoad: Observable<Void> {
		base.rx.methodInvoked(#selector(UIViewController.viewDidLoad))
			.map { _ in }
	}
}
