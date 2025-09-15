import SwiftUI

struct DisplayWeaponDetailView: View {
    @Binding var path: [WeaponPath]
    @ObservedObject var weaponViewModel: WeaponViewModel
    
    @State private var isEditing = false
    
    // 編集用の一時データ
    @State private var id = ""
    @State private var jpName = ""
    @State private var enName = ""
    @State private var rarity = ""
    @State private var type = ""
    @State private var attack = ""
    @State private var subStatusName = ""
    @State private var subStatusValue = ""
    @State private var effect = ""
    @State private var imgUrl = ""
    
    // 全体で共有するフォーカス管理
    @FocusState private var isKeyboardActive: Bool
    
    // firebaseに書き込み
    @State private var isUpdate = false
    @State private var errorUpdateFlg = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        if let weapon = weaponViewModel.selectedWeapon {
            ZStack {
                List {
                    if errorUpdateFlg {
                        ErrorWidget(errorMessage: errorMessage)
                    }
                    
                    // 武器画像
                    if !isEditing {
                        NetworkImage(url: weapon.imgUrl).frame(width: 120, height: 120).frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // hoyolab ID
                    if isEditing {
                        LeftLabeledTextField(label: "hoyolab ID", text: $id, numberType: "Int", limit: 10, focusField: $isKeyboardActive)
                    }
                        
                    // 名前
                    if isEditing {
                        LeftLabeledTextField(label: "名前(JP)", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "名前(EN)", text: $enName, limit: 50, focusField: $isKeyboardActive)
                    } else {
                        ProfileListChild(leftText: "名前(JP)", rightText: weapon.jpName)
                        ProfileListChild(leftText: "名前(EN)", rightText: weapon.enName)
                    }
                    
                    // レアリティ
                    if isEditing {
                        LeftLabeledTextField(label: "レアリティ", text: $rarity, isUsePicker: true, pickerOptions: ["5","4"])
                    } else {
                        ProfileListChild(leftText: "レアリティ", rightText: "\(weapon.rarity)")
                    }
                    
                    // 武器種
                    if isEditing {
                        LeftLabeledTextField(label: "武器種", text: $type, isUsePicker: true, pickerOptions: weaponTypes)
                    } else {
                        ProfileListChild(leftText: "武器種", rightText: weapon.type)
                    }
                    
                    // ステータス
                    if isEditing {
                        LeftLabeledTextField(label: "攻撃力", text: $attack, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "サブステータス\n : 種類", text: $subStatusName, isUsePicker: true, pickerOptions: statusNames)
                        HStack{
                            LeftLabeledTextField(label: "サブステータス\n : 値", text: $subStatusValue, numberType: "Double", limit: 5, focusField: $isKeyboardActive)
                            if subStatusName != "元素熟知" {Text("%")}
                        }
                    } else {
                        ProfileListChild(leftText: "攻撃力", rightText: "\(weapon.attack)")
                        ProfileListChild(leftText: "サブステータス", rightText: "\(removeTrailingPercent(str: weapon.subStatusName)) \(addTrailingPercent(key: weapon.subStatusName, value: weapon.subStatusValue))")
                    }
                    
                    // 効果
                    if isEditing {
                        LeftLabeledTextEditor(label: "効果", text: $effect, limit: 1000, focusField: $isKeyboardActive)
                    } else {
                        ProfileListChild(leftText: "効果（精錬1）", rightText: weapon.displayInitialEffect)
                        ProfileListChild(leftText: "効果（精錬5）", rightText: weapon.displayFinalEffect)
                    }
                    
                    // 画像URL
                    if isEditing {
                        LeftLabeledTextField(label: "アイコンURL", text: $imgUrl, limit: 10000, focusField: $isKeyboardActive)
                    }
                }
                
                ToastView(showToast: $showToast, showMessage: "武器を更新しました")
                
                if isUpdate {
                    BlockingIndicator()
                }
            }
            .navigationTitle("武器詳細")
            .navigationBarBackButtonHidden(isEditing) // 左上の戻るシェブロンのon/off
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("キャンセル") {
                            isEditing = false
                        }
                    } else {
                        EmptyView() // デフォルトの戻るボタン
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "完了" : "編集") {
                        if isEditing {
                            // キーボードを閉じる
                            isKeyboardActive = false
                            isUpdate.toggle()
                            
                            // 編集終了時: 更新処理
                            guard let url = URL(string: imgUrl) else {
                                isUpdate.toggle()
                                errorUpdateFlg = true
                                errorMessage = "武器画像が正しくありません"
                                return
                            }
                            
                            var weapon = Weapon (
                                attack: Int(attack) ?? 0,
                                effectSentence: [""], // 後で更新
                                enName: enName,
                                finalEffectValue: [0.0], // 後で更新
                                imgUrl: url,
                                initialEffectValue: [0.0], // 後で更新
                                jpName: jpName,
                                rarity: Int(rarity) ?? 0,
                                subStatusName: subStatusName,
                                subStatusValue: Double(subStatusValue) ?? 0,
                                type: type,
                                
                                hoyolabId: Int(id) ?? 0
                            )
                            // effectのset処理
                            weapon.getEffect = effect
                            
                            weaponViewModel.createWeapon(
                                weapon: weapon,
                                completion: {
                                    // 成功時の処理
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        isUpdate.toggle()
                                        errorUpdateFlg = false
                                        errorMessage = ""
                                        showToast = true
                                        isEditing.toggle()
                                    }
                                },
                                errorHandling: {
                                    // エラー時の処理
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        isUpdate.toggle()
                                        errorUpdateFlg = true
                                        errorMessage = "武器データの保存に失敗しました"
                                        isEditing.toggle()
                                    }
                                }
                            )
                        } else {
                            // 編集開始時: 現在の値をコピー
                            id = "\(weapon.hoyolabId)"
                            attack = "\(weapon.attack)"
                            enName = weapon.enName
                            imgUrl = weapon.imgUrl.absoluteString
                            jpName = weapon.jpName
                            rarity = "\(weapon.rarity)"
                            subStatusName = weapon.subStatusName
                            subStatusValue = "\(weapon.subStatusValue)"
                            type = weapon.type
                            // 編集用effectを生成
                            effect = weapon.getEffect
                            
                            isEditing.toggle()
                        }
                    }
                    .disabled(!isValidField() && isEditing)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        isKeyboardActive = false // キーボード閉じる
                    }
                }
            }
        } else {
            Text("エラーが発生しました")
                .foregroundColor(.gray)
        }
    }
    
    private func isValidField() -> Bool {
        return !id.isEmpty &&
        !jpName.isEmpty &&
        !enName.isEmpty &&
        !rarity.isEmpty &&
        !type.isEmpty &&
        !attack.isEmpty &&
        !subStatusName.isEmpty &&
        !subStatusValue.isEmpty &&
        !effect.isEmpty &&
        !imgUrl.isEmpty
    }
}
