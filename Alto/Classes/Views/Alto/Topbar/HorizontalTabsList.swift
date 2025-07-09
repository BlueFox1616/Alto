//


// MARK: - HorizontalTabsList

struct HorizontalTabsList: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        if let location = altoState.tabManager.currentSpace?.dailyTabs {
            ForEach(Array(location.tabs.enumerated()), id: \.element.id) { index, tab in
                TabDropZoneView(model: TabDropZoneViewModel(altoState, location: location, index: index))
                AltoTabView(model: TabViewModel(state: altoState, tab: tab))
                    .frame(maxWidth: altoState.sidebar ? .infinity : 160)
                    .frame(height: 30)
                    .offset(altoState.sidebar ? CGSize(width: 0, height: -40) : .zero)
            }
        }
    }
}
