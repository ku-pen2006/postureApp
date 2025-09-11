import SwiftUI

struct KawausoView: View {
    var body: some View {
            VStack {
                // カワウソの画像
                Image("kawauso")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.brown)
                    .padding()

                // メッセージ
                Text("姿勢が悪くなっていますよ！")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)
            }
            .frame(width: 400, height: 400) // ウィンドウのサイズ
    }
}
