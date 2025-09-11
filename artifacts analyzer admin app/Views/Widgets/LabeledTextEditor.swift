import SwiftUI
import Combine

struct LabeledTextEditor: View {
    let label: String
    
    @Binding var text: String
    
    var limit: Int = Int.max
    var height: CGFloat = 150
    // フォーカス管理
    var focusField: FocusState<Bool>.Binding?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
            }
            
            // 自由入力モード
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
            
        }
    }
}
