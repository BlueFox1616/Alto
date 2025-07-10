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
    
    @State private var activeWindow = WindowManager.shared.window
    
    var windowIsActive: Bool {
        altoState.window?.id == activeWindow?.id
    }
    var body: some View {
        Group {
            if let currentContent = altoState.currentContent {
                ForEach(Array(currentContent.enumerated()), id: \.element.id) { _, content in
                    AnyView(content.returnView(windowIsActive))
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }
            } else {
                EmptyWebView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            let window = notification.object as? AltoWindow
            self.activeWindow = window ?? activeWindow
        }
    }
}
