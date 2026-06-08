import SwiftUI

extension View {
    func cardStyle() -> some View {
        padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
