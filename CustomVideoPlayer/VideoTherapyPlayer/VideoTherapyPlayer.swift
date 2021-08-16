import Foundation
import AVFoundation

protocol VideoTherapyPlayerDelegate: AnyObject {
    func refreshAfterRestart(with player: AVPlayer)
    func setUpTimeline(with durations: [CMTime])
    func updateTimeline(with fraction: Double, at index: Int)
    func onNextPlayerItem(after index: Int)
    func onPlaybackStatusChange()
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
    private(set) var avPlayer: AVQueuePlayer
    private var assets: [AVAsset] = []
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerQueueObserver: NSKeyValueObservation?
    private var playerPlaybackStatusObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    
    init() {
        avPlayer = AVQueuePlayer()
        rate = .one
        registerObservers()
    }
    
    deinit {
        unregisterObservers()
    }
    
    func configure(with urls: [URL]) {
        assets = urls.map { url in AVAsset(url: url) }
        setUpPlayerItems()
    }
        
    //MARK: - Private methods
    private func restart() {
        avPlayer = AVQueuePlayer()
        setUpPlayerItems()
        delegate?.refreshAfterRestart(with: avPlayer)
    }
    
    private func setUpPlayerItems() {
        avPlayer.removeAllItems()
        assets
            .map { asset in AVPlayerItem(asset: asset) }
            .forEach { item in avPlayer.insert(item, after: nil) }
        setUpTimeline()
        registerObservers()
    }
    
    private func setUpTimeline() {
        let durations = assets.map { $0.duration }
        delegate?.setUpTimeline(with: durations)
    }
    
    private func getCurrentItemIndex() -> Int {
        assets.count - avPlayer.items().count
    }
    
    private func getPlayedTimeBeforeCurrentItem() -> CMTime {
        let curIndex = getCurrentItemIndex()
        var playedTime: CMTime = .zero
        for (index, _) in avPlayer.items().enumerated() where index < curIndex {
            playedTime = playedTime + assets[index].duration
        }
        return playedTime
    }
}

//MARK: - Observations
fileprivate extension VideoTherapyPlayer {
    private func registerObservers() {
        unregisterObservers()
        registerPlayerStatusObserver()
        registerPlayerItemStatusObserver()
        registerPeriodicTimeObserver()
        registerCurrentItemObserver()
        registerPlaybackStatusObserver()
    }
    
    private func registerPlayerStatusObserver() {
        playerStatusObserver = avPlayer.observe(\.status, options: [.new]) { [weak self] player, _ in
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
        }
    }
    
    private func registerPlayerItemStatusObserver() {
        playerItemStatusObserver = avPlayer.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            switch (item.status) {
            case .failed:
                self?.restart()
                print("playerItem status: [\(String(describing: item.error))]")
            case .readyToPlay:
                print("playerItem status: [.readyToPlay]")
                self?.play()
            case .unknown:
                print("playerItem status: [.unknown]")
            @unknown default:
                print("playerItem status: [@unknown default]")
            }
        }
    }
    
    private func registerPeriodicTimeObserver() {
        periodicTimeObserver = avPlayer.addPeriodicTimeObserver(
            forInterval: Constants.periodicObservationInterval,
            queue: .main) { [weak self] time in
            guard let self = self else {
                return
            }
            let itemDuration = self.avPlayer.currentItem?.duration.seconds
            guard let itemDuration = itemDuration, !itemDuration.isNaN else {
                return
            }
            let fraction = time.seconds / itemDuration
            let index = self.getCurrentItemIndex()
            self.delegate?.updateTimeline(with: fraction, at: index)
        }
    }
    
    private func registerCurrentItemObserver() {
        playerQueueObserver = self.avPlayer.observe(\.currentItem, options: [.new]) { [weak self] _, _ in
            guard let self = self else {
                return
            }
            let index = self.getCurrentItemIndex()
            self.delegate?.onNextPlayerItem(after: index)
        }
    }
    
    private func registerPlaybackStatusObserver()  {
        self.playerPlaybackStatusObserver = avPlayer.observe(\.timeControlStatus,
                                                             options: [.new, .old]) { [weak self] _, _ in
            self?.delegate?.onPlaybackStatusChange()
        }
    }
    
    private func unregisterObservers() {
        playerStatusObserver?.invalidate()
        playerStatusObserver = nil
        
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil
        
        playerQueueObserver?.invalidate()
        playerQueueObserver = nil
        
        playerPlaybackStatusObserver?.invalidate()
        playerPlaybackStatusObserver = nil
        
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
        let cmCurrent = avPlayer.currentTime()
        let cmOffset = CMTime(seconds: abs(offset), preferredTimescale: cmCurrent.timescale)
        let cmTarget = offset < 0 ? cmCurrent - cmOffset : cmCurrent + cmOffset
        seek(to: cmTarget)
    }
    
    func seek(to time: CMTime) {
        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .positiveInfinity)
        avPlayer.play()
    }

    func play() {
        if avPlayer.currentItem?.status == .readyToPlay {
            avPlayer.rate = rate.rawValue
        }
    }
    
    func pause() {
        avPlayer.pause()
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }
}
