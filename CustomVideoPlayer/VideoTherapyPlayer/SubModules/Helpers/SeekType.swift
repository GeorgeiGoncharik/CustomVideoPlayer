import Foundation
import AVFoundation

enum SeekType {
    case time(CMTime)
    case offset(TimeInterval)
    case start
    case end
}
