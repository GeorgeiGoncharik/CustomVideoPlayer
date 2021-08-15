import Foundation
import AVFoundation

protocol VideoTherapyPlayerDelegate: AnyObject {
    func refreshAfterRestart(with player: AVPlayer)
    func setUpTimeline(with durations: [CMTime])
    func updateTimeline(with time: CMTime)
    func updateTimeline(with fraction: Double, at index: Int)
    func reachedQuestionMark(mark: Int)
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
    private var questionMarks: [CMTime] = []
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerQueueObserver: NSKeyValueObservation?
    private var playerPlaybackStatusObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    private var boundaryTimeObserver: Any?
    
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
                #warning("setUpTimeline somewhere else")
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
        periodicTimeObserver = avPlayer.addPeriodicTimeObserver(forInterval: Constants.periodicObservationInterval,
                                                                queue: .main) { [weak self] time in
            guard let self = self else {
                return
            }
            let timeTotal = self.getPlayedTimeBeforeCurrentItem() + time
            self.delegate?.updateTimeline(with: timeTotal)
            let fraction = (time.seconds / self.avPlayer.currentItem!.duration.seconds)
            let index = self.getCurrentItemIndex()
            self.delegate?.updateTimeline(with: fraction, at: index)
        }
    }
    
    private func registerQuestionMarksObserver() {
        let values = questionMarks.map { NSValue(time:$0) }
        boundaryTimeObserver = avPlayer.addBoundaryTimeObserver(forTimes: values,
                                                                queue: .main) { [weak self] in
            self?.delegate?.reachedQuestionMark(mark: Int((self?.avPlayer.currentTime().seconds)!))
        }
    }
    
    private func registerCurrentItemObserver() {
        playerQueueObserver = self.avPlayer.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
            #warning("notify viewModel about next play item")
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
        boundaryTimeObserver = nil
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
        seek(to: cmTarget.seconds)
    }
    
    func seek(to time: TimeInterval) {
        let itemDuration = avPlayer.currentItem?.duration ?? .zero
        let seekTime = CMTime(seconds: Double(time),
                             preferredTimescale: avPlayer.currentTime().timescale)
        let itemSeekTime = seekTime - getPlayedTimeBeforeCurrentItem()
        var resultTime: CMTime = itemSeekTime
        if itemSeekTime < .zero {
            resultTime = .zero
        }
        else if itemSeekTime > itemDuration {
            resultTime = itemDuration
        }
        avPlayer.seek(to: resultTime)
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
    
    func set(marks: [Int]) {
        let timescale = avPlayer.currentTime().timescale
        questionMarks = marks.map { CMTime(seconds: Double($0), preferredTimescale: timescale)}
        registerQuestionMarksObserver()
    }
}
