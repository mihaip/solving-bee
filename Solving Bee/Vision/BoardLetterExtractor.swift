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
            print("Could not create Vision request for board letter detector")
            return nil
        }
    }()

    private lazy var contoursRequest: VNDetectContoursRequest = {
        let contoursRequest = VNDetectContoursRequest()
        // No need to adjust the contrast, the filter already does that.
        contoursRequest.contrastAdjustment = 1.0
        return contoursRequest
    }()

    func extractFrom(image: CIImage, isPrintBoard: Bool) -> [BoardLetter]? {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do {
            var requests: [VNRequest] = [textRequest]
            // Figure out where the center of the letters is so that we can compute
            // polar coordinates relative to it. Contour detection is probably
            // overkill for this.
            // We don't do this for the print board because the extra outline
            // makes contour extraction harder.
            if !isPrintBoard {
                requests.append(contoursRequest)
            }
            if let letterDetectionRequest = letterDetectionRequest {
                requests.append(letterDetectionRequest)
            }
            try handler.perform(requests)
        } catch {
            print("Could not run board detection request")
            return nil
        }

        var centerX: CGFloat = 0.5
        var centerY: CGFloat = 0.5
        if let contourObservations = contoursRequest.results as? [VNContoursObservation] {
            if let contourObservation = contourObservations.first {
                var minX: CGFloat = 1.0
                var maxX: CGFloat = 0.0
                var minY: CGFloat = 1.0
                var maxY: CGFloat = 0.0
                contourObservation.topLevelContours
                    .map{ $0.normalizedPath.boundingBox }
                    .filter{ $0.height >= 0.02 && $0.height <= 0.1 && $0.width >= 0.02 && $0.width <= 0.1 }
                    .forEach{ box in
                        minX = min(minX, box.minX)
                        minY = min(minY, box.minY)
                        maxX = max(maxX, box.maxY)
                        maxY = max(maxY, box.maxY)
                    }
                centerX = (minX + maxX) / 2.0
                centerY = (minY + maxY) / 2.0
            }
        }
        var result = [BoardLetter]()
        func addCandidate(candidate: String, boundingBox: CGRect) {
            let x = boundingBox.midX - centerX
            let y = boundingBox.midY - centerY
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
            if let letterIndex = letterIndex {
                result.append(BoardLetter(letter: candidate, index: letterIndex))
            }

        }

        if let textObservations = textRequest.results as? [VNRecognizedTextObservation] {
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
                if letterResult.confidence > 0.3 {
                    addCandidate(candidate: letterResult.labels.first!.identifier, boundingBox: letterResult.boundingBox)
                }
            }
        }

        return result.count > 0 ? result : nil
    }
}
