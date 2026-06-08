import Foundation

enum ThrottleLevel: Int, CaseIterable, Identifiable, Codable {
    case slow = 256
    case medium = 1000
    case fast = 5000

    var id: Int { rawValue }

    var kbps: Int { rawValue }
    var bytesPerSecond: Int { (kbps * 1000) / 8 }

    var title: String {
        switch self {
        case .slow:   return "Slow"
        case .medium: return "Medium"
        case .fast:   return "Fast"
        }
    }

    var subtitle: String {
        switch self {
        case .slow:   return "256 kbps — videos won't load"
        case .medium: return "1 Mbps — delays visible"
        case .fast:   return "5 Mbps — mild lag"
        }
    }
}
