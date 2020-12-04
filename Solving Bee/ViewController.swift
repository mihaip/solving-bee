import AVFoundation
import UIKit
import Vision

let BOARD_DETECTION_MIN_CONFIDENCE: VNConfidence = 0.2

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewView: PreviewView!
    private var reticleView: ReticleView!
#if SHOW_VISION_IMAGE
    private var visionImageView: UIImageView!
#endif
    private var boardTextView: UILabel!

    private var letterCandidates = LetterCandidates()

    private let captureSession = AVCaptureSession()
    let captureSessionQueue = DispatchQueue(label: "CaptureSessionQueue")
    var captureDevice: AVCaptureDevice?
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")

    private var boardDetectionRequest: VNCoreMLRequest!

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

#if SHOW_VISION_IMAGE
        visionImageView = UIImageView(frame: self.view.bounds)
        visionImageView.isHidden = true
        self.view.addSubview(visionImageView)
#endif

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

        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            let connection = videoDataOutput.connection(with: AVMediaType.video)
            // Force portait orientation so that we don't need to worry about
            // coordinate conversions when creating CIImages
            connection?.videoOrientation = .portrait
        } else {
            print("Could not add VDO output")
            return
        }

        // Set zoom and autofocus to help focus on very small text.
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = 2
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }

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
                let filteredResults = results.filter { $0.confidence > BOARD_DETECTION_MIN_CONFIDENCE }
                if !filteredResults.isEmpty {
                    detectionConfidence = Double(filteredResults[0].confidence)
                    let visionRect = filteredResults[0].boundingBox
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                    let image = CIImage(cvPixelBuffer: imageBuffer)
                    let cropRect = VNImageRectForNormalizedRect(visionRect, Int(image.extent.size.width), Int(image.extent.size.height))
                    let croppedImage = image.cropped(to:cropRect)
                    let filter = BoardImageFilter()
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
            if let letterResults = letterCandidates.results() {
                let words = Words(letters: letterResults)
                DispatchQueue.main.async {
                    self.present(WordsViewController(words: words), animated: true, completion: nil)
                    return
                }
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
#if SHOW_VISION_IMAGE
        if let visionImage = visionImage {
            visionImageView.isHidden = false
            // Avoid issues with displaying of cropped images (from https://stackoverflow.com/a/46965963/343108)
            let ciContext = CIContext()
            if let cgImage = ciContext.createCGImage(visionImage, from: visionImage.extent) {
                visionImageView.image = UIImage(cgImage: cgImage)
                let containerSize = self.view.bounds.size
                let imageSize = min(containerSize.width * 0.9, visionImage.extent.width)
                visionImageView.frame = CGRect(
                    x: (containerSize.width - imageSize)/2,
                    y: (containerSize.height - imageSize)/2,
                    width: imageSize,
                    height:imageSize)
            }
        } else {
            visionImageView.isHidden = true
        }
#endif

        if let letterResults = letterCandidates.results() {
            boardTextView.text = letterResults.joined()
            boardTextView.isHidden = false
        } else {
            boardTextView.isHidden = true
        }
    }


}

