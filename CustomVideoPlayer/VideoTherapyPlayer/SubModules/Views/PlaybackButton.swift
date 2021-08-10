import UIKit
import AVFoundation

class PlaybackButton: UIButton {
    var kvoRateContext = 0
    var avPlayer: AVPlayer?
    private var isPlaying: Bool {
        return avPlayer?.rate != 0 && avPlayer?.error == nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        updateUI()
        addObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateUI() {
        let imageName: String = isPlaying ? "pause" : "play"
        setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func updateStatus() {
        isPlaying ? avPlayer?.pause() : avPlayer?.play()
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        updateStatus()
        updateUI()
    }
    
    private func addObservers() {
        avPlayer?.addObserver(self, forKeyPath: "rate", options: .new, context: &kvoRateContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let context = context else { return }

        switch context {
        case &kvoRateContext:
            handleRateChanged()
        default:
            break
        }
    }
    
    private func handleRateChanged() {
        updateUI()
    }
}
