import UIKit
import AVFoundation

protocol VideoTherapyPlayerViewDelegate: AnyObject {
    func didTapBackgroundMusicButton()
    func didTapCloseTherapyButton()
    func didReachQuestionMark(_ mark: Int)
}

class VideoTherapyPlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    private var player: VideoTherapyPlayerProtocol = VideoTherapyPlayer()
    weak var delegate: VideoTherapyPlayerViewDelegate?
    
    // main controls: reverse, play/pause, forward
    private var playbackButton = PlaybackButton()
    private var reverseForwardButton = UIButton()
    private var forwardButton = UIButton()
    private var mainControlStack = UIStackView()
    // timeline slider
    private var timelineSlider = TimelineSlider()
    // background music button
    private var backgroundMusicButton = UIButton()
    // close button
    private var closeButton = UIButton()
    private var changeRateButton = PlaybackRateButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        player.delegate = self
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        playerLayer.player = player.avPlayer
        playerLayer.cornerRadius = 20
        playerLayer.masksToBounds = true
        playerLayer.videoGravity = .resize
        
        setUpMainControls()
        setUpPlaybackButton()
        setUpCloseButton()
        setUpBackgroundMusicButton()
        setUpSlider()
        setUpChangeRateButton()
    }
    
    private func setUpSlider() {
        timelineSlider.addTarget(self, action: #selector(sliderValueDidChange(sender:event:)), for: .valueChanged)
        addSubview(timelineSlider)
        timelineSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timelineSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            timelineSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            timelineSlider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timelineSlider.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -24)
        ])
    }
    
    private func setUpMainControls() {
        reverseForwardButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        forwardButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        
        reverseForwardButton.addTarget(self, action: #selector(reverseTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)

       
        mainControlStack.addArrangedSubview(reverseForwardButton)
        mainControlStack.addArrangedSubview(playbackButton)
        mainControlStack.addArrangedSubview(forwardButton)
        mainControlStack.axis = .horizontal
        mainControlStack.alignment = .center
        mainControlStack.distribution = .equalSpacing
        mainControlStack.spacing = 16
        
        addSubview(mainControlStack)
        
        mainControlStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainControlStack.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 6.0/10.0),
            mainControlStack.heightAnchor.constraint(equalToConstant: 20),
            mainControlStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            mainControlStack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    private func setUpCloseButton() {
        addSubview(closeButton)
        closeButton.setImage(UIImage(systemName: "circle.grid.cross"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor, multiplier: 1.0),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16)
        ])
    }
    
    private func setUpBackgroundMusicButton() {
        addSubview(backgroundMusicButton)
        backgroundMusicButton.setImage(UIImage(systemName: "music.note.house"), for: .normal)
        backgroundMusicButton.addTarget(self, action: #selector(backgroundMusicTapped), for: .touchUpInside)
        backgroundMusicButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundMusicButton.heightAnchor.constraint(equalTo: backgroundMusicButton.widthAnchor, multiplier: 1.0),
            backgroundMusicButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            backgroundMusicButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16)
        ])
    }
    
    private func setUpChangeRateButton() {
        changeRateButton.configure(with: player)
        addSubview(changeRateButton)
        changeRateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            changeRateButton.heightAnchor.constraint(equalTo: changeRateButton.widthAnchor, multiplier: 1.0),
            changeRateButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            changeRateButton.leadingAnchor.constraint(equalTo: self.backgroundMusicButton.trailingAnchor, constant: 16)
        ])
    }
    
    private func setUpPlaybackButton() {
        playbackButton.configure(with: player)
    }
    
    func configure(with playerItem: AVPlayerItem) {
        player.configure(with: playerItem)
        player.play()
    }
    
    func set(marks: [Int]) {
        player.set(marks: marks)
    }
    
    @objc private func forwardTapped() {
        player.seek(by: TimeInterval(15))
    }
    
    @objc private func reverseTapped() {
        player.seek(by: TimeInterval(-15))
    }
    
    @objc private func closeTapped() {
        delegate?.didTapCloseTherapyButton()
    }
    
    @objc private func backgroundMusicTapped() {
        delegate?.didTapBackgroundMusicButton()
    }
    
    @objc private func sliderValueDidChange(sender: UISlider, event: UIEvent) {
        guard let touch = event.allTouches?.first else {
            return
        }
        switch touch.phase {
        case .began:
            player.pause()
            break
        case .moved:
            let newTime = CMTime(seconds: Double(sender.value),
                                 preferredTimescale: player.avPlayer.currentTime().timescale)
            player.seek(to: newTime)
        case .ended:
            player.play()
            break
        default:
            break
        }
   }
}

extension VideoTherapyPlayerView: VideoTherapyPlayerDelegate {
    func reachedQuestionMark(mark: Int) {
        player.pause()
        delegate?.didReachQuestionMark(mark)
    }
    
    func updateTimeline(with time: CMTime) {
        if !timelineSlider.isTracking {
            timelineSlider.value = Float(time.seconds)
        }
    }
    
    func setUpTimeline(with item: AVPlayerItem) {
        timelineSlider.minimumValue = 0.0
        timelineSlider.maximumValue = Float(item.duration.seconds)
    }
    
    func refreshAfterRestart(with player: AVPlayer) {
        playerLayer.player = player
    }
}
