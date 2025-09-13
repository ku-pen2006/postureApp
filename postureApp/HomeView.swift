//
//  HomeView.swift
//  postureApp
//
//  Created by 🐣 on 2025/09/13.
//

import SwiftUI

struct HomeView: View {
    @State private var message = "こんにちは！今日も姿勢に気をつけよう！"
    
    // ランダムで切り替えるセリフ
    private let messages = [
        "背筋を伸ばしてリフレッシュ！",
        "ちょっと肩を回してみない？",
        "お水を飲んでひと休みしよう！",
        "いい姿勢、かっこいいよ！"
    ]
    
    // キャラ画像（複数フレームでアニメっぽく）
    private let meerkatImages = ["MeerkatCloseMouse", "MeerkatOpMouse", "MeerkatUpArm"]
    @State private var currentImageIndex = 0
    
    // タイマーで表情を切り替える
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .topTrailing) {
                // キャラクター
                Image(meerkatImages[currentImageIndex])
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)
                    .onReceive(timer) { _ in
                        currentImageIndex = (currentImageIndex + 1) % meerkatImages.count
                    }
                
                // 吹き出し
                BubbleView(message: message)
                    .frame(maxWidth: 260)
                    .padding(.trailing, 40)
                    .padding(.top, 10)
            }
            
            Spacer()
            
            Button("おしゃべりしてもらう") {
                withAnimation {
                    message = messages.randomElement() ?? message
                }
            }
            .padding()
        }
    }
}
