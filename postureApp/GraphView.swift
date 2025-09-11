import SwiftUI
import Charts

struct GraphView: View {
    var history: PostureHistory
    @State private var dailySummaries: [PostureHistory.DailySummary] = []

    var body: some View {
        VStack {
            Text("過去7日間の悪い姿勢の時間")
                .font(.headline)
                .padding()

            if dailySummaries.filter({ $0.totalBadDuration > 0 }).isEmpty {
                Text("履歴データがありません")
                    .padding()
            } else {
                Chart(dailySummaries) { summary in
                    let hours = summary.totalBadDuration / 3600.0
                    
                    BarMark(
                        x: .value("日付", summary.date, unit: .day),
                        y: .value("合計時間(時間)", hours)
                    )
                    // --- 👇 ここから追加 ---
                    // 💡 2. 棒グラフの上に注釈（Annotation）を追加
                    .annotation(position: .top, alignment: .center) {
                        // 0秒より大きい場合のみ時間を表示
                        if summary.totalBadDuration > 0 {
                            Text(formatDurationForAnnotation(summary.totalBadDuration))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    // --- 👆 ここまで追加 ---
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .chartYAxis {
                    // --- 👇 ここから修正 ---
                    // 💡 1. 目盛りを1時間ごと（stride by 1.0）に設定
                    AxisMarks(values: .stride(by: 1.0)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.0f時間", doubleValue))
                        }
                    }
                    // --- 👆 ここまで修正 ---
                }
                .padding()
            }
        }
        .onAppear(perform: loadData)
    }

    private func loadData() {
        self.dailySummaries = history.summaryForLast(days: 7)
    }

    // --- 👇 ここから追加 ---
    /// グラフの注釈用に、秒数を「〇h 〇m」形式の文字列に変換する
    private func formatDurationForAnnotation(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated // "h", "m", "s" のような短い単位
        formatter.allowedUnits = [.hour, .minute] // 時間と分のみ表示
        
        // 1分未満の場合は "< 1m" と表示
        if duration > 0 && duration < 60 {
            return "< 1m"
        }
        
        return formatter.string(from: duration) ?? ""
    }
    // --- 👆 ここまで追加 ---
}
