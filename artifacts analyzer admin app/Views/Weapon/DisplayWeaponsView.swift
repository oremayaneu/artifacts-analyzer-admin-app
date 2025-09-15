import SwiftUI

struct DisplayWeaponsView: View {
    @Binding var path: [WeaponPath]
    @ObservedObject var weaponViewModel: WeaponViewModel  // ← 外から注入 // 新しいインスタンスを生成すると、他画面と独立してしまうため
    
    var body: some View {
        Group {
            if (!weaponViewModel.isLoadingWeapons && weaponViewModel.weapons.count > 0){
                List(weaponViewModel.weapons) { weapon in
                    Button(weapon.jpName) {
                        Task {
                            weaponViewModel.selectedWeapon = weapon
                            path.append(.displayWeaponDetailPath)
                        }
                    }.foregroundColor(.primary)
                }
            } else if weaponViewModel.isLoadingWeapons {
                BlockingIndicator() // 全画面ブロッキングインジケータ
            } else {
                Text("No weapon")
            }
        }
        .navigationTitle("武器一覧")
        .onAppear {
            Task {
                await weaponViewModel.fetchAllWeapons()
            }
        }
    }
}
