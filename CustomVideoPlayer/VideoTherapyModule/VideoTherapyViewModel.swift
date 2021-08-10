import Foundation
import Combine

//MARK: -Flow mock

class TherapyCoordinator: VideoTherapyNavigation {
    func finishTherapy() {
        print("VideoTherapyViewModel called finishTherapy() method. processing some logic here...")
    }
}

//MARK: -Video Therapy ViewModel

protocol VideoTherapyNavigation: AnyObject {
    func finishTherapy()
}

class VideoTherapyViewModel {
    weak var navigation: VideoTherapyNavigation?
    var backgroundMusicManager: Bool = true
    private var model = CurrentValueSubject<URL, Never>(
        URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    )
    var mediaURL: AnyPublisher<URL, Never> {
        model.eraseToAnyPublisher()
    }
}

extension VideoTherapyViewModel: VideoTherapyPlayerViewDelegate {
    func didTapBackgroundMusicButton() {
        backgroundMusicManager.toggle()
        print(String(describing: backgroundMusicManager))
    }
    
    func didTapCloseTherapyButton() {
        navigation?.finishTherapy()
    }
}
