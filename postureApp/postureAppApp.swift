import SwiftUI

@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    // クールダウン用状態変数
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
                    // クールダウン中かチェック
                    guard !isWarningOnCooldown else { return }
                    
                    dismissWindow(id: "character-warning")
                    NSApp.activate(ignoringOtherApps: true)
                    
                    // 警告タイプを渡す
                    openWindow(id: "character-warning", value: "badPosture")
                    
                    startCooldown()
                }
                .onReceive(history.sedentaryWarningPublisher) { _ in
                    // クールダウン中かチェック
                    guard !isWarningOnCooldown else { return }
                    
                    dismissWindow(id: "character-warning")
                    NSApp.activate(ignoringOtherApps: true)
                    
                    // 警告タイプを渡す
                    openWindow(id: "character-warning", value: "sedentary")
                    
                    startCooldown()
                }
        } label: {
            Image(systemName: "figure.stand")
        }
        
        WindowGroup(id: "dashboard") {
            ContentView(history: history, cameraManager: cameraManager)
        }
        
        // WindowGroupの修正
        WindowGroup(id: "character-warning", for: String.self) { $warningType in
            CharacterWarningView(warningType: warningType ?? "")
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
        
    // クールダウンを管理する関数
    private func startCooldown() {
        isWarningOnCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            isWarningOnCooldown = false
        }
    }
}
