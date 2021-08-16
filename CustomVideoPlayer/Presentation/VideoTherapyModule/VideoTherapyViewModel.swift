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
            mediaURLs: [
                URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!,
                URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!,
                URL(string: "https://multiplatform-f.akamaihd.net/i/multi/april11/sintel/sintel-hd_,512x288_450_b,640x360_700_b,768x432_1000_b,1024x576_1400_m,.mp4.csmil/master.m3u8")!
            ]
        )
        
    )
    var mediaURL: AnyPublisher<VideoTherapyModel, Never> {
        model.eraseToAnyPublisher()
    }
}

extension VideoTherapyViewModel: VideoTherapyPlayerViewDelegate {    
    func onTextTherapy(after itemIndex: Int) {
        print("called: onTextTherapy(_:)")
        navigation?.openQuestion(question: String(describing: itemIndex))
    }

    func onBackgroundMusic() {
        print("called: onBackgroundMusic()")
        backgroundMusicManager.toggle()
    }
    
    func onClose() {
        print("called: onClose()")
        navigation?.finishTherapy()
    }
}
