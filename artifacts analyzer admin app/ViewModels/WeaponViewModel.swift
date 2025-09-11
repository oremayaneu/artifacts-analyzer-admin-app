//
//  WeaponViewModel.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/07.
//

import Foundation
import Combine
import FirebaseFirestore
import SwiftSoup
import WebKit

@MainActor // バックグラウンドでpublishedの値を更新してスタックすることを防ぐ
class WeaponViewModel: ObservableObject {
    @Published var selectedWeapon: Weapon?
    @Published var weapons: [Weapon] = []
    @Published var isLoadingWeapons: Bool = false
    
    func fetchAllWeapons() async {
        isLoadingWeapons = true
        defer { isLoadingWeapons = false } // 抜ける時の処理
        
        do {
            let snapshot = try await db.collection("weapons")
                .order(by: "hoyolabId", descending: true)
                .getDocuments()
            print("complete fetching all weapons")
            
            self.weapons = snapshot.documents.compactMap { doc in
                try? doc.data(as: Weapon.self)
            }
        } catch {
            print("error fetching all weapons: \(error)")
        }
    }
    
    func createWeapon(weapon: Weapon, completion: @escaping () -> Void, errorHandling: @escaping () -> Void) {
        do {
            try db.collection("weapons").document(weapon.enName).setData(from: weapon) { error in
                if error != nil {
                    errorHandling()
                    return
                } else {
                    completion()
                }
            }
        } catch {
            errorHandling()
        }
    }
    
    func updateWeapon() {}
    
    func fetchWeaponAPI(id: String, completion: @escaping (String, String, String, String, String, String, String, String, String) -> Void, errorHandling: @escaping () -> Void) {
        guard let url = URL(string: "https://sg-wiki-api-static.hoyolab.com/hoyowiki/genshin/wapi/entry_page?entry_page_id=\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // ヘッダー追加
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("ja,en-US;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.addValue("ja-jp", forHTTPHeaderField: "x-rpc-language")
        request.addValue("gzip, deflate, br, zstd", forHTTPHeaderField: "Accept-Encoding")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching weapon: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid weapon response")
                return
            }
            
            if let data = data {
                do {
                    // JSONとしてパース
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    // 取得したい値
                    var jpName = ""
                    var enName = ""
                    var type = ""
                    var effect = ""
                    var attack = ""
                    var subStatusName = ""
                    var subStatusValue = ""
                    var rarity = ""
                    var imgUrl = ""
                    
                    if let dict = json as? [String: Any],
                       let data = dict["data"] as? [String: Any],
                       let page = data["page"] as? [String: Any],
                       let iconURL = page["icon_url"] as? String,
                       let filterValues = page["filter_values"] as? [String: Any],
                       
                        let weaponRarity = filterValues["weapon_rarity"] as? [String: Any],
                       let rarityValues = weaponRarity["values"] as? [String],
                       
                        let modules = page["modules"] as? [[String: Any]] {
                        
                        for module in modules {
                            if let components = module["components"] as? [[String: Any]] {
                                for component in components {
                                    if let componentDataString = component["data"] as? String,
                                       let componentData = componentDataString.data(using: .utf8),
                                       let componentJson = try? JSONSerialization.jsonObject(with: componentData, options: []) as? [String: Any],
                                       let list = componentJson["list"] as? [[String: Any]] {
                                        
                                        for item in list {
                                            
                                            if let key = item["key"] as? String {
                                                // nameの抽出
                                                if key.contains("和名 / 英名"),
                                                   let valueArray = item["value"] as? [String] {
                                                    // HTMLタグが入ってる場合は取り除く
                                                    let name = valueArray.first?
                                                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                                                    // nameの処理
                                                    let parts = name.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                                                    jpName = parts[0]
                                                    enName = parts[1]
                                                }
                                                else if key.contains("入手方法") {}
                                                else if key.contains("種類"), let valueArray = item["value"] as? [String] {
                                                    type = valueArray.first?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                                                }
                                                else if key.contains("サブステータス"), let valueArray = item["value"] as? [String] {
                                                    subStatusName = valueArray.first?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                                                }
                                                else if key.contains("七聖召喚のカード") {}
                                                else if key.contains("実装バージョン") {}
                                                // 武器効果の抽出
                                                else
                                                if let valueArray = item["value"] as? [String] {
                                                    effect = valueArray.first ?? ""
                                                    effect = effect.replacingOccurrences(
                                                        of: "<p.*?>|</p>",
                                                        with: "",
                                                        options: .regularExpression)
                                                    effect = effect.replacingOccurrences(
                                                        of: "<span.*?>|</span>",
                                                        with: "",
                                                        options: .regularExpression)
                                                }
                                            }
                                        }
                                        
                                        // Lv.90のcombatListを探す
                                        if let lv90 = list.first(where: { $0["key"] as? String == "Lv.90" }),
                                           let combatList = lv90["combatList"] as? [[String: Any]] {
                                            // 最後のcombatListのvaluesを取得
                                            if let values = combatList.last?["values"] as? [String] {
                                                if values.count >= 3 {
                                                    attack = values[0]
                                                    subStatusValue = values[2]
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if rarityValues.count >= 1 {
                            rarity = TrimString(str: rarityValues[0], start: 1, end: 1)
                        }
                        imgUrl = iconURL
                    }
                    
                    // viewに値を渡す
                    completion(jpName, enName, rarity, type, attack, subStatusName, subStatusValue, effect, imgUrl)
                } catch {
                    errorHandling()
                }
            }
        }
        task.resume()
    }
}
