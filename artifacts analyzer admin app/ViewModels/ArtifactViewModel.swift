import Foundation
import Combine
import FirebaseFirestore
import SwiftSoup
import WebKit

@MainActor // バックグラウンドでpublishedの値を更新してスタックすることを防ぐ
class ArtifactViewModel: ObservableObject {
    //    @Published var selectedWeapon: Weapon?
    //    @Published var weapons: [Weapon] = []
    //    @Published var isLoadingWeapons: Bool = false
    
    //    func fetchAllWeapons() async {
    //        isLoadingWeapons = true
    //        defer { isLoadingWeapons = false } // 抜ける時の処理
    //
    //        do {
    //            let snapshot = try await db.collection("weapons")
    //                .order(by: "hoyolabId", descending: true)
    //                .getDocuments()
    //            print("complete fetching all weapons")
    //
    //            self.weapons = snapshot.documents.compactMap { doc in
    //                try? doc.data(as: Weapon.self)
    //            }
    //        } catch {
    //            print("error fetching all weapons: \(error)")
    //        }
    //    }
    
    //    func createWeapon(weapon: Weapon, completion: @escaping () -> Void, errorHandling: @escaping () -> Void) {
    //        do {
    //            try db.collection("weapons").document(weapon.enName).setData(from: weapon) { error in
    //                if error != nil {
    //                    errorHandling()
    //                    return
    //                } else {
    //                    completion()
    //                }
    //            }
    //        } catch {
    //            errorHandling()
    //        }
    //    }
    
    //    func updateWeapon() {}
    
    func fetchArtifactAPI(id: String, completion: @escaping ([String], [String], [String], [String]) -> Void, errorHandling: @escaping () -> Void) {
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
                print("Error fetching artifact: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid artifact response")
                return
            }
            
            if let data = data {
                do {
                    let res = try JSONDecoder().decode(ArtifactResponse.self, from: data)
                    
                    if res.message != "OK" {
                        errorHandling()
                        return
                    }
                    
                    if  // nameの取得
                        let nameJson = res.data.page.modules[0].components[0].data.data(using: .utf8),
                        let nameElement = try JSONSerialization.jsonObject(with: nameJson, options: []) as? [String: Any],
                        let list = nameElement["list"] as? [[String: Any]],
                        let valueArray = list[0]["value"] as? [String],
                        // effectの取得
                        let effectJson = res.data.page.modules[0].components[1].data.data(using: .utf8),
                        let effectElement = try JSONSerialization.jsonObject(with: effectJson, options: []) as? [String: Any],
                        let twoSet = effectElement["two_set_effect"] as? String,
                        let fourSet = effectElement["four_set_effect"] as? String,
                        // 各パーツの取得
                        let json = res.data.page.modules[1].components[0].data.data(using: .utf8)
                    {
                        // HTMLタグが入ってる場合は取り除く
                        let name = valueArray.first?
                            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                        let names = name.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                        if names.count != 2 {
                            errorHandling()
                            return
                        }
                        
                        let twoSetEffect = twoSet.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        let fourSetEffect = fourSet.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        
                        let artifacts = try JSONDecoder().decode(ArtifactList.self, from: json)
                        
                        // viewに渡す
                        completion(
                            names,
                            [twoSetEffect, fourSetEffect],
                            [artifacts.flower_of_life.title,
                             artifacts.plume_of_death.title,
                             artifacts.sands_of_eon.title,
                             artifacts.goblet_of_eonothem.title,
                             artifacts.circlet_of_logos.title
                            ],
                            [artifacts.flower_of_life.icon_url,
                             artifacts.plume_of_death.icon_url,
                             artifacts.sands_of_eon.icon_url,
                             artifacts.goblet_of_eonothem.icon_url,
                             artifacts.circlet_of_logos.icon_url
                            ])
                    } else {
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

