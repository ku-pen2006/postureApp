//
//  AppDelegate.swift
//  postureApp
//
//  Created by 🐣 on 2025/09/12.
//

import SwiftUI

// アプリケーションの動作を管理するためのクラス
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // アプリの最後のウィンドウが閉じられたときに、アプリを終了させるかどうかを決めるメソッド
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // falseを返すことで、ウィンドウを閉じてもアプリは終了しなくなる
        return false
    }
}
