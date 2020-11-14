import UIKit

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
