
import SwiftUI

struct AltoButton: View {
    @State var isHovered = false
    var action: () -> ()
    var icon: String
    var active: Bool

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered && active ? .gray.opacity(0.4) : .gray.opacity(0))
                Image(systemName: icon)
                    .opacity(active ? 1 : 0.3)
            }
            .animation(.bouncy, value: isHovered)
            .onHover { hovered in
                isHovered = hovered
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(PlainButtonStyle())
    }
}


struct AltoButtonStyle: ButtonStyle {
    var isActive: Bool = true
    @State var isHovered: Bool = false
    
    let hoveredColor: Color = .gray.opacity(0.4)
    let nonHoveredColor: Color = .clear
    
    let activeOpacity = 1.0
    let inacticeOpacity = 0.35
    
    var showActive: Bool {
        isActive && isHovered
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isActive ? activeOpacity : inacticeOpacity)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(showActive ? hoveredColor : nonHoveredColor)
                    .onHover { hovered in
                        isHovered = hovered
                    }
            }
            .animation(.bouncy, value: isActive)
            .animation(.bouncy, value: showActive)
            .aspectRatio(1, contentMode: .fit)
    }
}
