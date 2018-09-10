// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class LockEnterPasscodeCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    let window: UIWindow = UIWindow()
    var completition: ((Bool) -> Void)?
    private let model: LockEnterPasscodeViewModel
    private let lock: LockInterface
    private lazy var lockEnterPasscodeViewController: LockEnterPasscodeViewController = {
        return LockEnterPasscodeViewController(model: model)
    }()
    init(model: LockEnterPasscodeViewModel, lock: LockInterface = Lock()) {
        self.window.windowLevel = UIWindowLevelStatusBar + 1.0
        self.model = model
        self.lock = lock
        lockEnterPasscodeViewController.unlockWithResult = { [weak self] (state, bioUnlock) in
            if state {
                self?.completition?(state)
                self?.stop()
            }
        }
    }

    func start(showNavBar: Bool = false) {
        guard lock.shouldShowProtection() else { return }
        if showNavBar {
            let navigationController = NavigationController()
            let _ = lockEnterPasscodeViewController.view
            navigationController.viewControllers = [lockEnterPasscodeViewController]
            window.rootViewController = navigationController
            lockEnterPasscodeViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss))
            self.window.windowLevel = UIWindowLevelStatusBar - 0.5
            window.makeKeyAndVisible()
        } else {
            window.rootViewController = lockEnterPasscodeViewController
            window.makeKeyAndVisible()
        }
    }
    //This method should be refactored!!!
    func showAuthentication(withBioMerick: Bool = true, title: String? = nil) {
        
        if let navController = window.rootViewController as? NavigationController {
            guard navController.viewControllers.first == lockEnterPasscodeViewController else { return }
        } else {
            guard window.rootViewController == lockEnterPasscodeViewController else { return }
        }
        
        if let title = title {
            lockEnterPasscodeViewController.title = title
        }

        lockEnterPasscodeViewController.showKeyboard()
        if withBioMerick {
            lockEnterPasscodeViewController.showBioMerickAuth()
        }
        lockEnterPasscodeViewController.cleanUserInput()
    }

    func stop() {
        window.isHidden = true
    }
    
    @objc func dismiss() {
        
        completition?(false)
        stop()
    }
}
