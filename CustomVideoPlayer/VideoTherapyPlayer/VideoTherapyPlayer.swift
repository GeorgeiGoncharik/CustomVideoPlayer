import Foundation
import AVFoundation

protocol VideoTherapyPlayerDelegate: AnyObject {
    func refreshAfterRestart(with player: AVPlayer)
    func setUpTimeline(with durations: [CMTime])
    func updateTimeline(with fraction: Double, at index: Int)
    func onNextPlayerItem(after index: Int)
    func onPlaybackStatusChange()
    func onSubtitleTextChange(with text: String)
    func onShowLoader()
    func onHideLoader()
}

final class VideoTherapyPlayer: NSObject, VideoTherapyPlayerProtocol {
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
    private var isStall: Bool = true {
        didSet {
            isStall ? delegate?.onShowLoader() : delegate?.onHideLoader()
        }
    }
    weak var delegate: VideoTherapyPlayerDelegate?
    private(set) var avPlayer: AVQueuePlayer
    private var isSeekInProgress = false
    private var isEnabledSubtitles = false
    private var isFirstItem = true
    private var assets: [AVAsset] = []
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerQueueObserver: NSKeyValueObservation?
    private var playerPlaybackStatusObserver: NSKeyValueObservation?
    private var isPlaybackBufferEmptyObserver: NSKeyValueObservation?
    private var isPlaybackBufferFullObserver: NSKeyValueObservation?
    private var isPlaybackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    
    override init() {
        avPlayer = AVQueuePlayer()
        rate = .one
        super.init()
        registerObservers()
    }
    
    deinit {
        unregisterObservers()
    }
    
    func configure(with urls: [URL]) {
        assets = urls.map { url in
            let asset = AVAsset(url: url)
            let chars = asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
            print (chars)
            return asset
        }
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
    
    private func seek(to time: CMTime) {
        guard !isSeekInProgress, avPlayer.status == .readyToPlay else {
            return
        }
        isSeekInProgress = true
        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            self.isSeekInProgress = false
            self.avPlayer.play()
        }
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
        registerBufferingObservers()
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
            self.isSeekInProgress = false
            let captionOutput = AVPlayerItemLegibleOutput()
            captionOutput.setDelegate(self, queue: .main)
            self.avPlayer.currentItem?.add(captionOutput)
            if self.isFirstItem {
                self.isFirstItem = false
                return
            }
            self.avPlayer.pause()
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
    
    private func registerBufferingObservers() {
        self.isPlaybackBufferFullObserver = avPlayer.currentItem?.observe(\.isPlaybackBufferFull, options: [.new]) { [weak self] _, change in
            guard let self = self, let isFull = change.newValue else {
                return
            }
            self.isStall = !isFull
        }
        
        self.isPlaybackBufferEmptyObserver = avPlayer.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] _, change in
            guard let self = self, let isEmpty = change.newValue else {
                return
            }
            self.isStall = isEmpty
        }
        
        self.isPlaybackLikelyToKeepUpObserver = avPlayer.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] _, change in
            guard let self = self, let isKeepUp = change.newValue else {
                return
            }
            self.isStall = !isKeepUp
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
        
        isPlaybackBufferEmptyObserver?.invalidate()
        isPlaybackBufferEmptyObserver = nil
        isPlaybackBufferFullObserver?.invalidate()
        isPlaybackBufferFullObserver = nil
        isPlaybackLikelyToKeepUpObserver?.invalidate()
        isPlaybackLikelyToKeepUpObserver = nil
    }
}

//MARK: - VideoTherapyPlayerProtocol conformation
extension VideoTherapyPlayer {
    func toggleSubtitles() {
        isEnabledSubtitles.toggle()
        if let mediaSelectionGroup = avPlayer.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            avPlayer.currentItem?.select(isEnabledSubtitles ? mediaSelectionGroup.options[0] : nil, in: mediaSelectionGroup)
        }
    }
        
    func seek(_ type: SeekType) {
        switch type {
        case .start:
            let time: CMTime = .zero
            seek(to: time)
        case .end:
            guard let duration = avPlayer.currentItem?.duration else {
                return
            }
            seek(to: duration)
        case .offset(let interval):
            guard let duration = avPlayer.currentItem?.duration else {
                return
            }
            let current = avPlayer.currentTime()
            let offset = CMTime(seconds: abs(interval), preferredTimescale: current.timescale)
            let time = interval < 0 ? current - offset : current + offset
            if time > duration {
                seek(.end)
            } else if time < .zero {
                seek(.start)
            } else {
                seek(to: time)
            }
        case .time(let time):
            seek(to: time)
        }
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

//MARK:- AVPlayerItemLegibleOutputPushDelegate conformation. Subtitles
extension VideoTherapyPlayer: AVPlayerItemLegibleOutputPushDelegate {
    func legibleOutput(_ output: AVPlayerItemLegibleOutput,
                       didOutputAttributedStrings strings: [NSAttributedString],
                       nativeSampleBuffers nativeSamples: [Any],
                       forItemTime itemTime: CMTime) {
        print(strings)
        guard let string = strings.first?.string else {
            return
        }
        delegate?.onSubtitleTextChange(with: string)
    }
}
