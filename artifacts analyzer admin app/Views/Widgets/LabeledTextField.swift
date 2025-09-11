import SwiftUI
import Combine

struct LabeledTextField: View {
    let label: String
    
    @Binding var text: String
    
    var numberType: String = ""
    var isUsePicker: Bool = false
    var pickerOptions: [String] = []
    var limit: Int = Int.max
    // フォーカス管理
    var focusField: FocusState<Bool>.Binding?
    
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
            
            if isUsePicker {
                // ドラムロールモード
                PickerTextField(text: $text, label: "", options: pickerOptions)
            } else {
                // 自由入力モード
                TextField("", text: $text)
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


// UIKitのUITextFieldをラップして、inputViewにUIPickerViewを設定
struct PickerTextField: UIViewRepresentable {
    @Binding var text: String
    var label: String
    var options: [String]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = label
        
        // ✅ カーソルを非表示にする
        textField.tintColor = .clear
        
        // UIPickerView を inputView に設定
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        textField.inputView = picker
        
        // ✅ ツールバーを inputAccessoryView に設定
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: context.coordinator, action: #selector(Coordinator.doneTapped))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([space, doneButton], animated: false)
        textField.inputAccessoryView = toolbar
        
        // 初期値
        if let first = options.first {
            textField.text = text.isEmpty ? first : text
            context.coordinator.selectedValue = text.isEmpty ? first : text
        }
        
        context.coordinator.parent = self
        context.coordinator.textField = textField
        context.coordinator.picker = picker
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var parent: PickerTextField
        weak var picker: UIPickerView?
        weak var textField: UITextField?
        var selectedValue: String = ""
        
        init(_ parent: PickerTextField) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            parent.options.count
        }
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            parent.options[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selectedValue = parent.options[row]
        }
        
        @objc func doneTapped() {
            // 選択された値を反映
            parent.text = selectedValue
            textField?.text = selectedValue
            textField?.resignFirstResponder() // キーボード（picker）を閉じる
        }
    }
}
