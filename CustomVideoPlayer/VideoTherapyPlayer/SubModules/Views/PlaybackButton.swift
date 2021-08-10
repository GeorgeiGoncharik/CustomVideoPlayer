import UIKit
import AVFoundation

class PlaybackButton: UIButton {
    private var player: VideoTherapyPlayerProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
        setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with player: VideoTherapyPlayerProtocol) {
        self.player = player
    }
    
    @objc func onTap() {
        player.isPlaying ? player.pause() : player.play()
        updateUI()
    }
    
    func updateUI() {
        let imageName: String = player.isPlaying ? "pause" : "play"
        setImage(UIImage(systemName: imageName), for: .normal)
    }
}
