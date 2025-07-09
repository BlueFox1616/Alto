//
import AppKit
import Observation


@Observable
public class TabLocation: TabLocationProtocol {
    
    private var data: AltoData {
        AltoData.shared
    }
    public var title: String
    public let id: UUID = .init()
    public var tabs: [TabRepresentation] = []
    
    
    public init(title: String) {
        self.title = title
    }
    
    /// adds a single tab to the location
    /// - Parameters:
    ///   - tabRep: a tab representation
    ///   - insertionPoint: the location to insert the tab
    public func addTab(_ tabRep: TabRepresentation, at insertionPoint: Int? = nil) {
        guard let tab = data.getTab(id: tabRep.id) else { return }

        let targetIndex = insertionPoint ?? tabs.count

        if let currentIndex = tabs.firstIndex(of: tabRep) {
            // If it's already in the correct place, skip
            if currentIndex == targetIndex {
                return
            }
            // Remove existing to reinsert
            tabs.remove(at: currentIndex)
            // Adjust target index if removal shifted it
            let adjustedIndex = currentIndex < targetIndex ? targetIndex - 1 : targetIndex
            tabs.insert(tabRep, at: adjustedIndex)
        } else {
            tabs.insert(tabRep, at: targetIndex)
        }

        tab.location = self
    }
    
    /// adds an array of tabs to a location
    /// - Parameters:
    ///   - tabReps: an array of tab representations
    ///   - insertionPoint: the point to insert the tabs
    public func addTab(_ tabReps: [TabRepresentation], at insertionPoint: Int? = nil) {
        var currentIndex = insertionPoint ?? tabs.count

        for tabRep in tabReps {
            if let existingIndex = tabs.firstIndex(of: tabRep) {
                if existingIndex == currentIndex {
                    currentIndex += 1
                    continue
                }

                tabs.remove(at: existingIndex)

                // Adjust index due to removal
                let adjustedIndex = existingIndex < currentIndex ? currentIndex - 1 : currentIndex
                tabs.insert(tabRep, at: adjustedIndex)
                currentIndex = adjustedIndex + 1
            } else {
                tabs.insert(tabRep, at: currentIndex)
                currentIndex += 1
            }

            if let tab = data.getTab(id: tabRep.id) {
                tab.location = self
            }
        }
    }
    public func removeTab(_ tabRep: TabRepresentation) {
        tabs = tabs.filter { $0 != tabRep}
    }
    
    public func removeTab(id: UUID) {
        tabs = tabs.filter { $0.id != id}
    }
    
    public func getTab(_ id: UUID) -> TabRepresentation? {
        return tabs.first(where: { $0.id == id })
    }
}

public class PinnedTabs: TabLocation {
    
    public convenience init() {
        self.init(title: TabLocations.pinned.rawValue)
    }
}

public class FavoriteTabs: TabLocation {
    
    public convenience init() {
        self.init(title: TabLocations.favorite.rawValue)
    }
}


public class DailyTabs: TabLocation {
    
    public convenience init() {
        self.init(title: TabLocations.daily.rawValue)
    }
}


enum TabLocations: String, CaseIterable {
    case pinned = "pinned"
    case favorite = "favorite"
    case daily = "daily"
}


public protocol TabLocationProtocol {
    var title: String { get }
    var id: UUID { get }
    var tabs: [TabRepresentation] { get }
    
    func addTab(_ tabRep: TabRepresentation, at:Int?)
    func addTab(_ tabReps: [TabRepresentation], at:Int?)
    func removeTab(_ tabRep: TabRepresentation)
    func removeTab(id: UUID)
    func getTab(_ id: UUID) -> TabRepresentation?
}
