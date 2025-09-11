import SwiftUI

struct SummaryView: View {
    var history: PostureHistory
    @State private var todaySummary: [PostureType: TimeInterval] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の振り返り")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            if todaySummary.isEmpty {
                VStack {
                    Spacer()
                    Text("今日の悪い姿勢の記録はありませんでした。")
                    Text("素晴らしい一日です！🎉")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("特に長かった悪い姿勢:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                let sortedPostures = todaySummary.keys.sorted {
                    todaySummary[$0, default: 0] > todaySummary[$1, default: 0]
                }
                
                ForEach(sortedPostures, id: \.self) { posture in
                    HStack {
                        Text(posture.rawValue)
                        Spacer()
                        Text(formatDurationToMinutes(todaySummary[posture, default: 0]))
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .onAppear(perform: loadData)
    }
    
    private func loadData() {
        self.todaySummary = history.summaryForTodayPieChart()
    }

    private func formatDurationToMinutes(_ duration: TimeInterval) -> String {
        if duration <= 0 { return "0分" }
        let minutes = ceil(duration / 60.0)
        return String(format: "%.0f分", minutes)
    }
}
//import SwiftUI
//
//struct SummaryView: View {
//    @ObservedObject var history: PostureHistory
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) { // 左揃えにして、間隔を調整
//            Text("今日の振り返り")
//                .font(.title)
//                .fontWeight(.bold)
//                .padding(.bottom, 8)
//
//            // 新しいメソッドで今日のデータを取得
//            let todaySummary = history.summaryForTodayPieChart()
//
//            if todaySummary.isEmpty {
//                VStack {
//                    Spacer()
//                    Text("今日の悪い姿勢の記録はありませんでした。")
//                    Text("素晴らしい一日です！🎉")
//                    Spacer()
//                }
//                .frame(maxWidth: .infinity)
//            } else {
//                Text("特に長かった悪い姿勢:")
//                    .font(.headline)
//                    .padding(.bottom, 5)
//                
//                // 時間が長い順にソートしてキーを取得
//                let sortedPostures = todaySummary.keys.sorted {
//                    todaySummary[$0, default: 0] > todaySummary[$1, default: 0]
//                }
//                
//                // 各項目を表示
//                ForEach(sortedPostures, id: \.self) { posture in
//                    HStack {
//                        Text(posture.rawValue)
//                        Spacer()
//                        Text(formatDurationToMinutes(todaySummary[posture, default: 0]))
//                                                 .fontWeight(.semibold)
//                    }
//                    .padding(.vertical, 4)
//                }
//            }
//        }
//        .padding()
//    }
//
//    private func formatDurationToMinutes(_ duration: TimeInterval) -> String {
//           if duration <= 0 {
//               return "0分"
//           }
//           // 秒数を60で割り、小数点以下を切り上げる
//           let minutes = ceil(duration / 60.0)
//           return String(format: "%.0f分", minutes)
//       }
//    }

