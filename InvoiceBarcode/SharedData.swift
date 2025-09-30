// ===============================
// File: SharedData.swift (Both Targets)
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins
import RSBarcodes_Swift
import AVFoundation

// MARK: - Barcode Generator
class BarcodeGenerator {
    // Generate barcode with default black color
    static func generateCode128(from text: String) -> UIImage? {
        return generateCode128(from: text, color: .black)
    }
    
    // Generate barcode with custom color
    static func generateCode128(from text: String, color: UIColor) -> UIImage? {
        guard !text.isEmpty else { return nil }
        
        let generator = RSUnifiedCodeGenerator.shared
        let targetSize = CGSize(width: 360, height: 130)
        
        // Generate Code39 barcode
        guard let originalImage = generator.generateCode(
            text,
            machineReadableCodeObjectType: AVMetadataObject.ObjectType.code39.rawValue,
            targetSize: targetSize
        ) else {
            return nil
        }
        
        // If color is black, return original image
        if color == .black {
            print("Generated Code39 barcode size: \(originalImage.size)")
            return originalImage
        }
        
        // Convert barcode to specified color
        return changeImageColor(originalImage, to: color)
    }
    
    // Helper function to change barcode color
    private static func changeImageColor(_ image: UIImage, to color: UIColor) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Create color space and context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Draw original image
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelBuffer = context.data else { return nil }
        
        let pixels = pixelBuffer.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        // Get target color components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let targetR = UInt8(red * 255)
        let targetG = UInt8(green * 255)
        let targetB = UInt8(blue * 255)
        
        // Replace black pixels with target color
        for i in 0..<(width * height) {
            let offset = i * 4
            let r = pixels[offset]
            let g = pixels[offset + 1]
            let b = pixels[offset + 2]
            
            // If pixel is dark (barcode line), replace with target color
            if r < 128 && g < 128 && b < 128 {
                pixels[offset] = targetR
                pixels[offset + 1] = targetG
                pixels[offset + 2] = targetB
            }
        }
        
        // Create new image from modified pixel data
        guard let newCGImage = context.makeImage() else { return nil }
        
        return UIImage(cgImage: newCGImage)
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
