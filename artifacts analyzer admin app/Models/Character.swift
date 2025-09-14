import FirebaseFirestore

struct Character: Identifiable, Codable {
    var id: String {enName}
    let HP: Int
    let attack: Int
    let defense: Int
    var element: String
    let enName: String
    let extraStatusName: String
    let extraStatusValue: Double
    let imgUrl: URL
    let jpName: String
    let rarity: Int
    let weaponType: String
    // ここからはadmin専用
    let hoyolabId: Int
    
    var translateElement: String {
        get {
            elements.first { $0.value == element }?.key ?? "元素なし"   // 英語から日本語
        }
        set {
            element = elements[newValue] ?? "No element"    // 日本語から英語
        }
    }
}

struct CharacterDigest: Identifiable, Codable {
    var id: String {enName}
    let element: String
    let enName: String
    let imgUrl: URL
    let jpName: String
    let rarity: Int
    // ここからはadmin専用
    let hoyolabId: Int
}
