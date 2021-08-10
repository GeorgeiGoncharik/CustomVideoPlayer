import UIKit

class PlaybackRateButton: UIButton {
    struct Constants {
        static let imageAssets: Dictionary<PlaybackRates, String> = [
            .one : "a.circle",
            .oneAndQuarter : "b.circle",
            .oneAndHalf : "c.circle",
            .oneAndThreeQuarters : "d.circle",
            .double : "e.circle"
        ]
    }

    private var rates = PlaybackRates.allCases
    private var player: VideoTherapyPlayerProtocol! {
        didSet {
            updateUI()
        }
    }
    
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
    
    private func updateUI() {
        setImage(UIImage(systemName: Constants.imageAssets[player.rate] ?? "questionmark.circle"), for: .normal)
    }
}
