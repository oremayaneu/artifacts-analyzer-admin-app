import Foundation
import Combine
import FirebaseFirestore
import SwiftSoup
import WebKit

@MainActor // バックグラウンドでpublishedの値を更新してスタックすることを防ぐ
class CharacterViewModel: ObservableObject {
    @Published var characters: [CharacterDigest] = []
    @Published var isLoadingAllCharacters: Bool = false
    
    @Published var character: Character?
    @Published var isLoadingCharacter: Bool = false
    
    func fetchAllCharacters() async {
        isLoadingAllCharacters = true
        defer { isLoadingAllCharacters = false } // 抜ける時の処理
        
        do {
            let snapshot = try await db.collection("characters")
                .order(by: "hoyolabId", descending: true)
                .getDocuments()
            print("complete fetching all characters")
            
            self.characters = snapshot.documents.compactMap { doc in
                try? doc.data(as: CharacterDigest.self)
            }
        } catch {
            print("error fetching all characters: \(error)")
        }
    }
    
    func fetchCharacter(enName: String) async {
        isLoadingCharacter = true
        defer { isLoadingCharacter = false }
        
        do {
            let document = try await db.collection("characters").document(enName).collection("parameter").document("parameter").getDocument()
            
            self.character = try document.data(as: Character.self)
            print("complete fetching \(self.character!.jpName)")
        } catch {
            print("error fetching \(enName): \(error)")
        }
    }
    
    func createCharacter(character: Character, completion: @escaping () -> Void, errorHandling: @escaping () -> Void) {
        self.saveParameters(for: character) { error in
            if let error = error {
                print("parameters書き込みエラー: \(error)")
                errorHandling()
                return
            }
            
            self.saveDigest(for: character) { error in
                if let error = error {
                    print("digest書き込みエラー: \(error)")
                    errorHandling()
                    return
                }
                
                db.collection("admin").document("createTimestamp").updateData(["createdCharacter": FieldValue.serverTimestamp()]) { error in
                    if let error = error {
                        print("timestamp書き込みエラー: \(error)")
                        errorHandling()
                        return
                    }
                    
                    self.character = character
                    completion()
                }
            }
        }
    }
    
    private func saveParameters(for character: Character, completion: @escaping (Error?) -> Void) {
        do {
            try db.collection("characters")
                .document(character.enName)
                .collection("parameter")
                .document("parameter")
                .setData(from: character, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    private func saveDigest(for character: Character, completion: @escaping (Error?) -> Void) {
        let digest = CharacterDigest(
            element: character.element,
            enName: character.enName,
            imgUrl: character.imgUrl,
            jpName: character.jpName,
            rarity: character.rarity,
            hoyolabId: character.hoyolabId
        )
        do {
            try db.collection("characters")
                .document(character.enName)
                .setData(from: digest, completion: completion)
        } catch {
            completion(error)
        }
    }
}
