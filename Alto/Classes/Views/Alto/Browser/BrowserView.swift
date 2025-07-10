//

import SwiftUI


struct BrowserView: View {
    @Environment(AltoState.self) private var altoState
    @State var window = NSApplication.shared.keyWindow as? AltoWindow
    // If you can find a better solution please make a pr!

    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
            CommandPaletteView()
        }
        .preferredColorScheme(PreferencesManager.shared.colorScheme.asColorScheme)
        .ignoresSafeArea()
    }
}
