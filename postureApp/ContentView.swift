import SwiftUI

struct ContentView: View {
    // 💡 Postalgia → PostureHistory に修正
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager
    
    @State private var showingSedentaryAlert = false

    init() {
        // 💡 Postalgia → PostureHistory に修正
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

