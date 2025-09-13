// ===============================
// 專案結構說明：
// ===============================
// 1. 主 App Target：
//    - App.swift
//    - ContentView.swift
//    - SharedData.swift
//
// 2. Widget Extension Target：
//    - CarrierWidget.swift
//    - SharedData.swift (同一個檔案，加到兩個 target)
//
// 3. App Groups：
//    - group.idlevillager.InvoiceBarcode
//
// ===============================
// 檔案 1: App.swift (主 App Target)
// ===============================
import SwiftUI

@main
struct InvoiceCarrierApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
