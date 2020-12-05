import CoreImage
import Vision

struct BoardLetter {
    let letter: String
    let index: Int
}

class BoardLetterExtractor {
    private lazy var textRequest: VNRecognizeTextRequest = {
        let textRequest = VNRecognizeTextRequest()
        textRequest.customWords = LETTERS
        textRequest.recognitionLevel = .accurate
        textRequest.minimumTextHeight = 1.0/16.0
        textRequest.usesLanguageCorrection = true
        return textRequest
    }()

    private lazy var letterDetectionRequest: VNCoreMLRequest? = {
        do {
            let model = try VNCoreMLModel(for: LettersModel(configuration: MLModelConfiguration()).model)
            return VNCoreMLRequest(model: model)
        } catch {
            print("Could not create Vision request for board detector")
            return nil
        }
    }()

    func extractFrom(image: CIImage) -> [BoardLetter]? {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do {
            if let letterDetectionRequest = letterDetectionRequest {
                try handler.perform([textRequest, letterDetectionRequest])
            } else {
                try handler.perform([textRequest])
            }
        } catch {
            print("Could not run board detection request")
            return nil
        }

        var result = [BoardLetter]()
        func addCandidate(candidate: String, boundingBox: CGRect) {
            let x = boundingBox.midX - 0.5
            let y = boundingBox.midY - 0.5
            let distance = Double(sqrt(x * x + y * y))
            let azimuth = Double(atan2(y, x))
            var letterIndex: Int?
            if (distance < 0.08) {
                letterIndex = 0
            } else if (distance > 0.2 && distance < 0.6) {
                func closeTo(_ value: Double) -> Bool {
                    return abs(azimuth - value) < Double.pi / 10
                }
                if (closeTo(Double.pi / 2)) {
                    letterIndex = 1
                } else if (closeTo(Double.pi / 6)) {
                    letterIndex = 2
                } else if (closeTo(-Double.pi / 6)) {
                    letterIndex = 3
                } else if (closeTo(-Double.pi / 2)) {
                    letterIndex = 4
                } else if (closeTo(-Double.pi * 5.0/6.0)) {
                    letterIndex = 5
                } else if (closeTo(Double.pi * 5.0/6.0)) {
                    letterIndex = 6
                }
            }
            print("    candidate", candidate, letterIndex, distance, azimuth)
            if let letterIndex = letterIndex {
                result.append(BoardLetter(letter: candidate, index: letterIndex))
            }

        }

        let textObservations = textRequest.results as? [VNRecognizedTextObservation]
        if let textObservations = textObservations {
            print("textObservations", textObservations.count)
            for textObservation in textObservations {
                guard let candidate = textObservation.topCandidates(1).first else {continue}
                if candidate.string.count != 1 {
                    continue
                }
                addCandidate(candidate: candidate.string == "0" ? "0" : candidate.string, boundingBox: textObservation.boundingBox)
            }
        }

        if let letterResults = letterDetectionRequest?.results as? [VNRecognizedObjectObservation] {
            for letterResult in letterResults {
                print("letterResult", letterResult)
                if letterResult.confidence > 0.3 {
                    for letterLabel in letterResult.labels {
                        addCandidate(candidate: letterLabel.identifier, boundingBox: letterResult.boundingBox)
                    }
                }
            }
        }

        return result.count > 0 ? result : nil
    }
}
