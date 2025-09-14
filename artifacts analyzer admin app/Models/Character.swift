import FirebaseFirestore

struct Character: Identifiable, Codable {
    var id: String {enName}
    let HP: Int
    let attack: Int
    let defense: Int
    let element: String
    let enName: String
    let extraStatusName: String
    let extraStatusValue: Double
    let imgUrl: URL
    let jpName: String
    let rarity: Int
    let weaponType: String
    // ここからはadmin専用
    let hoyolabId: Int
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
