import SwiftUI

@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    init() {
        let historyObject = PostureHistory()
        _history = StateObject(wrappedValue: historyObject)
        _cameraManager = StateObject(wrappedValue: CameraManager(history: historyObject))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .onReceive(history.badPostureWarningPublisher) { posture in
                    NSApp.activate(ignoringOtherApps: true)
                    let message = "「\(posture.rawValue)」になっています。\n姿勢を直しましょう！"
                    openWindow(id: "character-warning", value: message)
                }
                .onReceive(history.sedentaryWarningPublisher) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                    let message = "1時間以上座り続けています！\n少し立ち上がって休憩しましょう！"
                    openWindow(id: "character-warning", value: message)
                }
        } label: {
            Image(systemName: "figure.stand")
        }

        WindowGroup(id: "dashboard") {
            ContentView(history: history, cameraManager: cameraManager)
        }

        WindowGroup(id: "character-warning", for: String.self) { $message in
            let imageName = (message ?? "").contains("座り続け") ? "character_warning" : "kawauso"
            CharacterWarningView(message: message ?? "姿勢に気をつけて！", imageName: imageName)
                .background(.clear)
                .onAppear {
                    // 👇 ここが DispatchTime.now() になっています
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                        dismissWindow(id: "character-warning")
                    }
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}
