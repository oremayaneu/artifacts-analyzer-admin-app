import SwiftUI
import PhotosUI

struct AddArtifactView: View {
    @Binding var path: [ArtifactPath]
    @ObservedObject var artifactViewModel: ArtifactViewModel
    
    @State private var errorMessage = ""
    
    // スクレイピング・追加用のデータ
    @State private var isScrape = false
    @State private var errorScrapeFlg = false
    
    @State private var id = ""
    
    @State private var jpName = ""
    @State private var enName = ""
    
    @State private var partNameList: [String] = Array(repeating: "", count: 5)
    @State private var imgUrlList: [URL?] = Array(repeating: nil, count: 5)
    
    @State private var twoSetEffectSentence = ""
    @State private var fourSetEffectSentence = ""
    
    // 全体で共有するフォーカス管理
    @FocusState private var isKeyboardActive: Bool
    
    // firebaseに書き込み
    @State private var isCreate = false
    @State private var errorCreateFlg = false
    
    @State private var selectedItems: [PhotosPickerItem?] = Array(repeating: nil, count: 5)
    @State private var selectedImageDatas: [Data?] = Array(repeating: nil, count: 5)
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
                            LabeledTextField(label: "hoyolab URL または ID", text: $id, focusField: $isKeyboardActive)
                            Button("自動取得", action: {
                                // キーボードを閉じる
                                isKeyboardActive = false
                                isScrape.toggle()
                                // 初期化
                                resetField()
                                imgUrlList = Array(repeating: nil, count: 5)
                                
                                // 入力のパターンがURL
                                if let url = URL(string: id) {
                                    id = url.lastPathComponent // 最後のpathを取得
                                }
                                if Int(id) == nil  {
                                    id = ""
                                    errorCreateFlg = true
                                    errorMessage = "自動取得において不正な値が入力されました"
                                    return
                                }
                                
                                // スクレイピング開始
                                artifactViewModel.fetchArtifactAPI(
                                    id: id,
                                    completion: {_names, _effects, _partNames, _partIcons in
                                        jpName = _names[0]
                                        enName = _names[1]
                                        
                                        twoSetEffectSentence = _effects[0]
                                        fourSetEffectSentence = _effects[1]
                                        
                                        partNameList = _partNames
                                        
                                        for i in 0 ..< 5 {
                                            if let url = URL(string: _partIcons[i]), isValidField() {
                                                imgUrlList[i] = url
                                                selectedItems[i] = nil
                                                selectedImageDatas[i] = nil
                                                errorScrapeFlg = false
                                                errorMessage = ""
                                            } else {
                                                errorScrapeFlg = true
                                                errorMessage = "データの取得に失敗しました"
                                                break
                                            }
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
                        
                        VStack(spacing: 10) {
                            // 聖遺物の画像5種類
                            ForEach(0..<5, id: \.self) { i in
                                
                                HStack(spacing: 20) {
                                    // 公式apiからimgUrlを取得できた場合
                                    if let url = imgUrlList[i] {
                                        NetworkImage(url: url)
                                            .frame(width: 70, height: 70)
                                        
                                    } else {
                                        SelectableImageView(selectedItem: $selectedItems[i], selectedImageData: $selectedImageDatas[i], imageSize: 70, iconSize: 15)
                                    }
                                    
                                    // 部位の名前
                                    LabeledTextField(label: artifactPartTitles[i], text: $partNameList[i], limit: 30, focusField: $isKeyboardActive)
                                }
                            }
                        }
                        
                        HStack {
                            LabeledTextField(label: "和名", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                            LabeledTextField(label: "英名", text: $enName, limit: 50, focusField: $isKeyboardActive)
                        }
                        
                        LabeledTextEditor(label: "2セット効果", text: $twoSetEffectSentence, limit: 1000, height: 75, focusField: $isKeyboardActive)
                        LabeledTextEditor(label: "4セット効果", text: $fourSetEffectSentence, limit: 1000, focusField: $isKeyboardActive)
                        
                        Button("聖遺物を追加", action: {
                            Task{
                                isKeyboardActive = false
                                isCreate.toggle()
                                
                                // 外部から取得した画像urlがある場合、selectedImageDataに落とし込む
                                for i in 0 ..< 5 {
                                    if let url = imgUrlList[i] {
                                        let (data, _) = try await URLSession.shared.data(from: url)
                                        selectedImageDatas[i] = data
                                    }
                                    if selectedImageDatas[i] == nil {
                                        isCreate.toggle()
                                        errorCreateFlg = true
                                        errorMessage = "聖遺物画像が選択されていません"
                                        return
                                    }
                                }
                                
                                var uploadUrls: [URL?] = Array(repeating: nil, count: 5)
                                // storageにアップロード
                                for i in 0 ..< 5 {
                                    uploadUrls[i] = await uploadImageViewModel.uploadImage(
                                        data: selectedImageDatas[i]!,
                                        imgType: "artifact",
                                        imgName: "\(enName)\(i)"
                                    )
                                    if uploadUrls[i] == nil {
                                        isCreate.toggle()
                                        errorCreateFlg = true
                                        errorMessage = "聖遺物画像が正しくありません"
                                        return
                                    }
                                }
                                
                                let urls = uploadUrls.compactMap { $0 } // [URL] に変換
                                let artifact = Artifact (
                                    jpName: jpName,
                                    enName: enName,
                                    partNameList: partNameList,
                                    imgUrlList: urls,
                                    twoSetEffectSentence: twoSetEffectSentence,
                                    fourSetEffectSentence: fourSetEffectSentence,
                                    hoyolabId: Int(id) ?? 0
                                )
                                
                                artifactViewModel.createArtifact(
                                    artifact: artifact,
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
                                        withAnimation {
                                            reader.scrollTo("top")
                                        }
                                    },
                                    errorHandling: {
                                        // エラー時の処理
                                        isCreate.toggle()
                                        errorCreateFlg = true
                                        errorMessage = "聖遺物データの保存に失敗しました"
                                    }
                                )
                                
                            }
                        })
                        .disabled(!isValidField() ||
                                  ( selectedImageDatas.contains(where: { $0 == nil }) && imgUrlList.contains(where: { $0 == nil }) )
                        )
                        .buttonStyle(.borderedProminent).padding(.vertical, 30)
                        
                    }.padding(.horizontal, 30)
                }.toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完了") {
                            isKeyboardActive = false // キーボード閉じる
                        }
                    }
                }
            }
            
            if isScrape || isCreate {
                BlockingIndicator()
            }
            
            ToastView(showToast: $showToast, showMessage: "聖遺物を追加しました")
        }
        .navigationTitle("聖遺物追加")
    }
    
    private func isValidField () -> Bool {
        return !jpName.isEmpty &&
        !enName.isEmpty &&
        !twoSetEffectSentence.isEmpty &&
        !fourSetEffectSentence.isEmpty &&
        partNameList.allSatisfy { $0 != "" }
    }
    
    private func resetField () {
        jpName = ""
        enName = ""
        twoSetEffectSentence = ""
        fourSetEffectSentence = ""
        partNameList = Array(repeating: "", count: 5)
        
        // 画像関連のリセット
        imgUrlList = Array(repeating: nil, count: 5)
        selectedItems = Array(repeating: nil, count: 5)
        selectedImageDatas = Array(repeating: nil, count: 5)
    }
}
