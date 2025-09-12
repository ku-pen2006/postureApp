import SwiftUI
import Charts

struct ReflectionView: View {
    @ObservedObject var history: PostureHistory
    @State private var selectedDate = Date()   // 選択中の日付
    @State private var data: [(type: PostureType, duration: TimeInterval)] = []

    var body: some View {
        VStack {
            Text("日ごとの姿勢を振り返ろう")
                .font(.headline)
                .padding(.top)

            // 日付切り替え（1週間分くらい）
            Picker("日付", selection: $selectedDate) {
                ForEach(last7Days(), id: \.self) { date in
                    Text(formatDate(date))
                        .tag(date)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if data.isEmpty {
                Text("この日のデータはありません")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart(data, id: \.type) { item in
                    SectorMark(
                        angle: .value("時間", item.duration),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("姿勢", item.type.rawValue))
                }
                .frame(height: 300)
                .padding()

                List(data, id: \.type) { item in
                    HStack {
                        Text(item.type.rawValue)
                        Spacer()
                        Text(formatDuration(item.duration))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear { updateData(for: selectedDate) }
        .onChange(of: selectedDate) { newDate in
            updateData(for: newDate)
        }
    }

    // データ更新
    private func updateData(for date: Date) {
        let summary = history.summaryForDayPieChart(date: date)
        data = summary.map { ($0.key, $0.value) }
            .sorted { $0.duration > $1.duration }
    }

    // 過去7日間を返す
    private func last7Days() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    // 日付を「M/d」形式で表示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 1 {
            return "<1分"
        } else {
            return "\(minutes)分"
        }
    }
}
// MARK: - 任意の日の悪い姿勢サマリー（円グラフ用）
extension PostureHistory {
    func summaryForDayPieChart(date: Date) -> [PostureType: TimeInterval] {
        let calendar = Calendar.current
        let dayRecords = records.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
        let badRecords = dayRecords.filter { $0.postureType != .good }
        
        return Dictionary(grouping: badRecords, by: { $0.postureType })
            .mapValues { records in
                records.reduce(0) { $0 + $1.duration }
            }
    }
}
