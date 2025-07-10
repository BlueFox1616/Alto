//
import SwiftUI


// MARK: - NavigationButtonsView

struct NavigationButtonsView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        HStack(spacing: 2) {
            if !altoState.sidebarIsRight || !altoState.sidebar {
                MacButtonsView()
                    .padding(.leading, 6)
                    .frame(width: 70)
            }

            AltoButton(
                action: {
                    withAnimation(.spring(duration: 0.2)) {
                        altoState.sidebar.toggle()
                    }
                },
                icon: "sidebar.left",
                active: true
            )
            .frame(height: 30)
            .fixedSize()

            if altoState.sidebar {
                Spacer()
            }

            if !altoState.sidebar {
                SpacePickerView(model: SpacePickerViewModel(state: altoState))
            }

            AltoButton(
                action: {
                    altoState.tabManager.currentTab?.content[0].goBack()
                },
                icon: "arrow.left",
                active: altoState.tabManager.currentTab?.content[0].canGoBack ?? false
            )
            .frame(height: 30)
            .fixedSize()

            AltoButton(
                action: {
                    altoState.tabManager.currentTab?.content[0].goForward()
                },
                icon: "arrow.right",
                active: altoState.tabManager.currentTab?.content[0].canGoForward ?? false
            )
            .frame(height: 30)
            .fixedSize()
            
            AltoButton(
                action: {
                    WindowManager.shared.createWindow()
                },
                icon: "macwindow.on.rectangle",
                active: altoState.tabManager.currentTab?.content[0].canGoForward ?? false
            )
            .frame(height: 30)
            .fixedSize()
        }
    }
}
