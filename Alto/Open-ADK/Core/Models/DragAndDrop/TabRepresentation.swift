
import Algorithms
import SwiftUI
import UniformTypeIdentifiers
import Observation

/// A structure to store the tab data for drag and drop
struct TabRepresentation: Transferable, Codable, Comparable, Hashable, Identifiable {
    var id: UUID /// The ID of the tab being represented
    var containerID: UUID? /// The drop zone: this could be a folder or a place like pinned tabs and favorites
    var index: Int /// the tabs position in its containers list
    
    /// tells the struct it should be represented as the custom UTType .tabItem
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .tabItem)
    }
    
    /// allows the tabs to be comparied with eachother based on ID
    static func < (lhs: TabRepresentation, rhs: TabRepresentation) -> Bool {
        return lhs.id == rhs.id
    }
    
    func toItemProvider() -> NSItemProvider {
        print("dragged")
        if let data = try? JSONEncoder().encode(self) {
            return NSItemProvider(item: data as NSData, typeIdentifier: "public.json")
        }
        
        return NSItemProvider()
    }
}

/// extentds the Unifide type identifier to add the tabItem structure
extension UTType {
    static let tabItem = UTType(exportedAs: "Alto-Browser.Alto.tabItem")
    /// creates a exported type identiffier
}
