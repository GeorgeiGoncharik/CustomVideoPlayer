import UIKit

class PlaybackRateButton: UIButton {
    struct Constants {
        #warning("add assets")
        static let imageAssets: Dictionary<PlaybackRates, String> = [
            .one : "rate-1.75",
            .oneAndQuarter : "rate-1.75",
            .oneAndHalf : "rate-1.75",
            .oneAndThreeQuarters : "rate-1.75",
            .double : "rate-1.75"
        ]
    }

    private var rates = PlaybackRates.allCases
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
    
    @objc private func onTap() {
        let nextIndex = (rates.firstIndex(of: player.rate)! + 1)
        player.rate = rates[nextIndex < rates.count ? nextIndex : 0]
        updateUI()
    }
    
    func updateUI() {
        setImage(UIImage(named: Constants.imageAssets[player.rate]!), for: .normal)
    }
}
