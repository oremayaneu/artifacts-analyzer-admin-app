import FirebaseFirestore

struct Weapon: Identifiable, Codable {
    var id: String {enName}
    let attack: Int
    let effectSentence: [String]
    let enName: String
    let finalEffectValue: [Double]
    let imgUrl: URL
    let initialEffectValue: [Double]
    let jpName: String
    let rarity: Int
    let subStatusName: String
    let subStatusValue: Double
    let type: String
    // ここからはadmin専用
    let hoyolabId: Int
    
    // effect sentenceの処理
    var getEffect: String {
        get {
            var text = ""
            for i in 0 ..< initialEffectValue.count {
                text += effectSentence[i]
                text += "$(\(initialEffectValue[i]),\(finalEffectValue[i])"
            }
            text += effectSentence[initialEffectValue.count]
            return text
        }
    }
}
