import SwiftUI
import PhotosUI

struct AddCharacterView: View {
    @Binding var path: [CharacterPath]
    @ObservedObject var characterViewModel: CharacterViewModel
    
    @State private var errorMessage = ""
    
    // スクレイピング・追加用のデータ
    @State private var isScrape = false
    @State private var errorScrapeFlg = false
    
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
                            isKeyboardActive = false
                            // 初期化
                            resetField()
                            // スクレイピング開始
                            isScrape.toggle()
                        })
                        .disabled(id.isEmpty)
                        .buttonStyle(.bordered).padding(.top,20)
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images){
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 25))
                                )
                        }
                    }
                    .onChange(of: selectedItem) {
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    
                    HStack {
                        LabeledTextField(label: "和名", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                        LabeledTextField(label: "英名", text: $enName, limit: 30, focusField: $isKeyboardActive)
                    }
                    
                    HStack {
                        LabeledTextField(label: "レアリティ", text: $rarity, isUsePicker: true, pickerOptions: ["5", "4"])
                        LabeledTextField(label: "元素", text: $element, isUsePicker: true, pickerOptions: ["炎","水","風","氷","岩","草","雷"])
                        LabeledTextField(label: "武器種", text: $weaponType, isUsePicker: true, pickerOptions: weaponTypes)
                    }
                    
                    HStack {
                        LabeledTextField(label: "HP", text: $hp, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LabeledTextField(label: "攻撃力", text: $attack, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                        LabeledTextField(label: "防御力", text: $defense, numberType: "Int", limit: 5, focusField: $isKeyboardActive)
                    }
                    
                    HStack {
                        LabeledTextField(label: "突破ステータス: 種類", text: $extraStatusName, isUsePicker: true, pickerOptions: statusNames)
                        HStack {
                            LabeledTextField(label: ": 値", text: $extraStatusValue, numberType: "Double", limit: 5, focusField: $isKeyboardActive)
                            if extraStatusName != "元素熟知" {
                                Text("%").padding(.top, 20)
                            }
                        }
                    }
                    
                    Button("キャラクターを追加", action: {
                        Task {
                            isKeyboardActive = false
                            isCreate.toggle()
                            if let data = selectedImageData {
                                let imgUrl = await uploadImageViewModel.uploadImage(
                                    data: data,
                                    imgType: "character",
                                    imgName: enName
                                )
                                
                                if imgUrl != nil {
                                    var character = Character (
                                        HP: Int(hp) ?? 0,
                                        attack: Int(attack) ?? 0,
                                        defense: Int(defense) ?? 0,
                                        element: "",    // 後から設定
                                        enName: enName,
                                        extraStatusName: extraStatusName,
                                        extraStatusValue: Double(extraStatusValue) ?? 0,
                                        imgUrl: imgUrl!,
                                        jpName: jpName,
                                        rarity: Int(rarity) ?? 0,
                                        weaponType: weaponType,
                                        hoyolabId: Int(id) ?? 0
                                    )
                                    character.translateElement = element

                                    characterViewModel.createCharacter(
                                        character: character,
                                        completion: {
                                            // 成功時の処理
                                            isCreate.toggle()
                                            errorCreateFlg = false
                                            errorMessage = ""
                                            showToast = true
                                            
                                            // 初期化
                                            id = ""
                                            resetField()
                                        },
                                        errorHandling: {
                                            // エラー時の処理
                                            isCreate.toggle()
                                            errorCreateFlg = true
                                            errorMessage = "キャラクターデータの保存に失敗しました"
                                        }
                                    )
                                } else {
                                    isCreate.toggle()
                                    errorCreateFlg = true
                                    errorMessage = "キャラクター画像の保存に失敗しました"
                                }
                            }
                        }
                    })
                    .disabled(!isValidField() || selectedImageData == nil)
                    .buttonStyle(.borderedProminent).padding(.vertical, 30)
                    
                    if isScrape {
                        // スクレイピングでデータを取得
                        ScrapingCharacter(
                            url: URL(string: "https://wiki.hoyolab.com/pc/genshin/entry/\(id)")!,
                            onLoaded: {name, tags, values in
                                // nameの処理
                                let parts = name.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                                jpName = parts[0]
                                enName = parts[1]
                                
                                // tagsの処理
                                for tag in tags {
                                    if tag.contains("★") {
                                        rarity = TrimString(str: tag, start: 1, end: 1)
                                    } else if tag.contains("元素") {
                                        element = TrimString(str: tag, start: 0, end: 0)
                                    } else if weaponTypes.contains(tag) {
                                        weaponType = tag
                                    } else if statusNames.contains(tag){
                                        extraStatusName = tag
                                    }
                                }
                                
                                // valuesの処理
                                hp = values[0].replacingOccurrences(of: ",", with: "")
                                attack = values[1].replacingOccurrences(of: ",", with: "")
                                defense = values[2].replacingOccurrences(of: ",", with: "")
                                extraStatusValue = values[3].replacingOccurrences(of: "%", with: "")
                                
                                if isValidField() {
                                    // 全てのフィールドが埋まった場合、errorFlgの削除
                                    errorScrapeFlg = false
                                    errorMessage = ""
                                } else {
                                    errorScrapeFlg = true
                                    errorMessage = "データの取得に失敗しました"
                                }
                            },
                            onLoading: {
                                isScrape.toggle()
                            },
                            onError: {
                                errorScrapeFlg = true
                                errorMessage = "データの取得に失敗しました"
                            }
                        ).frame(height: 0)   // WebViewは高さ0にして裏で読み込みだけする
                    }
                }.padding(.horizontal, 30)
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        isKeyboardActive = false // キーボード閉じる
                    }
                }
            }
            
            ToastView(showToast: $showToast, showMessage: "キャラクターを追加しました")
            
            if isScrape || isCreate {
                BlockingIndicator()
            }
        }.navigationTitle("キャラクター追加")
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
    
    private func resetField() {
        jpName = ""
        enName = ""
        rarity = ""
        element = ""
        weaponType = ""
        extraStatusName = ""
        hp = ""
        attack = ""
        defense = ""
        extraStatusValue = ""
        
        // 画像関連のリセット
        selectedItem = nil
        selectedImageData = nil
    }
}
