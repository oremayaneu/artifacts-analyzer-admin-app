import FirebaseFirestore

struct Artifact: Identifiable, Codable {
    var id: String {enName}
    let jpName: String
    let enName: String
    let partNameList: [String]
    let imgUrlList: [URL]
    let twoSetEffectSentence: String
    let fourSetEffectSentence: String
    // ここからはadmin専用
    let hoyolabId: Int
}
