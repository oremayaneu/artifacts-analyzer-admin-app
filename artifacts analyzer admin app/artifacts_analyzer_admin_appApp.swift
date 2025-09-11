//
//  artifacts_analyzer_admin_appApp.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/07/29.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct artifacts_analyzer_admin_appApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
            // 全体のデフォルトtintを指定
                .tint(Color("AppTheme"))
        }
    }
}
