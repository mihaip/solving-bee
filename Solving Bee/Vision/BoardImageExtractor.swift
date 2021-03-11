import CoreImage
import Foundation
import Vision

let BOARD_DETECTION_MIN_CONFIDENCE: VNConfidence = 0.2

class BoardImageExtractor {
    private lazy var boardDetectionRequest: VNCoreMLRequest? = {
        do {
            let model = try VNCoreMLModel(for: BoardModel(configuration: MLModelConfiguration()).model)
            return VNCoreMLRequest(model: model)
        } catch {
            print("Could not create Vision request for board detector")
            return nil
        }
    }()
    private lazy var printBoardDetectionRequest: VNCoreMLRequest? = {
        do {
            let model = try VNCoreMLModel(for: PrintBoardModel(configuration: MLModelConfiguration()).model)
            return VNCoreMLRequest(model: model)
        } catch {
            print("Could not create Vision request for board detector")
            return nil
        }
    }()


    func extractFrom(sampleBuffer: CMSampleBuffer) -> (CIImage, Double, Bool)? {
        if boardDetectionRequest == nil || printBoardDetectionRequest == nil {
            return nil
        }
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])

        do {
            try visionHandler.perform([boardDetectionRequest!, printBoardDetectionRequest!])
        } catch {
            print("Could not run board detection request")
            return nil
        }

        func getResult(request: VNCoreMLRequest) -> VNDetectedObjectObservation? {
            if let results = request.results as? [VNDetectedObjectObservation] {
                let filteredResults = results.filter { $0.confidence > BOARD_DETECTION_MIN_CONFIDENCE }
                if !filteredResults.isEmpty {
                    return filteredResults.first!
                }
            }
            return nil
        }
        let digitalResult = getResult(request: boardDetectionRequest!)
        let printResult = getResult(request: printBoardDetectionRequest!)

        let bestResult: VNDetectedObjectObservation?
        if digitalResult == nil {
            bestResult = printResult
        } else if printResult == nil {
            bestResult = digitalResult
        } else {
            bestResult = digitalResult!.confidence > printResult!.confidence ? digitalResult : printResult
        }

        if let result = bestResult {
            let detectionConfidence = Double(result.confidence)
            let visionRect = result.boundingBox
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let image = CIImage(cvPixelBuffer: imageBuffer)
            let cropRect = VNImageRectForNormalizedRect(visionRect, Int(image.extent.size.width), Int(image.extent.size.height))
            let croppedImage = image.cropped(to:cropRect)
            // Need to offset the cropped image, otherwise various
            // operations won't work correctly on it (e.g. displaying in
            // an UIImageView or running an object detection request).
            let transformedImage = croppedImage.transformed(by: CGAffineTransform(translationX: -croppedImage.extent.origin.x, y: -croppedImage.extent.origin.y))
            let filter = BoardImageFilter()
            filter.inputImage = transformedImage
            if let outputImage = filter.outputImage {
                return (outputImage, detectionConfidence, result == printResult)
            }
        }

        return nil
    }

}
