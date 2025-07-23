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
