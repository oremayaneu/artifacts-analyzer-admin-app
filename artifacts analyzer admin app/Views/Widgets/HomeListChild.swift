import SwiftUI

struct HomeListChild: View {
    let leftIconName: String
    let title: String
    let rightIconName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action:{onTap()}) {
            HStack{
                Image(systemName: leftIconName)
                Text(title)
                Spacer()
                Image(systemName: rightIconName)
            }
        }.foregroundColor(.primary)
    }
}
