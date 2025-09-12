import SwiftUI
struct ContentView: View {
    var history: PostureHistory
    var cameraManager: CameraManager

    var body: some View {
        TabView {
            HomeView()
                            .tabItem {
                                Label("ホーム", systemImage: "house.fill")
                            }
            SummaryView(history: history)
            
                .tabItem {
                    Label("今日", systemImage: "doc.text.image")
                }

            GraphView(history: history)
                .tabItem {
                    Label("グラフ", systemImage: "chart.bar.xaxis")
                }

            ReflectionView(history: history)   // 👈 新規追加
                .tabItem {
                    Label("振り返り", systemImage: "clock.arrow.circlepath")
                }
            StretchView()
                   .tabItem {
                       Label("ストレッチ", systemImage: "figure.cooldown")
                   }
        }

        }
    }

