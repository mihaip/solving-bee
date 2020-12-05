import Foundation

let LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

class LetterCandidates {
    // Map from letter index (0-6) to letter to count
    private var storage: [Int: [String: Int]] = [:]

    func add(letter: String, index: Int) {
        if !LETTERS.contains(letter) {
            return
        }
        storage[index, default: [:]][letter, default: 0] += 1
    }

    func reset() {
        storage = [:]
    }

    func results() -> [String]? {
        if storage.count != 7 {
            return nil
        }
        var result = [String]()
        for i in 0...6 {
            var topCandidate: String?
            var topCandidateCount = 0
            for (candidate, count) in storage[i]! {
                if (count > topCandidateCount) {
                    topCandidate = candidate
                    topCandidateCount = count
                }
            }
            if let candidate = topCandidate {
                if topCandidateCount > 5 {
                    result.append(candidate)
                    continue
                }
            }
            return nil
        }
        return result
    }

    func detectionConfidence() -> Double {
        var matchedLetters = 0
        for i in 0...6 {
            if let letterStorage = storage[i] {
                for (_, count) in letterStorage {
                    if count > 5 {
                        matchedLetters += 1
                        break
                    }
                }
            }
        }
        return Double(matchedLetters) / 6.0
    }
}
