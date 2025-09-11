import SwiftUI

struct ContentView: View {
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager
    
    // 座りっぱなしアラート用
    @State private var showingSedentaryAlert = false
    
    // 悪い姿勢アラート用のState変数
    @State private var showingBadPostureAlert = false
    @State private var detectedPosture: PostureType?

    init() {
        let historyObject = PostureHistory()
        _history = StateObject(wrappedValue: historyObject)
        _cameraManager = StateObject(wrappedValue: CameraManager(history: historyObject))
    }

    var body: some View {
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
        // 座りっぱなしアラート
        .onReceive(history.sedentaryWarningPublisher) { _ in
            self.showingSedentaryAlert = true
        }
        .alert("休憩の時間です！", isPresented: $showingSedentaryAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("1時間以上座り続けています。少し立ち上がって休憩しましょう！")
        }
        
        // 新しく追加した悪い姿勢の通知を受け取る
        .onReceive(history.badPostureWarningPublisher) { posture in
            self.detectedPosture = posture
            self.showingBadPostureAlert = true
        }
        // 悪い姿勢の種類を表示するアラート
        .alert("姿勢が崩れています！", isPresented: $showingBadPostureAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let posture = detectedPosture {
                Text("「\(posture.rawValue)」になっています。姿勢を直しましょう。")
            }
        }
    }
}
