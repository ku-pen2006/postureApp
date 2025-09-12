import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var history: PostureHistory
    @ObservedObject var cameraManager: CameraManager
    
    // 👇 この一行を追加して、ウィンドウを開く機能を使えるようにします
//    @Environment(\.openWindow) private var openWindow
    
    @State private var showingSedentaryAlert = false

    var body: some View {
        // 👇 VStackで全体を囲み、ボタンを上に追加します
//        VStack {
//            // 👇 テスト用のボタン
//            Button("テスト警告を表示 (手動)") {
//                print("テストボタンが押されました！ウィンドウを開きます。")
//                let message = "これは手動でのテスト表示です"
//                openWindow(id: "character-warning", value: message)
//            }
//            .font(.headline)
//            .padding()
//            .background(Color.indigo)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//            .padding(.top)

            // 元々のTabView
            TabView {
                SummaryView(history: history)
                    .tabItem {
                        Label("今日", systemImage: "doc.text.image")
                    }

                GraphView(history: history)
                    .tabItem {
                        Label("グラフ", systemImage: "chart.bar.xaxis")
                    }
            }
            .onReceive(history.sedentaryWarningPublisher) { _ in
                self.showingSedentaryAlert = true
            }
            .alert("休憩の時間です！", isPresented: $showingSedentaryAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("1時間以上座り続けています。少し立ち上がって休憩しましょう！")
            }
        }
    }
