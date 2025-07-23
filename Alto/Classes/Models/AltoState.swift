//
import Observation

// MARK: - AltoState

@Observable
public class AltoState {
    // MARK: - Peramaters

    var id = UUID()
    var tabManager: TabManager

    public var activeWindow = WindowManager.shared.window
    
    public weak var window: AltoWindow?
    public var currentContent: [any Displayable]? {
        window?.setTitle("No Title") // TODO: handle nil case
        return tabManager.currentTab?.content // TODO: Move current tab to tab manager
    }

    var sidebar = true
    var sidebarIsRight = false
    // The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette = true
    var Topbar: AltoTopBarViewModel.TopbarState = .hidden
    var draggedTab: TabRepresentation?

    public init() {
        let altoManager = TabManager()
        altoManager.currentSpace = AltoData.shared.spaces[0]
        tabManager = altoManager
        tabManager.state = self // Feeds in the state for the tab manager
    }

    func toggleTopbar() {
        switch Topbar {
        case .hidden:
            Topbar = .active
        case .active:
            Topbar = .hidden
        }
    }

    public func setup(webView: WKWebView) {
        CookiesManager.shared.setupCookies(for: webView)
    }
}
