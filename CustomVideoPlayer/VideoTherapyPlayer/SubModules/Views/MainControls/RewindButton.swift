import UIKit

class RewindButton: UIButton {
    private var player: VideoTherapyPlayerProtocol!
    private var rewindInterval: Double = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with player: VideoTherapyPlayerProtocol, rewind interval: TimeInterval) {
        self.player = player
        self.rewindInterval = interval
    }
    
    @objc func onTap() {
        player.seek(by: rewindInterval)
    }
}
