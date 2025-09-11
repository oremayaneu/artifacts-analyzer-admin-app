//
//  UserViewModel.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/08/19.
//

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
