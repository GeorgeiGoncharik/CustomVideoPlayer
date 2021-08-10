import UIKit
import AVFoundation
import AVKit
import Combine

class VideoTherapyViewController: UIViewController {
    var viewModel: VideoTherapyViewModel!
    var bag = Set<AnyCancellable>()
    
    var playerView = VideoTherapyPlayerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0, constant: 0)
        ])
        
    }

    func configure(with viewModel: VideoTherapyViewModel) {
        self.viewModel = viewModel
        self.playerView.delegate = self.viewModel
        configureSubscribers()
    }
    
    private func configureSubscribers() {
        viewModel.mediaURL
            .sink{ [weak self] url in
                let item = AVPlayerItem(url: url)
                self?.playerView.configure(with: item)
            }
            .store(in: &bag)
    }
}

