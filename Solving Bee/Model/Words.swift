import Foundation
import UIKit

class Words {
    static let HIGHLIGHT_COLOR = UIColor(red: 248.0/255.0, green: 205.0/255.0, blue: 5.0/255.0, alpha: 1)

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
    private let letters: [String]
    private var revaledAllWords = false
    private var revealedWords = Set<Int>()

    public let loaded: Bool
    public let words: [String]


    init(letters: [String]) {
        self.letters = letters
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

    func displayTitle() -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (i, letter) in letters.enumerated() {
            if i == 0 {
                result.append(NSAttributedString(string: letter, attributes: [.foregroundColor: Words.HIGHLIGHT_COLOR]))
            } else {
                result.append(NSAttributedString(string: letter))
            }
        }
        return result
    }

    func displayWord(at index: Int) -> NSAttributedString {
        let word = words[index]
        let requiredLetter = letters[0]
        let reveal = isWordRevealed(at: index)
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
        if isPangram(word) {
            result.append(NSAttributedString(string: " ★", attributes: [.foregroundColor: Words.HIGHLIGHT_COLOR]))
        }
        return result
    }

    func revealWord(at index: Int) {
        revealedWords.insert(index)
    }

    func revealAllWords() {
        revaledAllWords = true
    }

    func isWordRevealed(at index: Int) -> Bool {
        return revaledAllWords || revealedWords.contains(index)
    }

    func isPangram(_ word: String) -> Bool {
        return word.count >= 7 && Set(word).count == 7
    }
}
