
// ===============================
// 檔案 3: SharedData.swift (兩個 Target 都要加)
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins
import RSBarcodes_Swift
import AVFoundation

// MARK: - Barcode Generator
class BarcodeGenerator {
    static func generateCode128(from text: String) -> UIImage? {
        // 如果文字為空，返回 nil
        guard !text.isEmpty else { return nil }
        
        // 嘗試生成 Code39（符合台灣財政部規格）
        let generator = RSUnifiedCodeGenerator.shared
        let targetSize = CGSize(width: 360, height: 130)
        
        if let code39Image = generator.generateCode(
            text,
            machineReadableCodeObjectType: AVMetadataObject.ObjectType.code39.rawValue,
            targetSize: targetSize
        ) {
            print("Generated Code39 barcode size: \(code39Image.size)")
            return code39Image
        }
        
        return nil
    }
}

// MARK: - Shared User Defaults for App Groups
class SharedUserDefaults {
    private static let appGroupID = "group.idlevillager.InvoiceBarcode"
    private static let carrierNumberKey = "carrierNumber"
    private static let updatedDateKey = "updatedDate"
    
    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupID)
    }
    
    static func saveCarrierNumber(_ number: String) {
        sharedDefaults?.set(number, forKey: carrierNumberKey)
        sharedDefaults?.set(Date(), forKey: updatedDateKey)
        sharedDefaults?.synchronize()
    }
    
    static func getCarrierNumber() -> String {
        return sharedDefaults?.string(forKey: carrierNumberKey) ?? ""
    }
    
    static func getLastUpdated() -> Date? {
        return sharedDefaults?.object(forKey: updatedDateKey) as? Date
    }
}
