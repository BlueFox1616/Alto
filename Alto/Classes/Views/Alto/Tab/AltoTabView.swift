//
import SwiftUI

struct AltoTabView: View {
    var model: TabViewModel

    var body: some View {
        HStack {
            faviconImage(model: model)

            Text(model.tabTitle)

            Spacer()

            if model.isHovered {
                closeButton(model: model) //
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((model.tabManager?.currentSpace?.currentTab?.id == model.tab.id || model.isHovered) ?
                    .gray.opacity(0.4) : .gray.opacity(0)
                ) // lol i need to fix this
        )
        .contentShape(Rectangle()) // added to the background clickable
        .gesture(
            TapGesture(count: 2).onEnded {
                model.handleDoubleClick()
            }
        )
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                model.handleSingleClick()
            }
        )
        .onHover { hovered in
            model.isHovered = hovered
        }
        .draggable(model.tab) {
            AltoTabViewDragged(model: model)
        }
        .ViewDebug()
    }
}

struct closeButton: View {
    var model: TabViewModel

    var body: some View {
        Button(action: { model.handleClose(); print("hit") }) {
            model.closeIcon
        }
        .containerShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .aspectRatio(1 / 1, contentMode: .fill)
    }
}

struct faviconImage: View {
    var model: TabViewModel

    var body: some View {
        model.tabIcon
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
    }
}
