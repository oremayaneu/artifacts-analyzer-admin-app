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
