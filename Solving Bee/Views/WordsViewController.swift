import UIKit

class WordsViewController: UITableViewController {
    private let words: Words

    init(words: Words) {
        self.words = words
        super.init(style: .plain)
        self.title = "Words"
    }

    required init?(coder: NSCoder) {
        fatalError("Unused")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WordCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Words might have been revealed, easiest to regenerate all cells.
        self.tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // UIReferenceLibraryViewController is slow to render the first time
        // (presumably because dictionary data is loaded), so we trigger a
        // throwaway instance to warm up the asset cache.
        if let windowScene = self.view.window?.windowScene {
            let warmupWindow = UIWindow(windowScene: windowScene)
            warmupWindow.rootViewController = UIReferenceLibraryViewController(term: "intel")
            warmupWindow.makeKeyAndVisible()
            DispatchQueue.main.async {
                warmupWindow.removeFromSuperview()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.loaded ? words.words.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath)
        let textLabel = cell.textLabel!
        if (words.loaded) {
            textLabel.attributedText = words.displayWord(at: indexPath.row)
            textLabel.font = UIFont.boldSystemFont(ofSize: textLabel.font.pointSize)
        } else {
            textLabel.text = "Could not load words"
            textLabel.textColor = UIColor.systemRed
        }

        return cell
    }

    // Mark: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (words.loaded) {
            // Can't animate the push because we end up with a broken transition
            // due to how we force UIReferenceLibraryViewController to open a
            // specific dictionary.
            self.navigationController?.pushViewController(WordViewController(words: words, index: indexPath.row), animated:false)
        }
    }
}
