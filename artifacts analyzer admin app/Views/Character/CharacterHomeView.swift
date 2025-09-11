import SwiftUI

// 配列パスとして使う列挙型
enum CharacterPath {
    case addCharacterPath, displayCharactersPath, displayCharacterDetailPath
}

struct CharacterHomeView: View {
    // enumをデータ型に指定した配列パス
    @State private var navigationPath: [CharacterPath] = []
    
    @StateObject private var characterViewModel = CharacterViewModel()
    @StateObject private var safariOpener = SafariOpener()
    
    var body: some View {
        NavigationStack (path: $navigationPath){
            List {
                HomeListChild(
                    leftIconName: "icloud.and.arrow.up",
                    title: "キャラクターを追加する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.addCharacterPath)}
                )
                
                HomeListChild(
                    leftIconName: "icloud.and.arrow.down",
                    title: "追加したキャラクターを確認する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.displayCharactersPath)}
                )
                
                HomeListChild(
                    leftIconName: "list.bullet",
                    title: "hoyolabでキャラクター図鑑を見る",
                    rightIconName: "arrow.up.right.square",
                    onTap: {
                        safariOpener.open(urlString: "https://wiki.hoyolab.com/m/genshin/aggregate/2?lang=ja-jp")
                    }
                )
            }
            .navigationTitle("キャラクター ホーム")
            .navigationDestination(for: CharacterPath.self) { value in
                switch value {
                case .addCharacterPath:
                    AddCharacterView(path: $navigationPath, characterViewModel: characterViewModel)
                case .displayCharactersPath:
                    DisplayCharactersView(path: $navigationPath, characterViewModel: characterViewModel)
                case .displayCharacterDetailPath:
                    DisplayCharacterDetailView(path: $navigationPath, characterViewModel: characterViewModel)
                }
            }
        }}
}
