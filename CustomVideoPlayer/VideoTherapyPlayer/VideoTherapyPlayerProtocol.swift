import Foundation
import AVFoundation

// MARK: - Требования. Лишние комментарии потом удалю
#warning("Delete comments")
// Видео проигрыватель. Что в нем должно быть -
protocol VideoTherapyPlayerProtocol: AnyObject {
    var avPlayer: AVPlayer {get}
    var isPlaying: Bool {get}
    var rate: PlaybackRates {get set} // ускорение проигрывания х1.25, х1.5, х1.75, х2
    var delegate: VideoTherapyPlayerDelegate? {get set}
    // настройка плеера
    func configure(with url: URL)
    func configure(with item: AVPlayerItem)
    // пауза/плэй high priority
    func play()
    func pause()
    // промотка на 15 секунд вперед и назад
    func seek(to time: CMTime)
    func seek(by offset: TimeInterval)
    // субтитры вкл/вык
    func enableSubtitles()
    func disableSubtitles()
    // кнопка включения/выключения фоновой музыки high priority - VideoTherapyPlayerViewDelegate
    // крестик на закрытие сессии (будет во view и логика во VM) high priority - VideoTherapyPlayerViewDelegate
    // переход к вопросу с пропуском видео куска до вопроса (через делегат) !!!
    // таймлайн видео с пометкой мест вопросов (будет во view) high priority
}
