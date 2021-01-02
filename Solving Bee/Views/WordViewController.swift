import UIKit

class WordViewController: UIReferenceLibraryViewController {
    private let words: Words
    private let index: Int
    private let titleLabel: UILabel

    init(words: Words, index: Int) {
        let word = words.words[index]
        self.words = words
        self.index = index
        titleLabel = UILabel()
        titleLabel.attributedText = words.displayWord(at: index)
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)

        super.init(term: word)
        self.title = word
        self.navigationItem.titleView = titleLabel

        if (!words.isWordRevealed(at: index)) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reveal", style: .plain, target: self, action: #selector(revealWord(sender:)))
        }
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

    @objc func revealWord(sender: UIBarButtonItem) {
        words.revealWord(at: index)
        titleLabel.attributedText = words.displayWord(at: index)
        self.navigationItem.rightBarButtonItem = nil
    }
}
