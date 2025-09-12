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
                    .offset(x: -150, y: -100)
            }
            .padding(.bottom, 80)
        }
        // 👇 透明度のアニメーションを有効に戻します
        .opacity(isVisible ? 1.0 : 0.0)
        // 👇 表示されたときにアニメーションを開始する処理を有効に戻します
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
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
            .background(Color(red: 0.95, green: 0.85, blue: 0.95).opacity(0.95))
            .cornerRadius(30)
            .shadow(radius: 7)
            .overlay(
                Triangle()
                    .fill(Color(red: 0.95, green: 0.85, blue: 0.95).opacity(0.95))
                    .frame(width: 25, height: 20)
                    .rotationEffect(.degrees(250))
                    .offset(x: -12, y: 1)
                , alignment: .bottomLeading
            )
            .font(.body)
            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
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

