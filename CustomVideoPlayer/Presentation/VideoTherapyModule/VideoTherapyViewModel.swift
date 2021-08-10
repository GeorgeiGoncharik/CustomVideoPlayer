import Foundation
import Combine

//MARK: -Video Therapy ViewModel

protocol VideoTherapyNavigation: AnyObject {
    func finishTherapy()
    func openQuestion(question: String)
}

class VideoTherapyViewModel {
    weak var navigation: VideoTherapyNavigation?
    var backgroundMusicManager: Bool = true
    private var model = CurrentValueSubject<VideoTherapyModel, Never>(
        VideoTherapyModel(
            mediaURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            questionMarks: [5, 12, 20]
        )
        
    )
    var mediaURL: AnyPublisher<VideoTherapyModel, Never> {
        model.eraseToAnyPublisher()
    }
}

extension VideoTherapyViewModel: VideoTherapyPlayerViewDelegate {
    func didReachQuestionMark(_ mark: Int) {
        navigation?.openQuestion(question: String(describing: mark))
    }
    
    func didTapBackgroundMusicButton() {
        backgroundMusicManager.toggle()
        print(String(describing: backgroundMusicManager))
    }
    
    func didTapCloseTherapyButton() {
        navigation?.finishTherapy()
    }
}
