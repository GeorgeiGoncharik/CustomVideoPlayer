import Foundation
import AVFoundation

protocol VideoTherapyPlayerProtocol: AnyObject {
    var avPlayer: AVQueuePlayer {get}
    var isPlaying: Bool {get}
    var rate: PlaybackRates {get set}
    var delegate: VideoTherapyPlayerDelegate? {get set}
    func configure(with urls: [URL])
    func play()
    func pause()
    func togglePlayPause()
    func seek(to time: CMTime)
    func seek(by offset: TimeInterval)
    func enableSubtitles()
    func disableSubtitles()
}
