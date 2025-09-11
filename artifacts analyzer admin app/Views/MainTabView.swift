//
//  MainTabView.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/08/28.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CharacterHomeView()
                .tabItem {
                    Label("キャラ", systemImage: "person")
                }
            
            WeaponHomeView()
                .tabItem {
                    Label("武器", systemImage: "person.badge.shield.checkmark.fill")
                }
            
            ArtifactHomeView()
                .tabItem {
                    Label("聖遺物", systemImage: "person.badge.clock")
                }
        }
    }
}
