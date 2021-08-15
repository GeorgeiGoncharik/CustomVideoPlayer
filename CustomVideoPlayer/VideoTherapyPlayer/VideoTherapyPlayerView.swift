import UIKit
import AVFoundation

protocol VideoTherapyPlayerViewDelegate: AnyObject {
    func onTextTherapy(after itemIndex: Int)
    func onSwitchToTextTherapy()
    func onBackgroundMusic()
    func onClose()
}

class VideoTherapyPlayerView: UIView {
    struct Styles {
        static let playbackButtonWidth: CGFloat = 70
        static let rewindButtonWidth: CGFloat = 24
        static let playbackRateButtonWidth: CGFloat = 36
        static let playbackRateButtonHeight: CGFloat = 22
        static let mainControlsSpacing: CGFloat = 34
        static let additionalControlWidth: CGFloat = 32
        static let additionalControlsSpacing: CGFloat = 16
    }
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    private var player = VideoTherapyPlayer()
    weak var delegate: VideoTherapyPlayerViewDelegate?
    
    // main controls: reverse, play/pause, forward
    private var playbackButton = PlaybackButton()
    private var reverseForwardButton = RewindButton()
    private var forwardButton = RewindButton()
    private var mainControlsStack = UIStackView()
    private var playbackRateButton = PlaybackRateButton()
    // additional controls: text therapy, subtitles, bg music
    private var textTherapyButton = UIButton()
    private var subtitlesButton = UIButton()
    private var backgroundMusicButton = UIButton()
    private var additionalControlsStack = UIStackView()
    // timeline slider
    private var timelineSlider = TimelineSlider()
    private var timelineView = VideoTherapyProgressView()
    // close button
    private var closeButton = UIButton()
    
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
        playerLayer.videoGravity = .resize
        setUpMainControls()
        setUpAdditionalControls()
        setUpSlider()
        setUpProgress()
        setUpCloseButton()
    }
    
    private func setUpMainControls() {
        setUpPlaybackButton()
        setUpReverseForwardButton()
        setUpForwardButton()
        setUpPlaybackRateButton()
        setUpMainControlsStack()
    }
    
    private func setUpPlaybackButton() {
        playbackButton.configure(with: player)
        playbackButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setUpReverseForwardButton() {
        reverseForwardButton.configure(with: player, rewind: -15)
        reverseForwardButton.setImage(UIImage(named: "rewind-left"), for: .normal)
        reverseForwardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reverseForwardButton.widthAnchor.constraint(
                equalTo: reverseForwardButton.heightAnchor,
                multiplier: 1.0,
                constant: Styles.rewindButtonWidth)
        ])
    }
    
    private func setUpForwardButton() {
        forwardButton.configure(with: player, rewind: 15)
        forwardButton.setImage(UIImage(named: "rewind-right"), for: .normal)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forwardButton.widthAnchor.constraint(
                equalTo: forwardButton.heightAnchor,
                multiplier: 1.0,
                constant: Styles.rewindButtonWidth)
        ])
    }
    
    private func setUpPlaybackRateButton() {
        playbackRateButton.configure(with: player)
        playbackRateButton.updateUI()
        playbackRateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackRateButton.heightAnchor.constraint(equalToConstant: Styles.playbackRateButtonHeight),
            playbackRateButton.widthAnchor.constraint(equalToConstant: Styles.playbackRateButtonWidth)
        ])
    }
    
    private func setUpMainControlsStack() {
        func layoutPlaybackRateButton() {
            addSubview(playbackRateButton)
            playbackRateButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                playbackRateButton.centerYAnchor.constraint(equalTo: mainControlsStack.centerYAnchor),
                playbackRateButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
            ])
        }
        addSubview(mainControlsStack)
        mainControlsStack.addArrangedSubview(reverseForwardButton)
        mainControlsStack.addArrangedSubview(playbackButton)
        mainControlsStack.addArrangedSubview(forwardButton)
        mainControlsStack.axis = .horizontal
        mainControlsStack.alignment = .center
        mainControlsStack.distribution = .equalSpacing
        mainControlsStack.spacing = Styles.mainControlsSpacing
        mainControlsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainControlsStack.heightAnchor.constraint(equalToConstant: Styles.playbackButtonWidth),
            mainControlsStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            mainControlsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -42)
        ])
        layoutPlaybackRateButton()
    }
    
    private func setUpAdditionalControls() {
        setUpTextTherapyButton()
        setUpSubtitlesButton()
        setUpBackgroundMusicButton()
        setUpAdditionalControlsStack()
    }
    
    private func setUpTextTherapyButton() {
        textTherapyButton.setImage(UIImage(named: "text-therapy-on"), for: .normal)
        textTherapyButton.addTarget(self, action: #selector(onTextTherapyTapped), for: .touchUpInside)
        textTherapyButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textTherapyButton.widthAnchor.constraint(
                equalTo: textTherapyButton.heightAnchor,
                multiplier: 1.0,
                constant: Styles.additionalControlWidth)
        ])
    }
    
    private func setUpSubtitlesButton() {
        subtitlesButton.setImage(UIImage(named: "subtitles-on"), for: .normal)
        subtitlesButton.addTarget(self, action: #selector(onSubtitlesTapped), for: .touchUpInside)
        subtitlesButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitlesButton.widthAnchor.constraint(
                equalTo: subtitlesButton.heightAnchor,
                multiplier: 1.0,
                constant: Styles.additionalControlWidth)
        ])
    }
    
    private func setUpBackgroundMusicButton() {
        backgroundMusicButton.setImage(UIImage(named: "bg-music-on"), for: .normal)
        backgroundMusicButton.addTarget(self, action: #selector(onBackgroundMusicTapped), for: .touchUpInside)
        backgroundMusicButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundMusicButton.widthAnchor.constraint(
                equalTo: backgroundMusicButton.heightAnchor,
                multiplier: 1.0,
                constant: Styles.additionalControlWidth)
        ])
    }
    
    private func setUpAdditionalControlsStack() {
//        addSubview(additionalControlsStack)
//        additionalControlsStack.addArrangedSubview(textTherapyButton)
//        additionalControlsStack.addArrangedSubview(subtitlesButton)
//        additionalControlsStack.addArrangedSubview(backgroundMusicButton)
//        additionalControlsStack.axis = .vertical
//        additionalControlsStack.alignment = .center
//        additionalControlsStack.distribution = .equalSpacing
//        additionalControlsStack.spacing = Styles.additionalControlsSpacing
//        additionalControlsStack.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            additionalControlsStack.widthAnchor.constraint(equalToConstant: Styles.additionalControlWidth),
//            additionalControlsStack.widthAnchor.constraint(equalToConstant: Styles.additionalControlWidth),
//            additionalControlsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
//            additionalControlsStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16)
//        ])
        addSubview(textTherapyButton)
        addSubview(subtitlesButton)
        addSubview(backgroundMusicButton)
        NSLayoutConstraint.activate([
            textTherapyButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            textTherapyButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            subtitlesButton.topAnchor.constraint(equalTo: textTherapyButton.bottomAnchor, constant: Styles.additionalControlsSpacing),
            subtitlesButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backgroundMusicButton.topAnchor.constraint(equalTo: subtitlesButton.bottomAnchor, constant: Styles.additionalControlsSpacing),
            backgroundMusicButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        ])
    }
    
    private func setUpCloseButton() {
        addSubview(closeButton)
        closeButton.setImage(UIImage(named: "close-cross"), for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor, multiplier: 1.0, constant: Styles.additionalControlWidth),
            closeButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -8)
        ])
    }
    
    private func setUpSlider() {
        timelineSlider.addTarget(self, action: #selector(sliderValueDidChange(sender:event:)), for: .valueChanged)
        addSubview(timelineSlider)
        timelineSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timelineSlider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            timelineSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            timelineSlider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timelineSlider.bottomAnchor.constraint(equalTo: mainControlsStack.topAnchor, constant: -36)
        ])
    }
    
    private func setUpProgress() {
        addSubview(timelineView)
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timelineView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            timelineView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            timelineView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            timelineView.bottomAnchor.constraint(equalTo: timelineSlider.topAnchor, constant: -36)
        ])
    }
    
    func configure(with urls: [URL]) {
        player.configure(with: urls)
        player.play()
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
            player.seek(to: Double(sender.value))
        case .ended:
            player.play()
            break
        default:
            break
        }
   }
}

