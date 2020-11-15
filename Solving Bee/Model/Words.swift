import Foundation

class Words {
    public let loaded: Bool
    public let words: [String]

    init(letters: [String]) {
        let sorted = letters.sorted()
        let rotationOffset = sorted.firstIndex(of: letters[0])!
        var rotatedAndLowered: [String] = []
        for i in 0...6 {
            rotatedAndLowered.append(sorted[(i + rotationOffset) % sorted.count].lowercased())
        }
        let url = "https://storage.googleapis.com/spelling-bee/\(rotatedAndLowered.joined()).txt"
        do {
            let wordsText = try String(contentsOf: URL(string: url)!)
            let splitWords = wordsText.split(separator:"\n")
            // Drop the score that's last in the file
            words = splitWords.dropLast().map { String($0) }
            loaded = true
        } catch {
            words = []
            loaded = false
        }
    }
}
