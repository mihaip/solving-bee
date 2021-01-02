import Foundation
import UIKit

class Words {
    private static let HIGHLIGHT_COLOR = UIColor(red: 248.0/255.0, green: 205.0/255.0, blue: 5.0/255.0, alpha: 1)

    private static var dictionary: [String]? = {
        if let dictionaryPath = Bundle.main.path(forResource: "dictionary", ofType: "txt") {
            do {
                let dictionaryStr = try String(contentsOfFile: dictionaryPath)
                return dictionaryStr.components(separatedBy: "\n")
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }()
    private let requiredLetter: String
    private var revealedWords = Set<Int>()

    public let loaded: Bool
    public let words: [String]


    init(letters: [String]) {
        requiredLetter = letters[0]
        if let dictionary = Words.dictionary {
            let letterSet = Set(letters)
            var matchedWords = [String]()
            for word in dictionary {
                let wordSet = Set(word.map(String.init))
                if !wordSet.contains(letters[0]) {
                    continue
                }
                if wordSet.subtracting(letterSet).isEmpty {
                    matchedWords.append(word)
                }
            }
            words = matchedWords
            loaded = true
        } else {
            words = []
            loaded = false
        }
    }

    func displayWord(at index: Int) -> NSAttributedString {
        let word = words[index]
        let reveal = revealedWords.contains(index)
        let result = NSMutableAttributedString()
        for (i, piece) in word.split(separator: requiredLetter[requiredLetter.startIndex], maxSplits: Int.max, omittingEmptySubsequences: false).enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: requiredLetter, attributes: [.foregroundColor: Words.HIGHLIGHT_COLOR]))
                if !reveal {
                    result.append(NSAttributedString(string: " "))
                }
            }
            if (reveal) {
                result.append(NSAttributedString(string: String(piece)))
            } else {
                result.append(NSAttributedString(string: String(repeating:"_ ", count:piece.count)))
            }
        }
        return result
    }

    func revealWord(at index: Int) {
        revealedWords.insert(index)
    }

    func isWordRevealed(at index: Int) -> Bool {
        return revealedWords.contains(index)
    }
}
