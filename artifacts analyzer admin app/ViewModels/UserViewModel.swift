import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var userName: String = ""
    
    init() {
        loadUser()
    }
    
    private func loadUser() {
        // APIから取得する想定
        let user = User(id: 0, name: "田中太郎")
        self.userName = user.name
    }
}
