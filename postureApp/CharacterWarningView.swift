import SwiftUI
import AppKit

// MARK: - 警告ビュー
struct CharacterWarningView: View {
    let warningType: String // "badPosture" / "sedentary" / "breakTime"

    private let badPostureMessages = [
        "姿勢が悪いわ！しゃんとしぃ！",
        "せなかがまがっとるで！しゃんとしいや！",
        "姿勢悪いよぉ！すっと背筋伸ばしぃよ！",
        "姿勢悪いけんね！しゃんとしときんさい！",
        "姿勢悪かばい！しゃんとせんと！"
    ]
    
    private let sedentaryMessages = [
        "もう1時間座りっぱなしやで！ちょっと立って休憩せなあかんで！",
        "もう1時間座ってるで！ちょっと立ってやすみや！",
        "もう1時間も座ってるやん！ちょっと立って休憩しぃよ！",
        "もう1時間座っとるけぇ！ちょっと立って休憩せんといけん！",
        "もう1時間座っとうばい！ちょっと立ってから休憩しんしゃい！",
        "ストレッチしんしゃい",
        "ストレッチせんにゃあ"
    ]

    private let breakTimeMessages = [
        "そろそろ休憩しよか？☕️ ",
        "ちょっと休みなさいや！",
        "一息いれよか？",
        "休憩せんといけんよ！",
        "ちょっと休憩したらよかろうもん！"
    ]
    
    private let meerkatImages = ["MeerkatCloseMouse", "MeerkatOpMouse", "MeerkatUpArm"]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var currentImageIndex = 0
    @State private var isVisible = false
    @State private var currentMessage: String = ""

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Image(meerkatImages[currentImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(width: (NSScreen.main?.frame.width ?? 1024) * 0.3)
                    .padding(.leading, 20)
                    .onReceive(timer) { _ in
                        currentImageIndex = (currentImageIndex + 1) % meerkatImages.count
                    }
                
                BubbleView(message: currentMessage)
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 20)
                    .offset(x: -150, y: -100)
            }
            .padding(.bottom, 80)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            switch warningType {
            case "badPosture":
                currentMessage = badPostureMessages.randomElement() ?? "姿勢に気ぃつけてや！"
            case "sedentary":
                currentMessage = sedentaryMessages.randomElement() ?? "ちょっと休憩しいや！"
            case "breakTime":
                currentMessage = breakTimeMessages.randomElement() ?? "休憩しよ！"
            default:
                currentMessage = "🙂"
            }
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                isVisible = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

// MARK: - 吹き出しビュー
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
                    .rotationEffect(.degrees(242))
                    .offset(x: -11, y: 1),
                alignment: .bottomLeading
            )
            .font(.body)
            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
    }
}

// MARK: - 吹き出しのしっぽ
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
