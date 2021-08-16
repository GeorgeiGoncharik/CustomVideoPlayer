import UIKit
import AVFoundation

protocol VideoTherapyPlayerViewDelegate: AnyObject {
    func onTextTherapy(after itemIndex: Int)
    func onBackgroundMusic()
    func onClose()
}

class VideoTherapyPlayerView: UIView {
    struct Constants {
        static let playbackButtonWidth: CGFloat = 70
        static let rewindButtonWidth: CGFloat = 24
        static let playbackRateButtonWidth: CGFloat = 36
        static let playbackRateButtonHeight: CGFloat = 22
        static let mainControlsSpacing: CGFloat = 34
        static let additionalControlWidth: CGFloat = 32
        static let additionalControlsSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 24
        static let mainControlsBottomPadding: CGFloat = 42
        static let animationTime: TimeInterval = 1.0
        static let smallVeticalPadding: CGFloat = 8.0
    }
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    
    private var player = VideoTherapyPlayer()
    weak var delegate: VideoTherapyPlayerViewDelegate?
    private var isControlsHidden = false
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
    private var timelineView = VideoTherapyTimelineView()
    // close button
    private var closeButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        player.delegate = self
        initView()
        initTouchRecognizer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        playerLayer.player = player.avPlayer
        #warning("set to .resize")
        playerLayer.videoGravity = .resizeAspect
        setUpMainControls()
        setUpAdditionalControls()
        setUpProgressView()
        setUpCloseButton()
    }
    
    private func initTouchRecognizer() {
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
        touchGesture.numberOfTapsRequired = 1
        isUserInteractionEnabled = true
        addGestureRecognizer(touchGesture)
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
        NSLayoutConstraint.activate([
            playbackButton.widthAnchor.constraint(equalToConstant: Constants.playbackButtonWidth),
            playbackButton.heightAnchor.constraint(equalTo: playbackButton.widthAnchor)
        ])
    }
    
    private func setUpReverseForwardButton() {
        reverseForwardButton.configure(with: player, rewind: -15)
        reverseForwardButton.setImage(UIImage(named: "rewind-left"), for: .normal)
        reverseForwardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reverseForwardButton.widthAnchor.constraint(equalToConstant: Constants.rewindButtonWidth),
            reverseForwardButton.heightAnchor.constraint(equalTo: reverseForwardButton.widthAnchor)
        ])
    }
    
    private func setUpForwardButton() {
        forwardButton.configure(with: player, rewind: 15)
        forwardButton.setImage(UIImage(named: "rewind-right"), for: .normal)
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forwardButton.widthAnchor.constraint(equalToConstant: Constants.rewindButtonWidth),
            forwardButton.heightAnchor.constraint(equalTo: forwardButton.widthAnchor)
        ])
    }
    
    private func setUpPlaybackRateButton() {
        playbackRateButton.configure(with: player)
        playbackRateButton.updateUI()
        playbackRateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackRateButton.heightAnchor.constraint(equalToConstant: Constants.playbackRateButtonHeight),
            playbackRateButton.widthAnchor.constraint(equalToConstant: Constants.playbackRateButtonWidth)
        ])
    }
    
    private func setUpMainControlsStack() {
        func layoutPlaybackRateButton() {
            addSubview(playbackRateButton)
            NSLayoutConstraint.activate([
                playbackRateButton.centerYAnchor.constraint(equalTo: mainControlsStack.centerYAnchor),
                playbackRateButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding)
            ])
        }
        addSubview(mainControlsStack)
        mainControlsStack.addArrangedSubview(reverseForwardButton)
        mainControlsStack.addArrangedSubview(playbackButton)
        mainControlsStack.addArrangedSubview(forwardButton)
        mainControlsStack.axis = .horizontal
        mainControlsStack.alignment = .center
        mainControlsStack.distribution = .equalSpacing
        mainControlsStack.spacing = Constants.mainControlsSpacing
        mainControlsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainControlsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainControlsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.mainControlsBottomPadding)
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
            textTherapyButton.widthAnchor.constraint(equalToConstant: Constants.additionalControlWidth),
            textTherapyButton.heightAnchor.constraint(equalTo: textTherapyButton.widthAnchor)
        ])
    }
    
    private func setUpSubtitlesButton() {
        subtitlesButton.setImage(UIImage(named: "subtitles-on"), for: .normal)
        subtitlesButton.addTarget(self, action: #selector(onSubtitlesTapped), for: .touchUpInside)
        subtitlesButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitlesButton.widthAnchor.constraint(equalToConstant: Constants.additionalControlWidth),
            subtitlesButton.heightAnchor.constraint(equalTo: subtitlesButton.widthAnchor)
        ])
    }
    
    private func setUpBackgroundMusicButton() {
        backgroundMusicButton.setImage(UIImage(named: "bg-music-on"), for: .normal)
        backgroundMusicButton.addTarget(self, action: #selector(onBackgroundMusicTapped), for: .touchUpInside)
        backgroundMusicButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundMusicButton.widthAnchor.constraint(equalToConstant: Constants.additionalControlWidth),
            backgroundMusicButton.heightAnchor.constraint(equalTo: backgroundMusicButton.widthAnchor)
        ])
    }
    
    private func setUpAdditionalControlsStack() {
        addSubview(additionalControlsStack)
        additionalControlsStack.addArrangedSubview(textTherapyButton)
        additionalControlsStack.addArrangedSubview(subtitlesButton)
        additionalControlsStack.addArrangedSubview(backgroundMusicButton)
        additionalControlsStack.axis = .vertical
        additionalControlsStack.alignment = .center
        additionalControlsStack.distribution = .equalSpacing
        additionalControlsStack.spacing = Constants.additionalControlsSpacing
        additionalControlsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            additionalControlsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding),
            additionalControlsStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding)
        ])
    }
    
    private func setUpCloseButton() {
        addSubview(closeButton)
        closeButton.setImage(UIImage(named: "close-cross"), for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Constants.additionalControlWidth),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Constants.topPadding),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding)
        ])
    }
    private func setUpProgressView() {
        addSubview(timelineView)
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timelineView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalPadding),
            timelineView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalPadding),
            timelineView.bottomAnchor.constraint(equalTo: mainControlsStack.topAnchor, constant: -Constants.smallVeticalPadding)
        ])
    }
    
    func configure(with urls: [URL]) {
        player.configure(with: urls)
        player.play()
    }
    
    private func toggleControls() {
        isControlsHidden.toggle()
        if !isControlsHidden {
            subviews.forEach { $0.isHidden = false }
        }
        UIView.animate(
            withDuration: Constants.animationTime,
            animations: { [weak self] in self?.subviews.forEach { $0.alpha = self!.isControlsHidden ? 0 : 1 } },
            completion: { [weak self] _ in self?.subviews.forEach { $0.isHidden = self!.isControlsHidden } }
        )
    }
}

//MARK: -Selectors
extension VideoTherapyPlayerView {
    @objc private func onTextTherapyTapped() {
        player.seek(to: player.avPlayer.currentItem?.duration ?? .positiveInfinity)
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
    
    @objc private func onTapGesture() {
        toggleControls()
    }
}

extension VideoTherapyPlayerView: VideoTherapyPlayerDelegate {
    func updateTimeline(with fraction: Double, at index: Int) {
        timelineView.updateUI(with: fraction, at: index)
    }
    
    func onPlaybackStatusChange() {
        playbackButton.updateUI()
    }
    
    func onNextPlayerItem(after index: Int) {
        player.pause()
        delegate?.onTextTherapy(after: index)
    }
        
    func setUpTimeline(with durations: [CMTime]) {
        timelineView.configure(with: durations.map { $0.seconds })
    }
    
    func refreshAfterRestart(with player: AVPlayer) {
        playerLayer.player = player
    }
}
