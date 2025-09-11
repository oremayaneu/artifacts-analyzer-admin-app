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
            ScrollView {
                VStack(spacing: 20) {
                    
                    if errorScrapeFlg || errorCreateFlg {
                        ErrorWidget(errorMessage: errorMessage)
                    }
                    
                    HStack {
                        LabeledTextField(label: "hoyolab ID", text: $id, numberType: "Int", focusField: $isKeyboardActive)
                        Button("自動取得", action: {
                            isScrape.toggle()
                            // 初期化
                            //                            resetField()
                            imgUrlList = Array(repeating: nil, count: 5)
                            
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
                                        if let url = URL(string: _partIcons[i])
    //                                        , isValidScraping()
                                        {
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
                                    
                                    isScrape.toggle()
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
                                        .frame(width: 60, height: 60)
                                    
                                } else {
                                    PhotosPicker(selection: $selectedItems[i], matching: .images){
                                        if let data = selectedImageDatas[i], let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 60)
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray)
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 15))
                                                )
                                        }
                                    }
                                    .onChange(of: selectedItems[i]) {
                                        Task {
                                            if let data = try? await selectedItems[i]?.loadTransferable(type: Data.self) {
                                                selectedImageDatas[i] = data
                                            }
                                        }
                                    }
                                }
                                
                                // 部位の名前
                                LabeledTextField(label: ["生の花", "死の羽", "時の砂", "空の杯", "理の冠"][i], text: $partNameList[i], limit: 30, focusField: $isKeyboardActive)
                            }
                        }
                    }
                    
                    HStack {
                        LabeledTextField(label: "和名", text: $jpName, limit: 30, focusField: $isKeyboardActive)
                        LabeledTextField(label: "英名", text: $enName, limit: 50, focusField: $isKeyboardActive)
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
            
            if isScrape || isCreate {
                BlockingIndicator()
            }
        }
        .navigationTitle("聖遺物追加")
    }
}
