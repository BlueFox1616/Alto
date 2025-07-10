//
import SwiftUI

@Observable
class WindowManager {
    public static let shared = WindowManager()

    public var defaultConfig: DefaultWindowConfiguration = .init()

    public var windows: [AltoWindow] = []
    
    // This is the currently active window
    var window: AltoWindow? {
        let output = (NSApplication.shared.keyWindow as? AltoWindow) ?? (NSApplication.shared.mainWindow as? AltoWindow)
        return output
    }

    private var defaultProfile: Profile {
        ProfileManager.shared.defaultProfile
    }

    private init() {}

    @discardableResult
    func createWindow(
        profile: Profile? = nil,
        tabs: [ADKTab] = [],
        contentRect: NSRect? = nil
    ) -> AltoWindow? {
        let viewState = AltoState()

        let contentView = BrowserView()
            .environment(viewState)

        let hostingController = NSHostingView(rootView: contentView)

        let window = AltoWindow(
            rootView: hostingController,
            state: viewState
        )

        windows.append(window)
        window.orderFront(nil)
        return window
    }
}
