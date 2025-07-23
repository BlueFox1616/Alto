import SwiftUI

extension Color {
    init?(cssRGBString: String, allowAlpha: Bool = true) {
        // Find the numbers inside the parentheses
        let pattern = #"\(([^)]*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cssRGBString, range: NSRange(cssRGBString.startIndex..., in: cssRGBString)),
              let range = Range(match.range(at: 1), in: cssRGBString) else {
            return nil
        }
        
        // Get the comma-separated values
        let components = cssRGBString[range]
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 3,
              let r = Double(components[0]),
              let g = Double(components[1]),
              let b = Double(components[2]) else {
            return nil
        }
        
        let a: Double
        if components.count >= 4, let alpha = Double(components[3]), allowAlpha {
            a = alpha
        } else {
            a = 1.0
        }
        
        self.init(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: a)
    }
}
