//
import SwiftUI

// MARK: - TopbarView

struct TopbarView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        HStack(spacing: 2) {
            NavigationButtonsView()

            HorizontalTabsList()
            Spacer()

            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            }, icon: "plus", active: true)
        }
        .ViewDebug()
        .frame(height: 30)
    }
}
