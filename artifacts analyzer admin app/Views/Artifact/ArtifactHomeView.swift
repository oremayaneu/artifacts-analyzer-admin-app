import SwiftUI

// 配列パスとして使う列挙型
enum ArtifactPath {
    case addArtifactPath, displayArtifactsPath, displayArtifactDetailPath
}

struct ArtifactHomeView: View {
    // enumをデータ型に指定した配列パス
    @State private var navigationPath: [ArtifactPath] = []
    
    @StateObject private var artifactViewModel = ArtifactViewModel()
    @StateObject private var safariOpener = SafariOpener()
    
    var body: some View {
        NavigationStack (path: $navigationPath){
            List {
                HomeListChild(
                    leftIconName: "icloud.and.arrow.up",
                    title: "聖遺物を追加する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.addArtifactPath)}
                )
                
                HomeListChild(
                    leftIconName: "icloud.and.arrow.down",
                    title: "追加した聖遺物を確認する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.displayArtifactsPath)}
                )
                
                HomeListChild(
                    leftIconName: "list.bullet",
                    title: "hoyolabで聖遺物図鑑を見る",
                    rightIconName: "arrow.up.right.square",
                    onTap: {
                        safariOpener.open(urlString: "https://wiki.hoyolab.com/m/genshin/aggregate/5?lang=ja-jp")
                    }
                )
            }
            .navigationTitle("聖遺物 ホーム")
            .navigationDestination(for: ArtifactPath.self) { value in
                switch value {
                case .addArtifactPath:
                    AddArtifactView(path: $navigationPath, artifactViewModel: artifactViewModel)
                case .displayArtifactsPath:
                    DisplayArtifactsView(path: $navigationPath)
                case .displayArtifactDetailPath:
                    DisplayArtifactDetailView(path: $navigationPath)
                }
            }
        }}
}
