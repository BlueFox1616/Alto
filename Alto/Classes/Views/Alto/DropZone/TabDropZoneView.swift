//
import SwiftUI
import Equatable



struct TabDropZoneView: View {
    let model: TabDropZoneViewModel

    var body: some View {
        ZStack {
            if model.sidebar {
                VerticalDropZoneView(model: model, width: 250)
            } else {
                HorizontalDropZoneView(model: model, height: 30)
            }
        }
        .frame(height: 2)
        .frame(width: model.sidebar ? nil : 0)
        .zIndex(1)
    }
}


struct HorizontalDropZoneView: View {
    let model: TabDropZoneViewModel
    let height: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.red.opacity(0))
                .frame(width: model.width, height: height)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                    model.onDrop(droppedTabs: droppedTabs, location: location)
                } isTargeted: { targeted in
                    model.handleTargeted(targeted)
                }

            if model.isTargeted {
                VStack(spacing: 0) {
                    Circle()
                        .fill(.clear)
                        .stroke(.blue, lineWidth: 2)
                        .frame(width: 8, height: 8)

                    Rectangle()
                        .fill(.blue)
                        .frame(width: 2)
                }
            }
        }
    }
}


struct VerticalDropZoneView: View {
    let model: TabDropZoneViewModel
    let width: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.red.opacity(0))
                .frame(width: width, height: model.height)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                    model.onDrop(droppedTabs: droppedTabs, location: location)
                } isTargeted: { targeted in
                    model.handleTargeted(targeted)
                }

            if model.isTargeted {
                HStack(spacing: 0) {
                    Circle()
                        .fill(.clear)
                        .stroke(.blue, lineWidth: 2)
                        .frame(width: 8, height: 8)

                    Rectangle()
                        .fill(.blue)
                        .frame(height: 2)
                }
            }
        }
    }
}
