import Foundation
import Combine

enum PostureType: String, CaseIterable {
    case good = "良い姿勢"
    case faceTilt = "顔の傾き"
    case forwardLean = "前傾"
    case shoulderTilt = "肩の傾き"
    case sideLean = "横ズレ"
}

struct PostureRecord: Identifiable {
    let id = UUID()
    var postureType: PostureType
    var startTime: Date
    var endTime: Date

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

class PostureHistory: ObservableObject {
    @Published private(set) var records: [PostureRecord] = []

    let badPostureWarningPublisher = PassthroughSubject<PostureType, Never>()
    let sedentaryWarningPublisher = PassthroughSubject<Void, Never>()

    private var sessionStartTime: Date? = nil
    private var isWarningShownForCurrentSession = false
    private let sedentaryTimeThreshold: TimeInterval = 10 // 1時間

    func add(_ posture: PostureType) {
        DispatchQueue.main.async {
            if var last = self.records.last {
                if last.postureType == posture {
                    self.records[self.records.count - 1].endTime = Date()
                } else {
                    self.records.append(PostureRecord(postureType: posture,
                                                      startTime: Date(),
                                                      endTime: Date()))
                }
            } else {
                self.records.append(PostureRecord(postureType: posture,
                                                  startTime: Date(),
                                                  endTime: Date()))
            }

            if posture != .good {
                print("⚠️ 悪い姿勢: \(posture.rawValue)")
                self.badPostureWarningPublisher.send(posture)
            }

            self.checkSedentaryState()
        }
    }

    private func checkSedentaryState() {
        if sessionStartTime == nil {
            sessionStartTime = Date()
            isWarningShownForCurrentSession = false
        }

        if let start = sessionStartTime, !isWarningShownForCurrentSession {
            if Date().timeIntervalSince(start) > sedentaryTimeThreshold {
                print("🔔 1時間座りっぱなし！休憩しましょう")
                sedentaryWarningPublisher.send()
                isWarningShownForCurrentSession = true
            }
        }
    }

    func resetSession() {
        sessionStartTime = nil
        isWarningShownForCurrentSession = false
    }
}
// MARK: - 今日の悪い姿勢サマリー（円グラフ用）
extension PostureHistory {
    func summaryForTodayPieChart() -> [PostureType: TimeInterval] {
        let todayRecords = records.filter { Calendar.current.isDateInToday($0.startTime) }
        let badRecords = todayRecords.filter { $0.postureType != .good }
        
        return Dictionary(grouping: badRecords, by: { $0.postureType })
            .mapValues { records in
                records.reduce(0) { $0 + $1.duration }
            }
    }
}
// MARK: - グラフ用データ集計（棒グラフ用）
extension PostureHistory {
    /// 棒グラフで使う1日の要約
    struct DailySummary: Identifiable {
        let id = UUID()
        let date: Date
        let totalBadDuration: TimeInterval
    }

    /// 過去n日間の日ごとの悪い姿勢の合計時間
    func summaryForLast(days: Int) -> [DailySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DailySummary] = []

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            let recordsForDate = records.filter {
                calendar.isDate($0.startTime, inSameDayAs: date)
            }

            let totalBadDuration = recordsForDate
                .filter { $0.postureType != .good }
                .reduce(0) { $0 + $1.duration }

            summaries.append(DailySummary(date: date, totalBadDuration: totalBadDuration))
        }

        return summaries.sorted { $0.date < $1.date }
    }
}
