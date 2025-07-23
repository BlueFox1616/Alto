import SwiftUI
import Equatable

// MARK: - BrowserContentView

struct BrowserContentView: View {
    @Environment(AltoState.self) private var altoState

    var data: AltoData {
        AltoData.shared
    }

    var body: some View {
        HStack(spacing: 5) {
            if altoState.sidebar, !altoState.sidebarIsRight {
                SidebarView()
            }
            VStack(spacing: 5) {
                if !altoState.sidebar {
                    TopbarView()
                        .zIndex(1)
                }
                WebContentView()
            }

            if altoState.sidebar, altoState.sidebarIsRight {
                SidebarView()
            }
        }
        .padding(5)
    }
}

// MARK: - ContentView
struct WebContentView: View {
    @Environment(AltoState.self) private var altoState
    
    @State private var windowIsActive: Bool = true
    
    var body: some View {
        Group {
            if let currentContent = altoState.currentContent?[0] as? ADKWebPage {
                GeometryReader { geo in
                    AnyView(currentContent.returnView(windowIsActive))
                        .frame(width: geo.size.width, height: geo.size.height)
                        .cornerRadius(10)
                        .shadow(radius:4)
                }
            } else {
                EmptyWebView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            let window = notification.object as? AltoWindow
            altoState.activeWindow = window ?? altoState.activeWindow
            windowIsActive = altoState.window?.id == altoState.activeWindow?.id
        }
        
    }
}
