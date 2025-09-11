import SwiftUI

struct BlockingIndicator: View {
    var body: some View {
        ZStack {
            // overlay が画面全体を覆うので下のUIは触れなくなる
            Color.black.opacity(0.35)
                .ignoresSafeArea()                 // 画面端まで覆う
                .transition(.opacity)

            VStack(spacing: 16) {
                ProgressView()                   // スピナー
                    .scaleEffect(1.4, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle())
                Text("読み込み中…")
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)     // iOSのぼかしマテリアル（いい感じ）
            .cornerRadius(12)
            .shadow(radius: 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            // ここでタップを吸収するために空の onTapGesture を付ける
            .onTapGesture { /* 押しても何もしない（タップを吸収）*/ }
            .zIndex(1) // 確実に上に出す
        }
    }
}
