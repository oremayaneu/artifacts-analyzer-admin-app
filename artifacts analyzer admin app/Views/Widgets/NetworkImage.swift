//
//  NetworkImage.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/02.
//

import SwiftUI

struct NetworkImage: View {
    @State var image: UIImage?
    let url: URL
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView("Loading...")
                                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear {
            let url = url
            downloadImageAsync(url: url) { image in
                self.image = image
            }
        }
    }
}

func downloadImageAsync(url: URL, completion: @escaping (UIImage?) -> Void) {
    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: url) { (data, _, _) in
        var image: UIImage?
        if let imageData = data {
            image = UIImage(data: imageData)
        }
        DispatchQueue.main.async {
            completion(image)
        }
    }
    task.resume()
}
