//

import SwiftUI

// MARK: - ColorScheme Extension

public extension ColorScheme {
    var stringValue: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        @unknown default: return "system"
        }
    }
}
