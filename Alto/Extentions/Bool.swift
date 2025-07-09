//

import AppKit

extension Bool {
    func toString() -> String {
        if self {
            "true"
        } else {
            "false"
        }
    }

    init(string: String) {
        let string = string.lowercased()
        if string == "true" {
            self = true
        } else {
            self = false
        }
    }
}
