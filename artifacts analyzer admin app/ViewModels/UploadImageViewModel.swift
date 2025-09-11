//
//  UploadImageViewModel.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/06.
//

import Foundation
import FirebaseStorage

@MainActor
class UploadImageViewModel: ObservableObject {
    func uploadImage(data: Data, imgType: String, imgName: String) async -> URL? {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("\(imgType)Img/\(imgName).png")
        
        do {
            let _ = try await imageRef.putDataAsync(data)
            let url = try await imageRef.downloadURL()
            
            return url
        } catch {
            print("画像アップロード失敗: \(error)")
        }
        return nil
    }
}
