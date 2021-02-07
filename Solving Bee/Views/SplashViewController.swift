import SwiftUI
import UIKit

class SplashViewController : UIHostingController<SplashView> {
    init() {
        super.init(rootView: SplashView())
        rootView.begin = {
            // Though a bit strange, the easiest way to do a cross-fade
            // animation is to present the scanning controler modally.
            let scanningViewController = UINavigationController(rootViewController: ScanningViewController(dismiss: {
                self.dismiss(animated: true, completion: nil)
            }))
            scanningViewController.modalPresentationStyle = .overFullScreen
            scanningViewController.modalTransitionStyle = .crossDissolve
            self.present(scanningViewController, animated: true, completion: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Unused")
    }
}
