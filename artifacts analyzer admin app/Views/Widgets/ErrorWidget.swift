import SwiftUI

struct ErrorWidget: View {
    let errorMessage: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(errorMessage)
                .font(.system(size: 12))
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.red)
        )
    }
}
