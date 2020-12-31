import Foundation

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
    public let loaded: Bool
    public let words: [String]

    init(letters: [String]) {
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
}
