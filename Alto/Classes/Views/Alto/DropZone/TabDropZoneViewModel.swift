//



@Observable
class TabDropZoneViewModel {
    var width: CGFloat = 100
    var height: CGFloat = 30
    let location: TabLocation
    let state: AltoState
    
    var sidebar: Bool {
        state.sidebar
    }
    
    var isTargeted: Bool = false
    let index: Int
    var data: AltoData {
        AltoData.shared
    }
    
    init(_ state: AltoState, location: TabLocation, index: Int) {
        self.location = location
        self.index = index
        self.state = state
    }
    
    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        self.location.addTab(droppedTabs, at: index)
        return true
    }
    
    func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        isTargeted = targeted
    }
}
