//
import SwiftUI

// MARK: - SidebarView

struct SidebarView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        VStack {
            HStack(spacing: 2) {
                NavigationButtonsView()
            }
            .frame(height: 30)

            Button {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New Tab")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(5)

            VerticalTabsList()

            Spacer()

            HStack {
                Spacer()
                AltoButton(action: {
                    withAnimation(.spring(duration: 0.2)) {
                        altoState.isShowingCommandPalette = true
                    }
                }, icon: "plus", active: true)
                .frame(height: 30)
            }
        }
        .frame(width: 250)
    }
}
