//
import Observation

// MARK: - AltoState

@Observable
public class AltoState {
    // MARK: - Peramaters

    public var id = UUID()
    public var tabManager: TabManager

    public weak var window: AltoWindow? = nil
    public var currentContent: [any Displayable]? {
        window?.setTitle("No Title") // TODO: handle nil case
        return tabManager.currentTab?.content // TODO: Move current tab to tab manager
    }
    
    var sidebar = true
    var sidebarIsRight = false
//    The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette = true
    var Topbar: AltoTopBarViewModel.TopbarState = .hidden
    var draggedTab: TabRepresentation? = nil

    public init() {
        
        let altoManager = TabManager()
        altoManager.currentSpace = AltoData.shared.spaces[0]
        self.tabManager = altoManager
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
