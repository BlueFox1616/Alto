//
import SwiftUI


extension View {
    func ViewDebug() -> some View {
#if DEBUG
        return self
            //.background {
            //   let color = Color(
            //        red: .random(in: 0...1),
            //        green: .random(in: 0...1),
            //        blue: .random(in: 0...1)
            //    )
            //
            //    Rectangle()
            //        .fill(color)
            //        .opacity(0.3)
            //        .border(color, width: 2)
            //}
#else
        return self
#endif
    }
}


extension View {
    func snapshot() -> NSImage {
        let hostingView = NSHostingView(rootView: self)
        
        // Let the view size itself
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize
        
        hostingView.frame = CGRect(origin: .zero, size: fittingSize)

        let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        let image = NSImage(size: fittingSize)
        image.addRepresentation(rep)
        return image
    }
}
