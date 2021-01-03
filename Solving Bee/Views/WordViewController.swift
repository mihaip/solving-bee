import UIKit
import WebKit

class WordViewController: UIReferenceLibraryViewController, UINavigationControllerDelegate, WKNavigationDelegate {
    private let words: Words
    private let index: Int
    private let titleLabel: UILabel
    private var definitionWebView: WKWebView?
    private static let HIDE_WORD_JS = """
document.querySelectorAll("span.hg").forEach(el => {
    el.style.visibility = "hidden";
})
"""
    private static let SHOW_WORD_JS = """
document.querySelectorAll("span.hg").forEach(el => {
    el.style.removeProperty("visibility");
})
"""

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

        if !words.isWordRevealed(at: index) {
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
                navigationController.delegate = self

                // If there are multiple dictionaries installed, automatically open the
                // first one. We can't use indexPathsForVisibleRows because the view has
                // not been show yet (so nothing is visible).
                if let rootController = navigationController.viewControllers.first {
                    if rootController is UITableViewController {
                        let tableViewController = rootController as! UITableViewController
                        let dictionaryTableView = tableViewController.tableView!
                        if let dataSource = dictionaryTableView.dataSource {
                            if dataSource.numberOfSections?(in: dictionaryTableView) ?? 0 > 1 && dataSource.tableView(dictionaryTableView, numberOfRowsInSection: 0) > 0 {
                                // Calling tableView.selectRow(at:animated:scrollPosition:)
                                // does not appear to work, we need to trigger the delegate
                                // method directly (and disable animations manually and hide
                                // this view to avoid shown a transient state).
                                UIView.setAnimationsEnabled(false)
                                dictionaryTableView.isHidden = true
                                let firstRow = IndexPath(row: 0, section: 0)
                                let _ = dictionaryTableView.delegate?.tableView?(dictionaryTableView, willSelectRowAt: firstRow)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    UIView.setAnimationsEnabled(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @objc func revealWord(sender: UIBarButtonItem) {
        words.revealWord(at: index)
        titleLabel.attributedText = words.displayWord(at: index)
        self.navigationItem.rightBarButtonItem = nil
        definitionWebView?.evaluateJavaScript(WordViewController.SHOW_WORD_JS)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Hide the word in the definition display too. The definition display
        // is implemented via a (locally rendered) WKWebView, so we need to run
        // a snippet of JS to hide it. We can't do that immediately, we need for
        // the webview to navigate first.
        viewController.hidesBottomBarWhenPushed = true
        if !words.isWordRevealed(at: index) {
            if let subview = viewController.view.subviews.first {
                if subview is WKWebView {
                    definitionWebView = subview as? WKWebView
                    definitionWebView?.navigationDelegate = self
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == definitionWebView {
            webView.evaluateJavaScript(WordViewController.HIDE_WORD_JS)
        }
    }
}
