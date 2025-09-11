import SwiftUI

struct ProfileListChild: View {
    let leftText: String
    let rightText: String
    
    var body: some View {
        HStack {
            Text(leftText)
                .padding(.trailing, 5)
            Spacer()
            Text(rightText)
        }
    }
}
