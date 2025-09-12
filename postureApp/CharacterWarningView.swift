import SwiftUI
import AppKit

// MARK: - メインの警告ビュー
struct CharacterWarningView: View {
    let message: String
    let imageName: String
    
    // 👇 アニメーション用の変数を有効に戻します
    @State private var isVisible = false

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom) {
                // 👇 imageName変数を使うように戻して、警告の種類で画像が変わるようにします
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: (NSScreen.main?.frame.width ?? 1024) * 0.3)
                    .padding(.leading, 20)
            
                BubbleView(message: message)
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 20)
                    .offset(y: -100)
            }
            .padding(.bottom, 80)
        }
        // 👇 透明度のアニメーションを有効に戻します
        .opacity(isVisible ? 1.0 : 0.0)
        // 👇 表示されたときにアニメーションを開始する処理を有効に戻します
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                isVisible = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

// MARK: - 吹き出し部分のビュー
struct BubbleView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding(15)
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 7)
            .overlay(
                Triangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 25, height: 20)
                    .rotationEffect(.degrees(90))
                    .offset(x: -15, y: 5)
                , alignment: .bottomLeading
            )
            .font(.body)
            .foregroundColor(.black)
    }
}

// MARK: - 吹き出しのしっぽ（三角形）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
