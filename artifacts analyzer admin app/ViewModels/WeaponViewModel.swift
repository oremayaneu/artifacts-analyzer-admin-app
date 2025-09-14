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
                    self.selectedWeapon = weapon
                    completion()
                }
            }
        } catch {
            errorHandling()
        }
    }
    
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
                    
                    let res = try JSONDecoder().decode(HoyowikiResponse.self, from: data)
                    
                    if res.message != "OK" {
                        errorHandling()
                        return
                    }
                    
                    if  res.data.page.modules.count >= 2,
                        // 基本情報（名前・効果）の取得
                        let basicJson = res.data.page.modules[0].components[0].data.data(using: .utf8),
                        let basicObj = try JSONSerialization.jsonObject(with: basicJson, options: []) as? [String: Any],
                        let basicList = basicObj["list"] as? [[String: Any]],
                        // parameterの取得
                        let parameterJson = res.data.page.modules[1].components[0].data.data(using: .utf8),
                        let parameterObj = try JSONSerialization.jsonObject(with: parameterJson, options: []) as? [String: Any],
                        let parameterList = parameterObj["list"] as? [[String: Any]],
                        // filter_valuesの取得
                        let filterValues = res.data.page.filter_values
                    {
                        // json化し、structにセット
                        let newBasicJson = try JSONSerialization.data(withJSONObject: basicList, options: [])
                        let decodedBasicJson = try JSONDecoder().decode([WeaponBasicInfo].self, from: newBasicJson)
                        
                        let newParameterJson = try JSONSerialization.data(withJSONObject: parameterList, options: [])
                        let decodedParameterJson = try JSONDecoder().decode([WeaponAscension].self, from: newParameterJson)
                        
                        if let nameEntry = decodedBasicJson.first(where: { $0.key == "和名 / 英名" }),
                           let effectEntry = decodedBasicJson.first(where: { !["和名 / 英名", "入手方法", "種類", "サブステータス", "七聖召喚のカード", "実装バージョン"].contains($0.key) }),
                           let lv90 = decodedParameterJson.first(where: { $0.key == "Lv.90" })
                        {
                            let nameStr = nameEntry.value.first?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                            let parts = nameStr.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                            let jpName = parts[0]
                            let enName = parts[1]
                            
                            let effect = effectEntry.value.first?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                            
                            let parameters = lv90.combatList[1].values
                            let attack = parameters[0]
                            let subStatusValue = parameters[2]
                            
                            let type = filterValues.weapon_type?.values.first ?? ""
                            let subStatusName = filterValues.weapon_property?.values.first ?? ""
                            var rarity = filterValues.weapon_rarity?.values.first ?? ""
                            rarity = TrimString(str: rarity, start: 1, end: 1)
                            
                            // アイコンの取得
                            let imgUrl = res.data.page.icon_url
                            
                            // viewに渡す
                            completion(jpName, enName, rarity, type, attack, subStatusName, subStatusValue, effect, imgUrl)
                        }
                    } else {
                        print("データ整形でエラー")
                        errorHandling()
                    }
                } catch {
                    errorHandling()
                }
            }
        }
        task.resume()
    }
}
