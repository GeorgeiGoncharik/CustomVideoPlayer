import UIKit

class VideoTherapyTimelineView: UIView {
    struct Constants {
        static let spacing: CGFloat = 2.0
        static let progressHeight: CGFloat = 4.0
        static let labelSpacing: CGFloat = 12.0
    }
    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        return formatter
    }()
    private var times: [TimeInterval] = []
    private var currentTime: Double = 0
    private var totalTime: Double = 0
    private var currentItemIndex = -1
    private var progresses: [VideoTherapySliderView] = []
    private var currentTimeLabel = UILabel()
    private var totalTimeLabel = UILabel()
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpStack()
        setUpLabels()
    }
    
    private func setUpStack() {
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 2.0/3.0)
        ])
    }
    
    private func setUpLabels() {
        addSubview(currentTimeLabel)
        addSubview(totalTimeLabel)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.textColor = .white
        totalTimeLabel.textColor = .white
        currentTimeLabel.textAlignment = .left
        totalTimeLabel.textAlignment = .right
        NSLayoutConstraint.activate([
            currentTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            currentTimeLabel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: Constants.labelSpacing),
            currentTimeLabel.trailingAnchor.constraint(equalTo: centerXAnchor),
            currentTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            totalTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            totalTimeLabel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: Constants.labelSpacing),
            totalTimeLabel.leadingAnchor.constraint(equalTo: centerXAnchor),
            totalTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        updateLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with times: [TimeInterval]) {
        freeStack()
        let filtered = times.filter { $0 > 0 }
        self.times = filtered.count > 0 ? filtered : [100.0]
        self.totalTime = self.times.reduce(0, { $0 + $1 })
        for time in self.times {
            let progressView = VideoTherapySliderView()
            progressView.minimumValue = 0.0
            progressView.maximumValue = Float(time)
            addSubview(progressView)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                progressView.heightAnchor.constraint(equalToConstant: Constants.progressHeight),
                progressView.widthAnchor.constraint(equalTo: widthAnchor,
                                                    multiplier: CGFloat(time / totalTime),
                                                    constant: -Constants.spacing)
            ])
            progresses.append(progressView)
            stack.addArrangedSubview(progressView)
        }
    }
    
    func updateUI(with progress: Double, at index: Int) {
        progresses
            .filter { $0 != progresses[index] }
            .forEach { $0.setThumbImage(UIImage(), for: .normal) }
        progresses[index]
            .updateUI(with: Float(progress))
        currentTime = (progress * times[index]) + times.prefix(index).reduce(0, +)
        updateLabels()
        if index != currentItemIndex {
            currentItemIndex = index
            updatePins()
        }
        
    }
    
    private func updatePins() {
        progresses.forEach { $0.hidePin() }
        progresses[currentItemIndex].showPin()
    }
    
    private func updateLabels() {
        currentTimeLabel.text = formatter.string(from: currentTime)
        totalTimeLabel.text = formatter.string(from: totalTime)
    }
    
    private func freeStack() {
        stack.arrangedSubviews.forEach { [weak self] view in
            self?.stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

class VideoTherapyProgressView: UIProgressView {
    struct Constants {
        static let verticalSpacing: CGFloat = 2.0
        static let horizontalSpacing: CGFloat = 1.0
        static let animationTime: TimeInterval = 1.0
    }
    
    private lazy var questionPinImage: UIImageView = {
        let image = UIImage(named: "place-pin")
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        trackTintColor = UIColor(named: "player-progress-secondary")
        tintColor = UIColor(named: "player-progress-tint")
        setUpImageView()
    }
    
    private func setUpImageView() {
        addSubview(questionPinImage)
        questionPinImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionPinImage.centerXAnchor.constraint(equalTo: trailingAnchor, constant: Constants.horizontalSpacing),
            questionPinImage.bottomAnchor.constraint(equalTo: topAnchor, constant: -Constants.verticalSpacing)
        ])
        questionPinImage.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hidePin() {
        guard !questionPinImage.isHidden else {
            return
        }
        UIView.animate(
            withDuration: Constants.animationTime,
            animations: { [weak self] in
                self?.questionPinImage.alpha = 0.0
            }, completion: { [weak self] complete in
                self?.questionPinImage.isHidden = true
            }
        )
    }
    
    func showPin() {
        guard questionPinImage.isHidden else {
            return
        }
        questionPinImage.isHidden = false
        UIView.animate(
            withDuration: Constants.animationTime,
            animations: { [weak self] in
                self?.questionPinImage.alpha = 1.0
            }
        )
    }
}

class VideoTherapySliderView: UISlider {
    struct Constants {
        static let verticalSpacing: CGFloat = 2.0
        static let horizontalSpacing: CGFloat = 1.0
        static let animationTime: TimeInterval = 1.0
    }
    
    private lazy var questionPinImage: UIImageView = {
        let image = UIImage(named: "place-pin")
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        minimumTrackTintColor = UIColor(named: "player-progress-tint")
        maximumTrackTintColor = UIColor(named: "player-progress-secondary")
        tintColor = UIColor(named: "player-progress-tint")
        setThumbImage(UIImage(), for: .normal)
        isUserInteractionEnabled = false
        setUpImageView()
    }
    
    private func setUpImageView() {
        addSubview(questionPinImage)
        questionPinImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionPinImage.centerXAnchor.constraint(equalTo: trailingAnchor, constant: Constants.horizontalSpacing),
            questionPinImage.bottomAnchor.constraint(equalTo: topAnchor, constant: -Constants.verticalSpacing)
        ])
        questionPinImage.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateUI(with fractionValue: Float) {
        value = fractionValue * maximumValue
        if value > minimumValue && value <= maximumValue {
            setThumbImage(UIImage(named: "slider-thumb"), for: .normal)
        } else {
            setThumbImage(UIImage(), for: .normal)
        }
    }
    
    func hidePin() {
        guard !questionPinImage.isHidden else {
            return
        }
        UIView.animate(
            withDuration: Constants.animationTime,
            animations: { [weak self] in
                self?.questionPinImage.alpha = 0.0
            }, completion: { [weak self] complete in
                self?.questionPinImage.isHidden = true
            }
        )
    }
    
    func showPin() {
        guard questionPinImage.isHidden else {
            return
        }
        questionPinImage.isHidden = false
        UIView.animate(
            withDuration: Constants.animationTime,
            animations: { [weak self] in
                self?.questionPinImage.alpha = 1.0
            }
        )
    }
}
