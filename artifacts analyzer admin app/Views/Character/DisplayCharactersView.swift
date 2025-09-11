import SwiftUI

struct DisplayCharactersView: View {
    @Binding var path: [CharacterPath]
    @ObservedObject var characterViewModel: CharacterViewModel  // ← 外から注入 // 新しいインスタンスを生成すると、他画面と独立してしまうため
    
    var body: some View {
        Group {
            if (!characterViewModel.isLoadingAllCharacters && characterViewModel.characters.count > 0){
                List(characterViewModel.characters) { character in
                    Button(character.jpName) {
                        Task {
                            await characterViewModel.fetchCharacter(enName: character.enName)
                            path.append(.displayCharacterDetailPath)
                        }
                    }.foregroundColor(.primary)
                }
                .navigationTitle("キャラクター一覧")
            } else if characterViewModel.isLoadingAllCharacters {
                BlockingIndicator() // 全画面ブロッキングインジケータ
            } else {
                Text("No character")
            }
        }
        .onAppear {
            Task {
                await characterViewModel.fetchAllCharacters()
            }
        }
    }
}
