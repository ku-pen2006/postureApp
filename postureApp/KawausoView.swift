import SwiftUI

struct KawausoView: View {
    // 3枚の画像（Assets.xcassets に登録しておく）
    let images = ["kawauso1", "kawauso2", "kawauso3"]

    @State private var currentIndex = 0
    // 1秒ごとに切り替え
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Image(images[currentIndex])
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()

            Text("姿勢が悪くなっていますよ！")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 16)
        }
        .onReceive(timer) { _ in
            // 次の画像へ（最後までいったら最初に戻る）
            currentIndex = (currentIndex + 1) % images.count
        }
        .frame(width: 400, height: 400)
    }
}
