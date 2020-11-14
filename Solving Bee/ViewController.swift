import AVFoundation
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

let LETTERS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

class LetterCandidates {
    // Map from letter index (0-6) to letter to count
    private var storage: [Int: [String: Int]] = [:]

    func add(letter: String, index: Int) {
        var letter = letter
        if letter == "0" {
            letter = "O"
        }
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

class ReticleView: UIView {
    private var reticleView: UIImageView!
    private var detectedOverlayView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame:frame)

        reticleView = UIImageView(frame:self.bounds)
        reticleView.image = UIImage(named:"Reticle")
        self.addSubview(self.reticleView)

        detectedOverlayView = UIImageView(frame:self.bounds)
        detectedOverlayView.image = UIImage(named:"ReticleDetectedOverlay")
        detectedOverlayView.alpha = 0.0
        self.addSubview(self.detectedOverlayView)
    }

    var detectionConfidence: Double {
        get {
            Double(detectedOverlayView.alpha)
        }
        set {
            detectedOverlayView.alpha = CGFloat(newValue)
            let scale = 1.0 + CGFloat(newValue / 3)
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            UIView.animate(withDuration: 0.2) {
                self.detectedOverlayView.layer.setAffineTransform(scaleTransform)
                self.reticleView.layer.setAffineTransform(scaleTransform)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Unused")
    }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewView: PreviewView!
    private var reticleView: ReticleView!
    private var visionImageView: UIImageView!
    private var boardTextView: UILabel!
    private var letterCandidates = LetterCandidates()

    // MARK: - Capture related objects
    private let captureSession = AVCaptureSession()
    let captureSessionQueue = DispatchQueue(label: "com.example.apple-samplecode.CaptureSessionQueue")
    var captureDevice: AVCaptureDevice?
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoDataOutputQueue")

    private var boardDetectionRequest: VNCoreMLRequest!
    private let boardDetectionMinConfidence: VNConfidence = 0.2

    override func viewDidLoad() {
        super.viewDidLoad()

        previewView = PreviewView(frame: self.view.bounds)
        previewView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.addSubview(previewView)

        let previewSize = self.view.bounds.size
        let reticleSize = self.view.bounds.size.width * 0.6
        reticleView = ReticleView(frame: CGRect(x: (previewSize.width - reticleSize)/2, y: (previewSize.height - reticleSize)/2, width: reticleSize, height: reticleSize))
        reticleView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.view.addSubview(reticleView)

        previewView.session = captureSession

        do {
            let model = try VNCoreMLModel(for: SolvingBeeModel(configuration: MLModelConfiguration()).model)
            boardDetectionRequest = VNCoreMLRequest(model: model)
        } catch {
            print("Could not create Vision request for board detector")
        }

        visionImageView = UIImageView(frame: self.view.bounds)
        visionImageView.isHidden = true
        self.view.addSubview(visionImageView)

        let (boardTextFrame, _) = self.view.bounds.divided(atDistance: 120, from: .minYEdge)
        boardTextView = UILabel(frame: boardTextFrame)
        boardTextView.font = UIFont.systemFont(ofSize: 30)
        boardTextView.textAlignment = .center
        boardTextView.backgroundColor = UIColor.red
        boardTextView.isHidden = true
        self.view.addSubview(boardTextView)

        self.view.backgroundColor = UIColor.black

        // Starting the capture session is a blocking call. Perform setup using
        // a dedicated serial dispatch queue to prevent blocking the main thread.
        captureSessionQueue.async {
            self.setupCamera()
        }
    }

    func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            print("Could not create capture device.")
            return
        }
        self.captureDevice = captureDevice

        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Could not create device input.")
            return
        }
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }

        // Configure video data output.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // NOTE:
            // There is a trade-off to be made here. Enabling stabilization will
            // give temporally more stable results and should help the recognizer
            // converge. But if it's enabled the VideoDataOutput buffers don't
            // match what's displayed on screen, which makes drawing bounding
            // boxes very hard. Disable it in this app to allow drawing detected
            // bounding boxes on screen.
            let connection = videoDataOutput.connection(with: AVMediaType.video)
            connection?.preferredVideoStabilizationMode = .off
            connection?.videoOrientation = .portrait
        } else {
            print("Could not add VDO output")
            return
        }

        // Set zoom and autofocus to help focus on very small text.
        //        do {
        //            try captureDevice.lockForConfiguration()
        //            captureDevice.videoZoomFactor = 2
        //            captureDevice.autoFocusRangeRestriction = .near
        //            captureDevice.unlockForConfiguration()
        //        } catch {
        //            print("Could not set zoom level due to error: \(error)")
        //            return
        //        }

        captureSession.startRunning()
    }

    // MARK AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        do {
            // This is where we detect the board.
            let visionHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
            try visionHandler.perform([boardDetectionRequest])
            var visionImage: CIImage?
            var detectionConfidence: Double = 0.0
            if let results = boardDetectionRequest.results as? [VNDetectedObjectObservation] {
                let filteredResults = results.filter { $0.confidence > boardDetectionMinConfidence }
                if !filteredResults.isEmpty {
                    detectionConfidence = Double(filteredResults[0].confidence)
                    let visionRect = filteredResults[0].boundingBox
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                    let image = CIImage(cvPixelBuffer: imageBuffer)
                    let cropRect = VNImageRectForNormalizedRect(visionRect, Int(image.extent.size.width), Int(image.extent.size.height))
                    let croppedImage = image.cropped(to:cropRect)
                    let filter = CIFilter.colorControls()
                    filter.contrast = 3
                    filter.saturation = 0
                    filter.brightness = 0.8
                    filter.inputImage = croppedImage
                    visionImage = filter.outputImage
                }
            }

            if let visionImage = visionImage {
                let textRequest = VNRecognizeTextRequest()
                textRequest.customWords = LETTERS
                textRequest.recognitionLevel = .accurate
                textRequest.minimumTextHeight = 1.0/16.0
                textRequest.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(ciImage: visionImage, options: [:])
                try handler.perform([textRequest])
                let textObservations = textRequest.results as? [VNRecognizedTextObservation]
                if let textObservations = textObservations {
                    print("textObservations", textObservations.count)
                    for textObservation in textObservations {
                        guard let candidate = textObservation.topCandidates(1).first else {continue}
                        if candidate.string.count != 1 {
                            continue
                        }
                        let x = textObservation.boundingBox.midX - 0.5
                        let y = textObservation.boundingBox.midY - 0.5
                        let distance = Double(sqrt(x * x + y * y))
                        let azimuth = Double(atan2(y, x))
                        var letterIndex: Int?
                        if (distance < 0.05) {
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
                            letterCandidates.add(letter: candidate.string, index: letterIndex)
                        }
                        print("    candidate", candidate.string, letterIndex, distance, azimuth)
                    }
                }

                detectionConfidence += letterCandidates.detectionConfidence()
            } else {
                letterCandidates.reset()
            }
            DispatchQueue.main.async {
                self.reticleView.detectionConfidence = min(detectionConfidence, 1.0)
                self.showMatchRect(visionImage:visionImage)
            }
        } catch {
            print("Could not run board detection request")
            return
        }
    }


    func showMatchRect(visionImage: CIImage?) {
//        if let visionImage = visionImage {
//            visionImageView.isHidden = false
//            // Avoid issues with displaying of cropped images (from https://stackoverflow.com/a/46965963/343108)
//            let ciContext = CIContext()
//            if let cgImage = ciContext.createCGImage(visionImage, from: visionImage.extent) {
//                visionImageView.image = UIImage(cgImage: cgImage)
//                visionImageView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: visionImageView.image!.size)
//            }
//        } else {
//            visionImageView.isHidden = true
//        }
        if let letterResults = letterCandidates.results() {
            boardTextView.text = letterResults.joined()
            boardTextView.isHidden = false
        } else {
            boardTextView.isHidden = true
        }
    }


}

