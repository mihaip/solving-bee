import Foundation
import UIKit

class Words {
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
    public let loaded: Bool
    public let words: [String]
    private static let HIGHLIGHT_COLOR = UIColor(red: 248.0/255.0, green: 205.0/255.0, blue: 5.0/255.0, alpha: 1)

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
        let result = NSMutableAttributedString(string: word)
        var range = word.startIndex..<word.endIndex
        while true {
            if let letterRange = word.range(of: requiredLetter, options: [], range: range, locale: nil) {
                result.addAttribute(.foregroundColor, value:Words.HIGHLIGHT_COLOR, range: NSRange(letterRange, in: word))
                range = letterRange.upperBound..<word.endIndex
            } else {
                break
            }
        }
        return result
    }
}
