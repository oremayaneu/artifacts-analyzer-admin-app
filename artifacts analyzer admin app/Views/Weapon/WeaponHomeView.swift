import SwiftUI

// 配列パスとして使う列挙型
enum WeaponPath {
    case addWeaponPath, displayWeaponsPath, displayWeaponDetailPath
}

struct WeaponHomeView: View {
    // enumをデータ型に指定した配列パス
    @State private var navigationPath: [WeaponPath] = []
    
    @StateObject private var weaponViewModel = WeaponViewModel()
    @StateObject private var safariOpener = SafariOpener()
    
    var body: some View {
        NavigationStack (path: $navigationPath){
            List {
                HomeListChild(
                    leftIconName: "icloud.and.arrow.up",
                    title: "武器を追加する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.addWeaponPath)}
                )
                
                HomeListChild(
                    leftIconName: "icloud.and.arrow.down",
                    title: "追加した武器を確認する",
                    rightIconName: "chevron.right",
                    onTap: {navigationPath.append(.displayWeaponsPath)}
                )
                
                HomeListChild(
                    leftIconName: "list.bullet",
                    title: "hoyolabで武器図鑑を見る",
                    rightIconName: "arrow.up.right.square",
                    onTap: {
                        safariOpener.open(urlString: "https://wiki.hoyolab.com/m/genshin/aggregate/4?lang=ja-jp")
                    }
                )
            }
            .navigationTitle("武器 ホーム")
            .navigationDestination(for: WeaponPath.self) { value in
                switch value {
                case .addWeaponPath:
                    AddWeaponView(path: $navigationPath, weaponViewModel: weaponViewModel)
                case .displayWeaponsPath:
                    DisplayWeaponsView(path: $navigationPath, weaponViewModel: weaponViewModel)
                case .displayWeaponDetailPath:
                    DisplayWeaponDetailView(path: $navigationPath, weaponViewModel: weaponViewModel)
                }
            }
        }}
}
