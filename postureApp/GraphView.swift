//
//  GraphView.swift
//  postureApp
//
//  Created by 🐣 on 2025/09/11.
//
import SwiftUI
import Charts // Chartsフレームワークをインポート

struct GraphView: View {
    @ObservedObject var history: PostureHistory

    var body: some View {
        VStack {
            Text("過去7日間の悪い姿勢の時間（分）")
                .font(.headline)
                .padding()

            // データを取得
            let dailySummaries = history.summaryForLast(days: 7)

            if dailySummaries.isEmpty {
                Text("履歴データがありません")
                    .padding()
            } else {
                Chart(dailySummaries) { summary in
                                   // 💡【変更点】秒数を60で割り、分に変換
                                   // 0秒より大きいが1分未満の場合でも、最低限の高さが表示されるように
                                   // max(summary.totalBadDuration / 60, 0.1) のような微調整も可能
                                   let minutes = summary.totalBadDuration / 60.0
                                   
                                   BarMark(
                                       x: .value("日付", summary.date, unit: .day),
                                       y: .value("合計時間(分)", minutes)
                    )
                }
                .chartYAxis {
                                    // --- 👇 ここから修正 ---
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisTick()
                                        // 💡 IntではなくDoubleで値を取得し、表示をフォーマットする
                                        if let doubleValue = value.as(Double.self) {
                                            AxisValueLabel(String(format: "%.0f分", doubleValue))
                                        }
                                    }
                }
                .padding()
            }
        
        }
    }
}
