import SwiftUI

@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    // MARK: - NEW: クールダウン用の状態変数を追加
    @State private var isWarningOnCooldown = false

    init() {
        let historyObject = PostureHistory()
        _history = StateObject(wrappedValue: historyObject)
        _cameraManager = StateObject(wrappedValue: CameraManager(history: historyObject))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .onReceive(history.badPostureWarningPublisher) { posture in
                    // NEW: クールダウン中かチェック
                    guard !isWarningOnCooldown else { return }

                    dismissWindow(id: "character-warning")
                    NSApp.activate(ignoringOtherApps: true)
                    
                    let message = "「\(posture.rawValue)」になっています。\n姿勢を直しましょう！"
                    openWindow(id: "character-warning", value: message)
                    
                    // NEW: クールダウンを開始
                    startCooldown()
                }
                .onReceive(history.sedentaryWarningPublisher) { _ in
                    // NEW: クールダウン中かチェック
                    guard !isWarningOnCooldown else { return }

                    dismissWindow(id: "character-warning")
                    NSApp.activate(ignoringOtherApps: true)
                    
                    let message = "1時間以上座り続けています！\n少し立ち上がって休憩しましょう！"
                    openWindow(id: "character-warning", value: message)
                    
                    // NEW: クールダウンを開始
                    startCooldown()
                }
        } label: {
            Image(systemName: "figure.stand")
        }

        WindowGroup(id: "dashboard") {
            ContentView(history: history, cameraManager: cameraManager)
        }

        WindowGroup(id: "character-warning", for: String.self) { $message in
            // 👇 悪い姿勢の時の画像名を "kawauso" (またはお好きな名前) に修正しました
            let imageName = (message ?? "").contains("座り続け") ? "character_warning" : "MeerkatCloseMouse"
            CharacterWarningView(message: message ?? "姿勢に気をつけて！", imageName: imageName)
                .background(.clear)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                        dismissWindow(id: "character-warning")
                    }
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
    
    // MARK: - NEW: クールダウンを管理する関数を追加
    private func startCooldown() {
        isWarningOnCooldown = true
        // 8秒後にクールダウンを解除する
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            isWarningOnCooldown = false
        }
    }
}
