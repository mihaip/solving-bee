import UIKit

class HelpViewController: UIViewController {
    private var dismiss: (() -> Void)

    init(dismiss: @escaping (() -> Void)) {
        self.dismiss = dismiss
        super.init(nibName: nil, bundle: nil)
        self.title = "Solving Bee Help"
    }

    required init?(coder: NSCoder) {
        fatalError("Unused")
    }

    override func loadView() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        let textView = UITextView()
        if let helpFileUrl = Bundle.main.url(forResource: "help", withExtension: "html") {
            do {
                let baseHelpText = try NSAttributedString(url: helpFileUrl, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                let helpText = NSMutableAttributedString(attributedString: baseHelpText)
                let range = NSRange(location: 0, length: helpText.length)
                // Override color to be dark mode-aware
                helpText.addAttribute(.foregroundColor, value: UIColor.label, range: range)
                // Override font to be dynamic type-aware
                let bodyFont = UIFont.preferredFont(forTextStyle: .body)
                helpText.enumerateAttribute(.font, in: range, options: .longestEffectiveRangeNotRequired) { (value, range, top) in
                    helpText.addAttribute(.font, value: bodyFont, range: range)
                }
                textView.attributedText = helpText
            } catch {
                print("Could not load help HTML")
            }
        }
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.isEditable = false
        self.view = textView
    }

    @objc func doneTapped() {
        self.dismiss()
    }
}
