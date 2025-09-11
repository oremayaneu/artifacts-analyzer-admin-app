import SwiftUI

struct DisplayWeaponDetailView: View {
    @Binding var path: [WeaponPath]
    @ObservedObject var weaponViewModel: WeaponViewModel
    
    @State private var isEditing = false
    
    // 編集用の一時データ
    @State private var jpName = ""
    @State private var enName = ""
    @State private var rarity = ""
    @State private var type = ""
    @State private var attack = ""
    @State private var subStatusName = ""
    @State private var subStatusValue = ""
    @State private var effectSentence = []
    @State private var initialEffectValue = []
    @State private var finalEffectValue = []
    
    var body: some View {
        if let weapon = weaponViewModel.selectedWeapon {
            List {
                // キャラ画像
                NetworkImage(url: weapon.imgUrl).frame(width: 120, height: 120).frame(maxWidth: .infinity, alignment: .center)
                
                // 名前
                if isEditing {
                    TextField("名前(JP)", text: $jpName)
                    TextField("名前(EN)", text: $enName)
                } else {
                    ProfileListChild(leftText: "名前(JP)", rightText: weapon.jpName)
                    ProfileListChild(leftText: "名前(EN)", rightText: weapon.enName)
                }
                
                // レアリティ
                if isEditing {
                    //                    Stepper("レアリティ: \(rarity)", value: $rarity, in: 1...5)
                } else {
                    ProfileListChild(leftText: "レアリティ", rightText: "\(weapon.rarity)")
                }
                
                // 武器種
                if isEditing {
                    TextField("武器種", text: $type)
                } else {
                    ProfileListChild(leftText: "武器種", rightText: weapon.type)
                }
                
                // ステータス
                if isEditing {
                    TextField("攻撃力", text: $attack)
                    //                    TextField("サブステータス", text: $enName)
                } else {
                    ProfileListChild(leftText: "攻撃力", rightText: "\(weapon.attack)")
                    ProfileListChild(leftText: "サブステータス", rightText: "\(removeTrailingPercent(str: weapon.subStatusName)) \(addTrailingPercent(key: weapon.subStatusName, value: weapon.subStatusValue))")
                }
                
                // 効果
                if isEditing {
                    //                    TextField("名前(JP)", text: $jpName)
                    //                    TextField("名前(EN)", text: $enName)
                } else {
                    ProfileListChild(leftText: "効果（精錬1）", rightText: effectSentenceString(stringList: weapon.effectSentence, valueList: weapon.initialEffectValue))
                    ProfileListChild(leftText: "効果（精錬5）", rightText: effectSentenceString(stringList: weapon.effectSentence, valueList: weapon.finalEffectValue))
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
                            // 編集終了時: 更新処理
                        } else {
                            // 編集開始時: 現在の値をコピー
                            jpName = weapon.jpName
                            enName = weapon.enName
                            rarity = "\(weapon.rarity)"
                        }
                        isEditing.toggle()
                    }
                }
            }
        } else {
            Text("エラーが発生しました")
                .foregroundColor(.gray)
        }
    }
    
    private func effectSentenceString (stringList: [String], valueList: [Double]) -> String {
        var sentence = ""
        for i in 0..<valueList.count {
            sentence += "\(stringList[i])\(valueList[i])"
        }
        sentence += stringList[stringList.count - 1]
        return sentence
    }
}
