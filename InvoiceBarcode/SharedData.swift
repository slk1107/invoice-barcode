
// ===============================
// 檔案 3: SharedData.swift (兩個 Target 都要加)
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Barcode Generator
class BarcodeGenerator {
    static func generateCode128(from text: String) -> UIImage? {
        // 如果文字為空，返回 nil
        
        guard !text.isEmpty else { return nil }
        
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(text.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale up the barcode for better quality
        let scaleX = 360.0 / outputImage.extent.width
        let scaleY = 130.0 / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        print("Original barcode size: \(outputImage.extent)")
        print("Final barcode size: \(scaledImage.extent)")

        return UIImage(cgImage: cgImage)
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
