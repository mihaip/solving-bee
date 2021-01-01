import UIKit

class WordViewController: UIReferenceLibraryViewController {
    init(word: String) {
        super.init(term: word)
        self.title = word
    }

    required init(coder: NSCoder) {
        fatalError("Unused")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // UIReferenceLibraryViewController embeds its own navigation
        // controller, which we don't want. Hide its navigation bar and disable
        // its swipe back gesture so that ours takes precedence.
        if let child = self.children.first {
            if child is UINavigationController {
                let navigationController = child as! UINavigationController
                navigationController.navigationBar.isHidden = true
                navigationController.interactivePopGestureRecognizer?.isEnabled = false
            }
        }
    }
}