//MARK: -Selectors
extension VideoTherapyPlayerView {
    @objc private func onTextTherapyTapped() {
        player.pause()
        delegate?.onSwitchToTextTherapy()
    }
    
    @objc private func onSubtitlesTapped() {
        #warning("add code here")
    }
    
    @objc private func onBackgroundMusicTapped() {
        delegate?.onBackgroundMusic()
    }
    
    @objc private func onCloseTapped() {
        player.pause()
        delegate?.onClose()
    }
}

extension VideoTherapyPlayerView: VideoTherapyPlayerDelegate {
    func updateTimeline(with fraction: Double, at index: Int) {
        timelineView.updateUI(with: fraction, at: index)
    }
    
    func onPlaybackStatusChange() {
        if !timelineSlider.isTracking {
            playbackButton.updateUI()
        }
    }
    
    func reachedQuestionMark(mark: Int) {
        player.pause()
        delegate?.onTextTherapy(after: mark)
    }
    
    func updateTimeline(with time: CMTime) {
        if !timelineSlider.isTracking {
            timelineSlider.value = Float(time.seconds)
        }
    }
    
    func setUpTimeline(with durations: [CMTime]) {
        let maxValue = durations.map({$0.seconds}).reduce(0, {$0 + $1})
        timelineSlider.minimumValue = 0.0
        timelineSlider.maximumValue = Float(maxValue)
        timelineView.configure(with: durations.map { $0.seconds })
    }
    
    func refreshAfterRestart(with player: AVPlayer) {
        playerLayer.player = player
    }
}
