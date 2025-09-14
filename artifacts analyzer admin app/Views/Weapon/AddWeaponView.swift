import SwiftUI
import PhotosUI
import Combine

struct AddWeaponView: View {
    @Binding var path: [WeaponPath]
    @ObservedObject var weaponViewModel: WeaponViewModel
    
    @State private var errorMessage = ""
    
    @State private var isShowHelp = false
    
    // スクレイピング・追加用のデータ
    @State private var isScrape = false
    @State private var errorScrapeFlg = false
    
    @State private var id = ""
    
    @State private var jpName = ""
    @State private var enName = ""
    
    @State private var rarity = ""
    @State private var type = ""
    
    @State private var attack = ""
    @State private var subStatusName = ""
    @State private var subStatusValue = ""
    
    @State private var effect = ""
    @State private var effectSentence = []
    @State private var initialEffectValue = []
    @State private var finalEffectValue = []
    
    @State private var imgUrl: URL?
    
    // 全体で共有するフォーカス管理
    @FocusState private var isKeyboardActive: Bool
    
    // firebaseに書き込み
    @State private var isCreate = false
    @State private var errorCreateFlg = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @StateObject private var uploadImageViewModel = UploadImageViewModel()
    
    @State private var showToast = false
    
    var body: some View {
        
        ZStack {
            ScrollViewReader { reader in
                ScrollView {
                    // スクロール用のダミー
                    Color.clear.frame(height: 1)
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    
                    VStack(spacing: 20) {
                        
                        if errorScrapeFlg || errorCreateFlg {
                            ErrorWidget(errorMessage: errorMessage)
                        }
                        
                        HStack {
                            LabeledTextField(label: "hoyolab ID", text: $id, numberType: "Int", focusField: $isKeyboardActive)
                            Button("自動取得", action: {
                                // キーボードを閉じる
                                isKeyboardActive = false
                                isScrape.toggle()
                                // 全てのfieldを初期化
                                resetField()
                                imgUrl = nil
                                
                                weaponViewModel.fetchWeaponAPI(
                                    id: id,
                                    completion: { _jpName, _enName, _rarity, _type, _attack, _subStatusName, _subStatusValue, _effect, _imgUrl in
                                        jpName = _jpName
                                        enName = _enName
                                        rarity = _rarity
                                        type = _type
                                        attack = _attack
                                        subStatusName = _subStatusName.replacingOccurrences(of: "パーセンテージ", with: "")
                                        subStatusValue = _subStatusValue.replacingOccurrences(of: "%", with: "")
                                        effect = _effect
                                        
                                        if let url = URL(string: _imgUrl), isValidField() {
                                            imgUrl = url
                                            selectedItem = nil
                                            selectedImageData = nil
                                            errorScrapeFlg = false
                                            errorMessage = ""
                                        } else {
                                            errorScrapeFlg = true
                                            errorMessage = "データの取得に失敗しました"
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            isScrape.toggle()
                                        }
                                    },
                                    errorHandling: {
                                        errorScrapeFlg = true
                                        errorMessage = "データの取得に失敗しました"
                                        isScrape.toggle()
                                    }
                                )
                            })
                            .disabled(id.isEmpty)
                            .buttonStyle(.bordered).padding(.top,20)
                        }
                        
                        // 公式apiからimgUrlを取得できた場合
                        if let url = imgUrl {
                            NetworkImage(url: url)
                                .frame(width: 200, height: 200)
                            
                        } else {
                            SelectableImageView(selectedItem: $selectedItem, selectedImageData: $selectedImageData, imageSize: 200, iconSize: 25)
                        }
                        
                        HStack {
                            LabeledTextField(label: "和名", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                            LabeledTextField(label: "英名", text: $enName, limit: 50, focusField: $isKeyboardActive)
                        }
                        
                        HStack {
                            LabeledTextField(label: "レアリティ", text: $rarity, isUsePicker: true, pickerOptions: ["5", "4", "3"])
                            LabeledTextField(label: "武器種", text: $type, isUsePicker: true, pickerOptions: weaponTypes)
                        }
                        
                        HStack {
                            LabeledTextField(label: "攻撃力", text: $attack, numberType: "Int", limit: 4, focusField: $isKeyboardActive)
                                .frame(width:70)
                            LabeledTextField(label: "サブステータス: 種類", text: $subStatusName, isUsePicker: true, pickerOptions: statusNames)
                            HStack {
                                LabeledTextField(label: ": 値", text: $subStatusValue, numberType: "Double", limit: 5, focusField: $isKeyboardActive)
                                if subStatusName != "元素熟知" {
                                    Text("%").padding(.top, 20)
                                }
                            }
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("武器効果")
                                    .font(.caption)
                                Spacer()
                                
                                Button(action: {isShowHelp.toggle()}){Image(systemName: isShowHelp ? "info.circle.fill": "info.circle")}
                            }
                            if isShowHelp {
                                HStack {
                                    Spacer()
                                    Text("精錬ランクによって変動する箇所を$(初期値,最終値)に書き換えてください。\n例えば、「攻撃力+2/4/6/8/10%」の箇所は「攻撃力+$(2,10)%」とします。")
                                        .font(.system(size: 9.5))
                                        .frame(width: 200)
                                        .padding(2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(.appTheme)
                                        )
                                }
                            }
                            
                            LabeledTextEditor(label: "", text: $effect, limit: 1000, focusField: $isKeyboardActive)
                        }
                        
                        
                        Button("武器を追加", action: {
                            Task {
                                isKeyboardActive = false
                                isCreate.toggle()
                                // effectのstringからconst部分とvar部分を分割
                                getConstAndVariableEffect(effect: effect)
                                
                                if let data = selectedImageData {
                                    imgUrl = await uploadImageViewModel.uploadImage(
                                        data: data,
                                        imgType: "weapon",
                                        imgName: enName
                                    )
                                }
                                
                                if imgUrl != nil {
                                    let weapon = Weapon (
                                        attack: Int(attack) ?? 0,
                                        effectSentence: (effectSentence as? [String]) ?? [""],
                                        enName: enName,
                                        finalEffectValue: (finalEffectValue as? [Double]) ?? [0.0],
                                        imgUrl: imgUrl!,
                                        initialEffectValue: (initialEffectValue as? [Double]) ?? [0.0],
                                        jpName: jpName,
                                        rarity: Int(rarity) ?? 0,
                                        subStatusName: subStatusName,
                                        subStatusValue: Double(subStatusValue) ?? 0,
                                        type: type,
                                        
                                        hoyolabId: Int(id) ?? 0
                                    )
                                    
                                    weaponViewModel.createWeapon(
                                        weapon: weapon,
                                        completion: {
                                            // 成功時の処理
                                            isCreate.toggle()
                                            errorCreateFlg = false
                                            errorMessage = ""
                                            showToast = true
                                            
                                            // 初期化
                                            id = ""
                                            resetField()
                                            
                                            // 上へスクロール
                                            withAnimation(.default) {
                                                reader.scrollTo("top")
                                            }
                                        },
                                        errorHandling: {
                                            // エラー時の処理
                                            isCreate.toggle()
                                            errorCreateFlg = true
                                            errorMessage = "武器データの保存に失敗しました"
                                        }
                                    )
                                } else {
                                    isCreate.toggle()
                                    errorCreateFlg = true
                                    errorMessage = "武器画像が正しくありません"
                                }
                            }
                        })
                        .disabled(!isValidField() || (selectedImageData == nil && imgUrl == nil))
                        .buttonStyle(.borderedProminent).padding(.vertical, 30)
                    }
                    .padding(.horizontal, 30)
                }.toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完了") {
                            isKeyboardActive = false // キーボード閉じる
                        }
                    }
                }
            }
            
            ToastView(showToast: $showToast, showMessage: "武器を追加しました")
            
            if isScrape || isCreate {
                BlockingIndicator()
            }
        }
        .navigationTitle("武器追加")
    }
    
    private func getConstAndVariableEffect (effect: String) {
        // 正規表現パターン: ${...} の中身をキャプチャ
        let pattern = #"\$\(([^)]*)\)"#
        
        // 初期化
        self.initialEffectValue = []
        self.finalEffectValue = []
        self.effectSentence = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: effect, range: NSRange(effect.startIndex..., in: effect))
            
            // 数値の抽出
            let values = matches.compactMap {
                Range($0.range(at: 1), in: effect).map { String(effect[$0]) }
            }
            
            for value in values {
                let list = value.split(separator: ",")
                self.initialEffectValue.append(Double(list[0]) ?? 0.0)
                self.finalEffectValue.append(Double(list[1]) ?? 0.0)
            }
            
            // string部分の抽出
            var lastIndex = effect.startIndex
            for match in matches {
                let range = Range(match.range, in: effect)!
                
                // ${...} の前の固定部分
                if lastIndex < range.lowerBound {
                    self.effectSentence.append(String(effect[lastIndex..<range.lowerBound]))
                }
                lastIndex = range.upperBound
            }
            
            // 最後の残り部分
            if lastIndex < effect.endIndex {
                self.effectSentence.append(String(effect[lastIndex..<effect.endIndex]))
            }
            
        } catch {
            print("正規表現エラー: \(error)")
        }
    }
    
    private func isValidField () -> Bool {
        return !jpName.isEmpty && !enName.isEmpty && !rarity.isEmpty && !type.isEmpty && !attack.isEmpty && !subStatusName.isEmpty && !subStatusValue.isEmpty && !effect.isEmpty
    }
    
    private func resetField () {
        jpName = ""
        enName = ""
        rarity = ""
        type = ""
        attack = ""
        subStatusName = ""
        subStatusValue = ""
        effect = ""
        
        // 画像関連のリセット
        imgUrl = nil
        selectedItem = nil
        selectedImageData = nil
    }
}
