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

    var body: some View {
        let currentContent = altoState.currentContent

        if let currentContent {
            ForEach(Array(currentContent.enumerated()), id: \.element.id) { _, content in
                AnyView(content.returnView())
                    .cornerRadius(10)
                    .shadow(radius: 4)
            }
        } else {
            EmptyWebView()
        }
    }
}
