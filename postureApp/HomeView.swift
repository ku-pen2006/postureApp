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
        "背筋ピンと伸ばしたら、めっちゃスッキリするで！",
            "ちょっと肩回したら、気持ちええやろ？",
            "水飲んでリフレッシュせなあかんで！",
            "その姿勢、ほんまかっこええで！",
            "深呼吸してみぃ、楽になるで〜",
            "立って伸びしたら血の巡りよぅなるで！",
            "目ぇ休めるんも大事やで！",
            "ちょっと背中動かしてみぃ、スッキリするわ！",
          

            // 和歌山弁
            "背ぇ伸ばしたらスッと楽になるで！",
            "肩ぐるぐる回してみぃよ、だいぶ違うで。",
            "ちょっと水でも飲んで休みや〜",
            "ええ姿勢しとるとほんま見栄えするで！",
            "深呼吸して気分変えよか〜",
            "腰伸ばしてリセットしよら！",
      

            // 広島弁
            "背筋ピンと伸ばしたら、ええ感じじゃけぇ！",
            "肩ぐるぐる回してみんさい、すっきりするよ。",
            "水飲んで休憩せんといけんよ〜",
            "姿勢ようしとると、かっこええけぇ！",
            "深呼吸して気持ち切り替えんさい。",
            "腰伸ばしたら、身体が喜ぶけぇ！",
            "目ぇ休めんと疲れるけんね。",
            "背中動かして、ちぃとリセットしんさい。",
         

            // 博多弁
            "背筋伸ばしたら、シャキッとすっばい！",
            "肩ぐるっと回したら気持ちよかよ〜",
            "水ば飲んでひと息つきんしゃい！",
            "姿勢がよかと、ほんとカッコよかよ〜",
            "深呼吸したら気分変わるばい。",
            "腰ば伸ばしてスッキリせんね！",
            "目ん休ませんと、疲れ溜まるけんね。",
            "背中グイッと伸ばしたら元気でるばい！",
            "休憩も大事な仕事たい。",
            "姿勢の振り返りしてみたら〜？",
            "ストレッチしない？"
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
