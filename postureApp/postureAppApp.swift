import SwiftUI
import Combine

// MARK: - 休憩リマインダー管理
class BreakReminderManager: ObservableObject {
    private var timer: AnyCancellable?
    private let reminderTimes: [String] = ["9:08", "12:15", "14:45", "16:30"]
    private let calendar = Calendar.current

    let breakReminderPublisher = PassthroughSubject<Void, Never>()

    init() {
        startTimer()
    }

    private func startTimer() {
        // 1分ごとに現在時刻をチェック
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.checkReminderTime(date: date)
            }
    }

    private func checkReminderTime(date: Date) {
        // 平日のみ (2=月曜, 6=金曜)
        let weekday = calendar.component(.weekday, from: date)
        guard (2...6).contains(weekday) else { return }

        // HH:mm 形式にフォーマット
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: date)

        if reminderTimes.contains(currentTime) {
            breakReminderPublisher.send()
        }
    }
}

// MARK: - アプリ本体
@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    // クールダウン用
    @State private var isWarningOnCooldown = false
    @State private var currentWarningType: String? = nil

    // 警告の待ち行列
    @State private var warningQueue: [String] = []

    init() {
        let historyObject = PostureHistory()
        _history = StateObject(wrappedValue: historyObject)
        _cameraManager = StateObject(wrappedValue: CameraManager(history: historyObject))
        
        // アプリ起動時にリマインダーをセット
        historyObject.scheduleBreakReminders()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .onReceive(history.badPostureWarningPublisher) { _ in
                    enqueueWarning("badPosture")
                }
                .onReceive(history.sedentaryWarningPublisher) { _ in
                    enqueueWarning("sedentary")
                }
                .onReceive(history.breakTimeWarningPublisher) { _ in
                    enqueueWarning("breakTime")
                }
        } label: {
            Image(systemName: "figure.stand")
        }
        
        WindowGroup(id: "dashboard") {
            ContentView(history: history, cameraManager: cameraManager)
        }
        
        WindowGroup(id: "character-warning", for: String.self) { $warningType in
            CharacterWarningView(warningType: warningType ?? "")
                .background(.clear)
                .onAppear {
                    // 3秒後に閉じて次の警告へ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismissWindow(id: "character-warning")
                        currentWarningType = nil
                        showNextWarning() // ← 次を表示
                    }
                }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }

    // 優先度を返す
    private func priority(for type: String) -> Int {
        switch type {
        case "sedentary", "breakTime": return 2
        case "badPosture": return 1
        default: return 0
        }
    }

    // キューに追加
    private func enqueueWarning(_ type: String) {
        warningQueue.append(type)
        showNextWarning()
    }

    // 次の警告を表示
    private func showNextWarning() {
        guard !isWarningOnCooldown, currentWarningType == nil else { return }
        guard !warningQueue.isEmpty else { return }

        // キューを優先度順に並べ替えて、先頭を表示
        warningQueue.sort { priority(for: $0) > priority(for: $1) }
        let next = warningQueue.removeFirst()

        dismissWindow(id: "character-warning")
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "character-warning", value: next)

        currentWarningType = next
        startCooldown()
    }

    // クールダウン管理
    private func startCooldown() {
        isWarningOnCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            isWarningOnCooldown = false
            showNextWarning() // クールダウン解除後に次を表示
        }
    }
}
