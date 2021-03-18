import SwiftUI
import UIKit

class SplashViewController : UIHostingController<SplashView> {
    init() {
        super.init(rootView: SplashView())
        func showViewController(_ viewController: UIViewController) {
            // Though a bit strange, the easiest way to do a cross-fade
            // animation is to present the scanning controler modally.
            let wrappedViewController = UINavigationController(rootViewController: viewController)
            wrappedViewController.modalPresentationStyle = .overFullScreen
            wrappedViewController.modalTransitionStyle = .crossDissolve
            self.present(wrappedViewController, animated: true, completion: {
                // Make sure that we're not visible when doing word view
                // transitions (during which time transparent views may be
                // on-screen).
                self.view.isHidden = true
            })

        }
        func dismissViewController() {
            self.view.isHidden = false
            self.dismiss(animated: true, completion: nil)
        }

        rootView.begin = {
            showViewController(ScanningViewController(dismiss: dismissViewController))
        }
        rootView.help = {
            showViewController(HelpViewController(dismiss: dismissViewController))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Unused")
    }
}
