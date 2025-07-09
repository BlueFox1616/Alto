//



import Observation
import SwiftUI

@Observable
class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var tabManager: TabManager? {
        state.tabManager
    }

    var altoTab: ADKTab? {
        AltoData.shared.getTab(id: tab.id)
    }

    var tabTitle: String {
        altoTab?.content[0].title ?? "Untitled"
    }

    var tabIcon: Image {
        if let favicon = altoTab?.content[0].favicon {
            Image(nsImage: favicon)
        } else {
            Image(systemName: "square.fill")
        }
    }

    var closeIcon = Image(systemName: "xmark")

    var isHovered = false
    var isDragged = false

    var isCurrentTab: Bool {
        tabManager?.currentSpace?.currentTab?.id == altoTab?.id
    }

    var tabRepresentation: TabRepresentation {
        tab
    }

    init(state: AltoState, tab: TabRepresentation) {
        self.state = state
        self.tab = tab
    }

    func handleSingleClick() {
        tabManager?.currentSpace?.currentTab = AltoData.shared.getTab(id: tab.id)
        tabManager?.currentTab = AltoData.shared.getTab(id: tab.id)
    }

    func selectTab() {
        handleSingleClick()
    }

    func handleDoubleClick() {
        // Does nothing currenlty
        // Eventualy this will open a urlbar
    }

    func handleDragEnd() {}

    func handleClose() {
        altoTab?.closeTab()
    }
}
