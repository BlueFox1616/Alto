
import AppKit

// MARK: - NSImage Extension

extension NSImage {
    /// Validates that the NSImage is valid and has proper dimensions
    var isValid: Bool {
        size.width > 0 && size.height > 0 && !representations.isEmpty
    }
}
