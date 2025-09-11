//
//  Weapon.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/07.
//

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
}
