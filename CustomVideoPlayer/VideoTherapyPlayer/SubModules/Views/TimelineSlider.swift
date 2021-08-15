import UIKit

class TimelineSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.minX, y: bounds.midY)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: 10))
    }
}

class VideoTherapyProgressView: UIView {
    struct Styles {
        static let spacing: CGFloat = 2.0
        static let progressHeight: CGFloat = 10.0
    }
    
    private var times: [TimeInterval] = []
    private var totalTime: Double = 0
    private var progresses: [VideoTherapyProgressLineView] = []
    private var stack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = Styles.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.heightAnchor.constraint(equalToConstant: Styles.progressHeight),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with times: [TimeInterval]) {
        self.times = times
        self.totalTime = times.reduce(0, { $0 + $1 })
        for time in times {
            let progressView = VideoTherapyProgressLineView()
            addSubview(progressView)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                progressView.heightAnchor.constraint(equalToConstant: Styles.progressHeight),
                progressView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(time / totalTime))
            ])
            progresses.append(progressView)
            stack.addArrangedSubview(progressView)
        }

    }
    
    func updateUI(with progress: Double, at index: Int) {
        progresses[index].progress = Float(progress)
    }
}

class VideoTherapyProgressLineView: UIProgressView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        trackTintColor = UIColor(named: "player-progress-secondary")
        tintColor = UIColor(named: "player-progress-tint")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//            if let prev = progresses.last {
//                NSLayoutConstraint.activate([
//                    progressView.topAnchor.constraint(equalTo: topAnchor),
//                    progressView.heightAnchor.constraint(equalToConstant: Styles.progressHeight),
//                    progressView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(time / totalTime)),
//                    progressView.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Styles.spacing)
//                ])
//            } else {
//                NSLayoutConstraint.activate([
//                    progressView.topAnchor.constraint(equalTo: topAnchor),
//                    progressView.heightAnchor.constraint(equalToConstant: Styles.progressHeight),
//                    progressView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(time / totalTime)),
//                    progressView.leadingAnchor.constraint(equalTo: leadingAnchor)
//                ])
//            }
