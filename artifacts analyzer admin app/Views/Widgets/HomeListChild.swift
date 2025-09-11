//
//  HomeListChild.swift
//  artifacts analyzer admin app
//
//  Created by 釆山怜央 on 2025/09/06.
//

import SwiftUI

struct HomeListChild: View {
    let leftIconName: String
    let title: String
    let rightIconName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action:{onTap()}) {
            HStack{
                Image(systemName: leftIconName)
                Text(title)
                Spacer()
                Image(systemName: rightIconName)
            }
        }.foregroundColor(.primary)
    }
}
