import SwiftUI
import Combine

struct LeftLabeledTextField: View {
    let label: String
    @Binding var text: String
    
    var numberType: String = ""
    var isUsePicker: Bool = false
    var pickerOptions: [String] = []
    var limit: Int = Int.max

    // フォーカス管理
    var focusField: FocusState<Bool>.Binding?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .frame(width: 100, alignment: .leading)
            Divider()
            
            if isUsePicker {
                Picker("", selection: $text) {
                    ForEach(pickerOptions, id: \.self) { elem in
                        Text(elem)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
            } else {
                TextField("", text: $text)
                    .multilineTextAlignment(TextAlignment.trailing)
                    .keyboardType(numberType == "Int"
                                  ? .numberPad
                                  : numberType == "Double"
                                  ? .decimalPad
                                  :.default) // 数字のみ or 小数あり or 通常入力
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onReceive(Just(text), perform: { _ in
                        if limit < text.count {
                            text = String(text.prefix(limit))
                        }
                    })
                    .focused(focusField!) // フォーカスを監視
            }
        }
    }
}

