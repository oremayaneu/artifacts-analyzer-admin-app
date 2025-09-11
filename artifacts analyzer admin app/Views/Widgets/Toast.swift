import SimpleToast
import SwiftUI

struct ToastView: View {
    @Binding var showToast: Bool
    
    let showMessage: String

    private let toastOptions = SimpleToastOptions(
        hideAfter: 3 // 追加
    )

    var body: some View {
        VStack {
            EmptyView()
        }
        .simpleToast(isPresented: $showToast, options: toastOptions) {
            Label(showMessage, systemImage: "info.circle")
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .padding(.top)
        }
    }
}
