import UIKit

class PlaybackButton: UIButton {
    private var player: VideoTherapyPlayerProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with player: VideoTherapyPlayerProtocol) {
        self.player = player
    }
    
    @objc func onTap() {
        player.togglePlayPause()
    }
    
    func updateUI() {
        let imageName: String = player.isPlaying ? "playback-pause" : "playback-play"
        setImage(UIImage(named: imageName), for: .normal)
    }
}
