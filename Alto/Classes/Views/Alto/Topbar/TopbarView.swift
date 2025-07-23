//
import SwiftUI

// MARK: - TopbarView

struct TopbarView: View {
    @Environment(AltoState.self) private var altoState
    @State private var isPopoverPresented: Bool = false
    
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
            
            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    isPopoverPresented.toggle()
                }
            }, icon: "arrow.down.circle", active: true)
            .popover(isPresented: $isPopoverPresented) {
                VStack {
                    HStack {
                        Text("Downloads")
                        
                        Spacer()
                        
                        Button {
                            DownloadManager.shared.downloads.clear()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    
                    Divider()
                    
                    ForEach(DownloadManager.shared.downloads.list, id: \.id) { download in
                        DownloadItemView(model: DownloadItemViewModel(downloadItem: download))
                    }
                }
            }
            
        }
        .ViewDebug()
        .frame(height: 30)
    }
}
