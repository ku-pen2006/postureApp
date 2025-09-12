import Foundation
import Combine

/// 姿勢の種類を定義
enum PostureType: String, CaseIterable {
    case good = "良い姿勢"
    case faceTilt = "顔の傾き"
    case forwardLean = "前傾"
    case shoulderTilt = "肩の傾き"
    case sideLean = "横ズレ"
}

/// 1つの姿勢の記録を表すデータ構造
struct PostureRecord: Identifiable {
    let id = UUID()
    var postureType: PostureType
    var startTime: Date
    var endTime: Date

    /// 継続時間（秒）
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}


/// 姿勢の履歴データを管理するクラス
class PostureHistory: ObservableObject {
    @Published private(set) var records: [PostureRecord] = []
    
    // MARK: - 警告機能
    /// 悪い姿勢の種類を通知するためのPublisher
    let badPostureWarningPublisher = PassthroughSubject<PostureType, Never>()
    
    /// 座りっぱなし警告機能
    let sedentaryWarningPublisher = PassthroughSubject<Void, Never>()
    private var goodPostureStartTime: Date? = nil
    private var isWarningShownForCurrentSession = false
    private let sedentaryTimeThreshold: TimeInterval = 3600 // 👈 デバッグ用に10秒に変更

    /// 新しい姿勢データを記録する
    func add(_ posture: PostureType) {
        DispatchQueue.main.async {
            // 記録ロジック
            if var lastRecord = self.records.last {
                if lastRecord.postureType == posture {
                    self.records[self.records.count - 1].endTime = Date()
                } else {
                    let newRecord = PostureRecord(postureType: posture, startTime: Date(), endTime: Date())
                    self.records.append(newRecord)
                }
            } else {
                let newRecord = PostureRecord(postureType: posture, startTime: Date(), endTime: Date())
                self.records.append(newRecord)
            }
            
            // 悪い姿勢だったら通知を送る
            if posture != .good {
                print("⚠️ 悪い姿勢を検知しました: \(posture.rawValue)")
                self.badPostureWarningPublisher.send(posture)
            }
            
            // 座りっぱなし判定
            self.checkSedentaryState(currentPosture: posture)
        }
    }
    
    /// 座りっぱなしの状態をチェックして、必要なら警告を発行する
    private func checkSedentaryState(currentPosture: PostureType) {
        if currentPosture == .good {
            if goodPostureStartTime == nil {
                goodPostureStartTime = Date()
                isWarningShownForCurrentSession = false
            }
            
            if let startTime = goodPostureStartTime, !isWarningShownForCurrentSession {
                if Date().timeIntervalSince(startTime) > sedentaryTimeThreshold {
                    print("🔔 1時間座りっぱなしです！休憩しましょう。")
                    sedentaryWarningPublisher.send()
                    isWarningShownForCurrentSession = true
                }
            }
        } else {
            goodPostureStartTime = nil
        }
    }
}
// MARK: - グラフ用のデータ集計機能
extension PostureHistory {
    /// 円グラフ用：今日の悪い姿勢の種類と、それぞれの合計時間（秒）を返す
    func summaryForTodayPieChart() -> [PostureType: TimeInterval] {
        let todayRecords = records.filter { Calendar.current.isDateInToday($0.startTime) }
        let badPostureRecords = todayRecords.filter { $0.postureType != .good }
        return Dictionary(grouping: badPostureRecords, by: { $0.postureType })
            .mapValues { records in
                records.reduce(0) { $0 + $1.duration }
            }
    }

    /// 棒グラフで使うデータ形式
    struct DailySummary: Identifiable {
        let id = UUID()
        let date: Date
        let totalBadDuration: TimeInterval
    }

