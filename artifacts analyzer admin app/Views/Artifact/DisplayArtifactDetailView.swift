import SwiftUI

struct DisplayArtifactDetailView: View {
    @Binding var path: [ArtifactPath]
    @ObservedObject var artifactViewModel: ArtifactViewModel
    
    @State private var isEditing = false
    
    // 編集用の一時データ
    @State private var id = ""
    
    @State private var jpName = ""
    @State private var enName = ""
    
    @State private var partNameList: [String] = Array(repeating: "", count: 5)
    @State private var imgUrlList: [String] = Array(repeating: "", count: 5)
    
    @State private var twoSetEffectSentence = ""
    @State private var fourSetEffectSentence = ""
    
    // 全体で共有するフォーカス管理
    @FocusState private var isKeyboardActive: Bool
    
    // firebaseに書き込み
    @State private var isUpdate = false
    @State private var errorUpdateFlg = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        if let artifact = artifactViewModel.selectedArtifact {
            ZStack {
                List {
                    if errorUpdateFlg {
                        ErrorWidget(errorMessage: errorMessage)
                    }
                    
                    // 画像
                    if !isEditing {
                        HStack(spacing: 7) {
                            Spacer()
                            // 聖遺物の画像5種類
                            ForEach(0..<5, id: \.self) { i in
                                NetworkImage(url: artifact.imgUrlList[i])
                                    .frame(width: 60, height: 60)
                            }
                            Spacer()
                        }
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
                        ProfileListChild(leftText: "名前(JP)", rightText: artifact.jpName)
                        ProfileListChild(leftText: "名前(EN)", rightText: artifact.enName)
                    }
                    
                    // パーツの名前
                    if isEditing {
                        ForEach(0..<5, id: \.self) { i in
                            LeftLabeledTextField(label: "\(artifactPartTitles[i])", text: $partNameList[i], limit: 10000, focusField: $isKeyboardActive)
                        }
                    } else {
                        ForEach(0..<5, id: \.self) { i in
                            ProfileListChild(leftText: "\(artifactPartTitles[i])", rightText: artifact.partNameList[i])
                        }
                    }
                    
                    if isEditing {
                        LeftLabeledTextEditor(label: "2セット効果", text: $twoSetEffectSentence, limit: 1000, height: 75, focusField: $isKeyboardActive)
                        LeftLabeledTextEditor(label: "4セット効果", text: $fourSetEffectSentence, limit: 1000, focusField: $isKeyboardActive)
                    } else {
                        ProfileListChild(leftText: "2セット効果", rightText: artifact.twoSetEffectSentence)
                        ProfileListChild(leftText: "4セット効果", rightText: artifact.fourSetEffectSentence)
                    }
                    
                    if isEditing {
                        ForEach(0..<5, id: \.self) { i in
                            LeftLabeledTextField(label: "アイコンURL \(i+1)", text: $imgUrlList[i], limit: 10000, focusField: $isKeyboardActive)
                        }
                    }
                }
                
                ToastView(showToast: $showToast, showMessage: "聖遺物を更新しました")
                
                if isUpdate {
                    BlockingIndicator()
                }
            }
            .navigationTitle("聖遺物詳細")
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
                            let urls = imgUrlList.compactMap { URL(string: $0) }
                            guard urls.count == imgUrlList.count else {
                                errorMessage = "アイコンURLが正しくありません"
                                errorUpdateFlg = true
                                return
                            }
                            
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
                                        errorMessage = "聖遺物の更新に失敗しました"
                                        isEditing.toggle()
                                    }
                                }
                            )
                        } else {
                            // 編集開始時: 現在の値をコピー
                            id = "\(artifact.hoyolabId)"
                            jpName = artifact.jpName
                            enName = artifact.enName
                            partNameList = artifact.partNameList
                            imgUrlList = artifact.imgUrlList.map { $0.absoluteString }
                            twoSetEffectSentence = artifact.twoSetEffectSentence
                            fourSetEffectSentence = artifact.fourSetEffectSentence
                            
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
            Text("情報取得に失敗しました")
                .foregroundColor(.gray)
                .navigationTitle("聖遺物詳細")
        }
    }
    
    private func isValidField() -> Bool {
        return !id.isEmpty &&
        !jpName.isEmpty &&
        !enName.isEmpty &&
        !twoSetEffectSentence.isEmpty &&
        !fourSetEffectSentence.isEmpty &&
        
        partNameList.allSatisfy { !$0.isEmpty } &&
        imgUrlList.allSatisfy { !$0.isEmpty }
    }
}
