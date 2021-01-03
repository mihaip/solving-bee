import AVFoundation
import UIKit

class ScanningViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewView: PreviewView!
    private var reticleView: ReticleView!
#if SHOW_VISION_IMAGE
    private var visionImageView: UIImageView!
#endif
    private var boardTextView: UILabel!

    private let boardImageExtractor = BoardImageExtractor()
    private let boardLetterExtractor = BoardLetterExtractor()
    private let letterCandidates = LetterCandidates()

    private let captureSession = AVCaptureSession()
    let captureSessionQueue = DispatchQueue(label: "CaptureSessionQueue")
    var captureDevice: AVCaptureDevice?
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoDataOutput.connection(with: AVMediaType.video)?.isEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoDataOutput.connection(with: AVMediaType.video)?.isEnabled = false
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var visionImage:  CIImage?
        var detectionConfidence: Double = 0.0
        if let (boardImage, boardImageConfidence) = boardImageExtractor.extractFrom(sampleBuffer: sampleBuffer) {

            if let boardLetters = boardLetterExtractor.extractFrom(image: boardImage) {
                for boardLetter in boardLetters {
                    letterCandidates.add(letter: boardLetter.letter, index: boardLetter.index)
                }
            }

#if SAVE_VISION_IMAGE
                self.saveVisionImage(visionImage)
#endif

            visionImage = boardImage
            detectionConfidence = boardImageConfidence + letterCandidates.detectionConfidence()
        } else {
            letterCandidates.reset()
        }
        if let letterResults = letterCandidates.results() {
            let words = Words(letters: letterResults)
            letterCandidates.reset()
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(WordsViewController(words: words), animated: true)
                return
            }
        }
        DispatchQueue.main.async {
            self.reticleView.detectionConfidence = min(detectionConfidence, 1.0)
            self.showMatchRect(visionImage:visionImage)
        }
    }

    func showMatchRect(visionImage: CIImage?) {
#if SHOW_VISION_IMAGE
        if let visionImage = visionImage {
            visionImageView.isHidden = false
            visionImageView.image = UIImage(ciImage: visionImage)
            let containerSize = self.view.bounds.size
            let imageSize = min(containerSize.width * 0.9, visionImage.extent.width)
            visionImageView.frame = CGRect(
                x: (containerSize.width - imageSize)/2,
                y: (containerSize.height - imageSize)/2,
                width: imageSize,
                height:imageSize)
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

    func saveVisionImage(_ visionImage: CIImage) {
        let filename = ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone.current, formatOptions: [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withFractionalSeconds]) + ".png";
        let ciContext = CIContext()
        do {
            let destinationUrl = try FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename)
            try ciContext.writePNGRepresentation(of: visionImage, to: destinationUrl, format: CIFormat.RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        } catch {
            print("Could not save vision image: \(error)")
        }
    }
}

