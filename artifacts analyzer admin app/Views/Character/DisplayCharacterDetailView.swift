import SwiftUI

struct DisplayCharacterDetailView: View {
    @Binding var path: [CharacterPath]
    @ObservedObject var characterViewModel: CharacterViewModel
    
    @State private var isEditing = false
    
    // 編集用の一時データ
    @State private var id = ""
    
    @State private var jpName = ""
    @State private var enName = ""
    
    @State private var rarity = ""
    @State private var element = ""
    @State private var weaponType = ""
    @State private var extraStatusName = ""
    
    @State private var hp = ""
    @State private var attack = ""
    @State private var defense = ""
    @State private var extraStatusValue = ""
    
    @State private var imgUrl = ""
    
    // 全体で共有するフォーカス管理
    @FocusState private var isKeyboardActive: Bool
    
    // firebaseに書き込み
    @State private var isUpdate = false
    @State private var errorUpdateFlg = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        if characterViewModel.isLoadingCharacter {
            BlockingIndicator()
        } else if let character = characterViewModel.character {
            ZStack {
                List {
                    if errorUpdateFlg {
                        ErrorWidget(errorMessage: errorMessage)
                    }
                    
                    // キャラ画像
                    if !isEditing {
                        NetworkImage(url: character.imgUrl).frame(width: 120, height: 120).frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // hoyolab ID
                    if isEditing {
                        LeftLabeledTextField(label: "hoyolab ID", text: $id, numberType: "Int", limit: 10, focusField: $isKeyboardActive)
                    }
                    
                    // 名前
                    if isEditing {
                        LeftLabeledTextField(label: "名前(JP)", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "名前(EN)", text: $enName, limit: 30, focusField: $isKeyboardActive)
                    } else {
                        ProfileListChild(leftText: "名前(JP)", rightText: character.jpName)
                        ProfileListChild(leftText: "名前(EN)", rightText: character.enName)
                    }
                    
                    // レアリティ
                    if isEditing {
                        LeftLabeledTextField(label: "レアリティ", text: $rarity, isUsePicker: true, pickerOptions: ["5","4"])
                    } else {
                        ProfileListChild(leftText: "レアリティ", rightText: "\(character.rarity)")
                    }
                    
                    // 元素
                    if isEditing {
                        LeftLabeledTextField(label: "元素", text: $element, isUsePicker: true, pickerOptions: ["炎","水","風","氷","岩","草","雷"])
                    } else {
                        ProfileListChild(leftText: "元素", rightText: translateFromEnElement(element: character.element))
                    }
                    
                    // 武器種
                    if isEditing {
                        LeftLabeledTextField(label: "武器種", text: $weaponType, isUsePicker: true, pickerOptions: weaponTypes)
                    } else {
                        ProfileListChild(leftText: "武器種", rightText: character.weaponType)
                    }
                    
                    // ステータス
                    if isEditing {
                        LeftLabeledTextField(label: "HP", text: $hp, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "攻撃力", text: $attack, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "防御力", text: $defense, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LeftLabeledTextField(label: "突破ステータス\n : 種類", text: $extraStatusName, isUsePicker: true, pickerOptions: statusNames)
                        HStack{
                            LeftLabeledTextField(label: "突破ステータス\n : 値", text: $extraStatusValue, numberType: "Double", limit: 5, focusField: $isKeyboardActive)
                            if extraStatusName != "元素熟知" {Text("%")}
                        }
                    } else {
                        ProfileListChild(leftText: "HP", rightText: "\(character.HP)")
                        ProfileListChild(leftText: "攻撃力", rightText: "\(character.attack)")
                        ProfileListChild(leftText: "防御力", rightText: "\(character.defense)")
                        ProfileListChild(leftText: "突破ステータス", rightText: "\(removeTrailingPercent(str: character.extraStatusName)) \(addTrailingPercent(key: character.extraStatusName, value: character.extraStatusValue))")
                    }
                    
                    if isEditing {
                        LeftLabeledTextField(label: "アイコンURL", text: $imgUrl, limit: 10000, focusField: $isKeyboardActive)
                    }
                }
                
                ToastView(showToast: $showToast, showMessage: "キャラクターを更新しました")
                
                if isUpdate {
                    BlockingIndicator()
                }
            }
            .navigationTitle("キャラクター詳細")
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
                                errorMessage = "アイコンURLが正しくありません"
                                errorUpdateFlg = true
                                return
                            }
                            let character = Character (
                                HP: Int(hp) ?? 0,
                                attack: Int(attack) ?? 0,
                                defense: Int(defense) ?? 0,
                                element: element,
                                enName: enName,
                                extraStatusName: extraStatusName,
                                extraStatusValue: Double(extraStatusValue) ?? 0,
                                imgUrl: url,
                                jpName: jpName,
                                rarity: Int(rarity) ?? 0,
                                weaponType: weaponType,
                                hoyolabId: Int(id) ?? 0
                            )
                            
                            characterViewModel.createCharacter(
                                character: character,
                                completion: {
                                    // 成功時の処理
                                    isUpdate.toggle()
                                    errorUpdateFlg = false
                                    errorMessage = ""
                                    showToast = true
                                },
                                errorHandling: {
                                    // エラー時の処理
                                    isUpdate.toggle()
                                    errorUpdateFlg = true
                                    errorMessage = "キャラクターの更新に失敗しました"
                                }
                            )
                        } else {
                            // 編集開始時: 現在の値をコピー
                            id = "\(character.hoyolabId)"
                            jpName = character.jpName
                            enName = character.enName
                            rarity = "\(character.rarity)"
                            element = translateFromEnElement(element: character.element)
                            weaponType = character.weaponType
                            hp = "\(character.HP)"
                            attack = "\(character.attack)"
                            defense = "\(character.defense)"
                            extraStatusValue = "\(character.extraStatusValue)"
                            imgUrl = character.imgUrl.absoluteString
                        }
                        isEditing.toggle()
                    }
                    .disabled(!isValidField())
                }
            }
        } else {
            Text("情報取得に失敗しました")
                .foregroundColor(.gray)
        }
    }
    
    private func isValidField () -> Bool {
        return !id.isEmpty &&
        !jpName.isEmpty &&
        !enName.isEmpty &&
        !rarity.isEmpty &&
        !element.isEmpty &&
        !weaponType.isEmpty &&
        !extraStatusName.isEmpty &&
        !hp.isEmpty &&
        !attack.isEmpty &&
        !defense.isEmpty &&
        !extraStatusValue.isEmpty
    }
}
