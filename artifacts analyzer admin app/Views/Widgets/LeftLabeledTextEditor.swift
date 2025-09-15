import SwiftUI
import Combine

struct LeftLabeledTextEditor: View {
    let label: String
    
    @Binding var text: String
    
    var limit: Int = Int.max
    var height: CGFloat = 150
    // フォーカス管理
    var focusField: FocusState<Bool>.Binding?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .frame(width: 100, alignment: .leading)
            Divider()
            
            TextEditor(text: $text)
                .frame(height: height)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onReceive(Just(text), perform: { _ in
                    if limit < text.count {
                        text = String(text.prefix(limit))
                    }
                })
                .focused(focusField!) // フォーカスを監視
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(UIColor.systemGray6))
                )
                .scrollContentBackground(.hidden)
                .background(Color.darkPrimary)
        }
    }
}