    /// 棒グラフ用：過去数日間の、日ごとの悪い姿勢の合計時間（秒）を返す
    func summaryForLast(days: Int) -> [DailySummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var summaries: [DailySummary] = []

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let recordsForDate = records.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            let totalBadDuration = recordsForDate
                .filter { $0.postureType != .good }
                .reduce(0) { $0 + $1.duration }
            summaries.append(DailySummary(date: date, totalBadDuration: totalBadDuration))
        }
        return summaries.sorted { $0.date < $1.date }
    }
}
////
////  PostureHistory.swift
////  postureApp
////
////  Created by 🐣 on 2025/09/11.
////
//
//import Foundation
//
//import Foundation
//
//// 1つの姿勢の記録を表す構造体
//struct PostureRecord: Identifiable {
//    let id = UUID()
//    var postureType: PostureType
//    var startTime: Date
//    var endTime: Date
//
//    // 継続時間を計算するプロパティ（秒単位）
//    var duration: TimeInterval {
//        endTime.timeIntervalSince(startTime)
//    }
//}
//
//enum PostureType: String, CaseIterable {
//    case good = "良い姿勢"
//    case faceTilt = "顔の傾き"
//    case forwardLean = "前傾"
//    case shoulderTilt = "肩の傾き"
//    case sideLean = "横ズレ"
//}
//
//class PostureHistory: ObservableObject {
//    // 記録の配列を[PostureType]から[PostureRecord]に変更
//    @Published private(set) var records: [PostureRecord] = []
//    @Published private(set) var lastUpdated: Date = Date()
//
//    // addメソッドを全面的に書き換え
//    func add(_ posture: PostureType) {
//        DispatchQueue.main.async {
//            // 最後の記録を取得
//            if var lastRecord = self.records.last {
//                // 最後の記録と同じ姿勢が続いている場合
//                if lastRecord.postureType == posture {
//                    // 終了時刻だけを更新
//                    self.records[self.records.count - 1].endTime = Date()
//                } else {
//                    // 姿勢が変わった場合、新しい記録を開始
//                    let newRecord = PostureRecord(postureType: posture, startTime: Date(), endTime: Date())
//                    self.records.append(newRecord)
//                }
//            } else {
//                // これが最初の記録の場合
//                let newRecord = PostureRecord(postureType: posture, startTime: Date(), endTime: Date())
//                self.records.append(newRecord)
//            }
//            self.lastUpdated = Date()
//        }
//    }
//    
//    // summaryメソッドは使わなくなるので削除します
//}
//// PostureHistoryを拡張して、集計機能を追加
//extension PostureHistory {
//
//    /// 1. 円グラフ用：今日の悪い姿勢の種類と、それぞれの合計時間（秒）を返す
//    func summaryForTodayPieChart() -> [PostureType: TimeInterval] {
//        // 今日の日付の記録に絞り込む
//        let todayRecords = records.filter { Calendar.current.isDateInToday($0.startTime) }
//
//        // 「良い姿勢」を除外
//        let badPostureRecords = todayRecords.filter { $0.postureType != .good }
//
//        // 姿勢の種類ごとにグループ化し、それぞれの合計時間を計算
//        return Dictionary(grouping: badPostureRecords, by: { $0.postureType })
//            .mapValues { records in
//                records.reduce(0) { $0 + $1.duration }
//            }
//    }
//
//    /// 棒グラフで使うデータ形式
//    struct DailySummary: Identifiable {
//        let id = UUID()
//        let date: Date
//        let totalBadDuration: TimeInterval
//    }
//
//    /// 2. 棒グラフ用：過去数日間の、日ごとの悪い姿勢の合計時間（秒）を返す
//    func summaryForLast(days: Int) -> [DailySummary] {
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//        var summaries: [DailySummary] = []
//
//        for i in 0..<days {
//            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
//
//            // その日付の記録に絞り込む
//            let recordsForDate = records.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
//
//            // その日の悪い姿勢の合計時間を計算
//            let totalBadDuration = recordsForDate
//                .filter { $0.postureType != .good }
//                .reduce(0) { $0 + $1.duration }
//
//            summaries.append(DailySummary(date: date, totalBadDuration: totalBadDuration))
//        }
//
//        return summaries.sorted { $0.date < $1.date } // 日付順に並べ替えて返す
//    }
//}

