import Foundation
import AVFoundation

protocol VideoTherapyPlayerDelegate: AnyObject {
    func refreshAfterRestart(with player: AVPlayer)
    func setUpTimeline(with item: AVPlayerItem)
    func updateTimeline(with time: CMTime)
}

final class VideoTherapyPlayer: VideoTherapyPlayerProtocol {
    
    struct Constants {
        static let periodicObservationInterval = CMTime(seconds: 0.5,
                                                        preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    var rate: PlaybackRates {
        didSet {
            if(isPlaying) {
                avPlayer.rate = rate.rawValue
            }
        }
    }
    var isPlaying: Bool {
        get {
            avPlayer.rate != 0 && avPlayer.error == nil
        }
    }
    weak var delegate: VideoTherapyPlayerDelegate?
    private(set) var avPlayer: AVPlayer
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    
    init() {
        avPlayer = AVPlayer()
        rate = .one
        registerObservers()
    }
    
    deinit {
        unregisterObservers()
    }
    
    func configure(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        configure(with: playerItem)
    }
    
    func configure(with item: AVPlayerItem) {
        avPlayer.replaceCurrentItem(with: item)
        registerObservers()
    }
    
    //MARK: - Private methods
    private func restart() {
        let currentItem = avPlayer.currentItem
        avPlayer = AVPlayer(playerItem: currentItem)
        registerObservers()
        delegate?.refreshAfterRestart(with: avPlayer)
    }
}

//MARK: - Observations
fileprivate extension VideoTherapyPlayer {
    private func registerObservers() {
        unregisterObservers()
        registerPlayerObserver()
        registerPlayerItemObserver()
        registerPeriodicTimeObserver()
    }
    
    private func registerPlayerObserver() {
        playerStatusObserver = avPlayer.observe(\.status, changeHandler: { [weak self] player, _ in
            switch (player.status) {
            case .failed:
                self?.restart()
                print("player status: [\(String(describing: player.error))]")
            case .readyToPlay:
                print("player status: [.readyToPlay]")
            case .unknown:
                print("player status: [.unknown]")
            @unknown default:
                print("player status: [@unknown default]")
            }
        })
    }
    
    private func registerPlayerItemObserver() {
        playerItemStatusObserver = avPlayer.currentItem?.observe(\.status, changeHandler: { [weak self] item, _ in
            switch (item.status) {
            case .failed:
                self?.restart()
                print("playerItem status: [\(String(describing: item.error))]")
            case .readyToPlay:
                self?.delegate?.setUpTimeline(with: item)
                print("playerItem status: [.readyToPlay]")
                self?.play()
            case .unknown:
                print("playerItem status: [.unknown]")
            @unknown default:
                print("playerItem status: [@unknown default]")
            }
        })
    }
    
    private func registerPeriodicTimeObserver() {
        periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: Constants.periodicObservationInterval,
                                                                queue: .main) { [weak self] time in
            self?.delegate?.updateTimeline(with: time)
        }
    }
    
    private func unregisterObservers() {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil
        
        periodicTimeObserver = nil
    }
}

//MARK: - VideoTherapyPlayerProtocol conformation

extension VideoTherapyPlayer {
    func enableSubtitles() {
        // later
    }
    
    func disableSubtitles() {
        // later
    }
        
    func seek(by offset: TimeInterval) {
        let isNegative = offset < 0
        let cmCurrent = avPlayer.currentTime()
        let cmOffset = CMTime(seconds: isNegative ? -offset : offset,
                                preferredTimescale: cmCurrent.timescale)
        let cmTarget = isNegative ? cmCurrent - cmOffset : cmCurrent + cmOffset
        seek(to: cmTarget)
    }
    
    func seek(to time: CMTime) {
        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func play() {
        if avPlayer.currentItem?.status == .readyToPlay {
            avPlayer.rate = rate.rawValue
        }
    }
    
    func pause() {
        avPlayer.pause()
    }
}
