import SwiftUI

struct DisplayCharacterDetailView: View {
    @Binding var path: [CharacterPath]
    @ObservedObject var characterViewModel: CharacterViewModel
    
    @State private var isEditing = false
    
    // 編集用の一時データ
    @State private var jpName = ""
    @State private var enName = ""
    @State private var rarity = ""
    @State private var element = ""
    @State private var weaponType = ""
    @State private var hp = ""
    @State private var attack = ""
    @State private var defense = ""
    
    // 属性候補
    private let elements = ["炎", "水", "風", "雷", "氷", "岩", "草"]
    
    var body: some View {
            if characterViewModel.isLoadingCharacter {
                BlockingIndicator()
            } else if let character = characterViewModel.character {
                List {
                    // キャラ画像
                    NetworkImage(url: character.imgUrl).frame(width: 120, height: 120).frame(maxWidth: .infinity, alignment: .center)
                    
                    // 名前
                    if isEditing {
                        TextField("名前(JP)", text: $jpName)
                        TextField("名前(EN)", text: $enName)
                    } else {
                        ProfileListChild(leftText: "名前(JP)", rightText: character.jpName)
                        ProfileListChild(leftText: "名前(EN)", rightText: character.enName)
                    }
                    
                    // レアリティ
                    if isEditing {
//                        Stepper("レアリティ: \(rarity)", value: $rarity, in: 1...5)
                    } else {
                        ProfileListChild(leftText: "レアリティ", rightText: "\(character.rarity)")
                    }
                    
                    // 元素
                    if isEditing {
                        Picker("元素", selection: $element) {
                            ForEach(elements, id: \.self) { elem in
                                Text(elem)
                            }
                        }
                        .pickerStyle(.wheel)
                    } else {
                        ProfileListChild(leftText: "元素", rightText: translateFromEnElement(element: character.element))
                    }
                    
                    // 武器種
                    if isEditing {
                        TextField("武器種", text: $weaponType)
                    } else {
                        ProfileListChild(leftText: "武器種", rightText: character.weaponType)
                    }
                    
                    // ステータス
                    if isEditing {
                        TextField("HP", text: $hp)
                            .keyboardType(.numberPad)
                        TextField("攻撃力", text: $attack)
                            .keyboardType(.numberPad)
                        TextField("防御力", text: $defense)
                            .keyboardType(.numberPad)
                    } else {
                        ProfileListChild(leftText: "HP", rightText: "\(character.HP)")
                        ProfileListChild(leftText: "攻撃力", rightText: "\(character.attack)")
                        ProfileListChild(leftText: "防御力", rightText: "\(character.defense)")
                    }
                    ProfileListChild(leftText: "突破ステータス", rightText: "\(removeTrailingPercent(str: character.extraStatusName)) \(addTrailingPercent(key: character.extraStatusName, value: character.extraStatusValue))")
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
                                // 編集終了時: 更新処理
                            } else {
                                // 編集開始時: 現在の値をコピー
                                jpName = character.jpName
                                enName = character.enName
                                rarity = "\(character.rarity)"
                                element = translateFromEnElement(element: character.element)
                                weaponType = character.weaponType
                                hp = "\(character.HP)"
                                attack = "\(character.attack)"
                                defense = "\(character.defense)"
                            }
                            isEditing.toggle()
                        }
                    }
                }
            } else {
                Text("情報取得に失敗しました")
                    .foregroundColor(.gray)
            }
    }
}
