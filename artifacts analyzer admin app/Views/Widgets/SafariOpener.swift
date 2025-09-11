//
//  ViewController.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/07.
//

import SwiftUI
import SafariServices

// Safariを起動する処理をまとめたクラス
class SafariOpener: NSObject, ObservableObject {
    func open(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // 現在表示中のビューコントローラーを取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let safariVC = SFSafariViewController(url: url)
            rootVC.present(safariVC, animated: true)
        }
    }
}
