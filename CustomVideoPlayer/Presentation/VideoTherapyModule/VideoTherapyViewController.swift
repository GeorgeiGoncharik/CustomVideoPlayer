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
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func configure(with viewModel: VideoTherapyViewModel) {
        self.viewModel = viewModel
        self.playerView.delegate = self.viewModel
        configureSubscribers()
    }
    
    private func configureSubscribers() {
        viewModel.mediaURL
            .sink{ [weak self] model in
                self?.playerView.configure(with: model.mediaURLs)
            }
            .store(in: &bag)
    }
}

