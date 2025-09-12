import SwiftUI
import AppKit

// MARK: - メインの警告ビュー
struct CharacterWarningView: View {
    let warningType: String // 警告タイプ (例: "badPosture", "sedentary")

    // 悪い姿勢の時のメッセージリスト (方言入り)
    private let badPostureMessages: [String] = [
        "姿勢が悪いわ！しゃんとしぃ！(大阪)",
        "せなかがまがっとるで！しゃんとしいや！(奈良)",
        "姿勢悪いよぉ！すっと背筋伸ばしぃよ！(和歌山)",
        "姿勢悪いけんね！しゃんとしときんさい！(広島)",
        "姿勢悪かばい！しゃんとせんと！(福岡)"
    ]
    
    // 長時間座りっぱなしの時のメッセージリスト (方言入り)
    private let sedentaryMessages: [String] = [
        "もう1時間座りっぱなしやで！ちょっと立って休憩せなあかんで！(関西弁)",
        "もう1時間座ってるで！ちょっと立ってやすみや！(奈良)",
        "もう1時間も座ってるやん！ちょっと立って休憩しぃよ！(和歌山)",
        "もう1時間座っとるけぇ！ちょっと立って休憩せんといけん！(広島)",
        "もう1時間座っとうばい！ちょっと立ってから休憩しんしゃい！(福岡)"
    ]
    
    // 表示するカワウソの画像アセット名リスト
    private let meerkatImages = ["MeerkatCloseMouse", "MeerkatOpMouse", "MeerkatUpArm"]
    
    // 画像を1秒ごとに切り替えるタイマー
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var currentImageIndex = 0 // 現在表示する画像のインデックス
    @State private var isVisible = false      // ビューの表示状態
    @State private var currentMessage: String = "" // ランダムに選択されたメッセージ

    var body: some View {
        VStack {
            Spacer()
            
            HStack(alignment: .bottom) {
                // カワウソの画像（タイマーで切り替わる）
                Image(meerkatImages[currentImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: (NSScreen.main?.frame.width ?? 1024) * 0.3)
                    .padding(.leading, 20)
                    .onReceive(timer) { _ in
                        currentImageIndex = (currentImageIndex + 1) % meerkatImages.count
                    }
                    
                // 吹き出しビュー
                BubbleView(message: currentMessage) // currentMessageを表示
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 20)
                    .offset(x: -150, y: -100) // 吹き出しの位置調整
            }
            .padding(.bottom, 80)
        }
        .opacity(isVisible ? 1.0 : 0.0) // 透明度アニメーション
        .onAppear {
                    // 警告タイプに応じてメッセージをランダムに選択
                    if warningType == "badPosture" {
                        currentMessage = badPostureMessages.randomElement() ?? "姿勢に気ぃつけてや！"
                    } else if warningType == "sedentary" {
                        currentMessage = sedentaryMessages.randomElement() ?? "ちょっと休憩しいや！"
                    }
                    
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                        isVisible = true
                    }
                }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea() // 画面全体に広げる
    }
}

// MARK: - 吹き出し部分のビュー
struct BubbleView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding(15)
            .background(Color(red: 0.95, green: 0.85, blue: 0.95).opacity(0.95)) // 背景色
            .cornerRadius(30) // 角丸
            .shadow(radius: 7) // 影
            .overlay(
                Triangle() // 吹き出しのしっぽ
                    .fill(Color(red: 0.95, green: 0.85, blue: 0.95).opacity(0.95))
                    .frame(width: 25, height: 20)
                    .rotationEffect(.degrees(242)) // しっぽの角度
                    .offset(x: -11, y: 1)          // しっぽの位置調整
                , alignment: .bottomLeading
            )
            .font(.body)
            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1)) // 文字色
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
