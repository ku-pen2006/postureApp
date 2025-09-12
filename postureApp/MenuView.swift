import SwiftUI

struct MenuView: View {
    // 👇 自分で @Environment を使って openWindow を取得しているか確認！
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading) {
            Button("ダッシュボードを開く") {
                // 👇 openWindow(id: "...") の形で呼び出しているか確認！
                openWindow(id: "dashboard")
                NSApp.unhide(nil)
            }
            Divider()
            Button("終了") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}
