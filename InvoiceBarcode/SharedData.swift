// ===============================
// File: SharedData.swift (Both Targets)
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins
import RSBarcodes_Swift
import AVFoundation

// MARK: - Barcode Color Scheme
struct BarcodeColorScheme {
    let name: String
    let foregroundColor: UIColor
    let backgroundColor: UIColor
}

// MARK: - Barcode Generator
class BarcodeGenerator {
    // Predefined color schemes for barcode scanning compatibility
    static let colorSchemes: [BarcodeColorScheme] = [
        BarcodeColorScheme(
            name: "經典黑白",
            foregroundColor: .black,
            backgroundColor: .white
        ),
        BarcodeColorScheme(
            name: "深藍配色",
            foregroundColor: UIColor(red: 0, green: 0.2, blue: 0.4, alpha: 1),
            backgroundColor: UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
        ),
        BarcodeColorScheme(
            name: "深綠配色",
            foregroundColor: UIColor(red: 0, green: 0.3, blue: 0.2, alpha: 1),
            backgroundColor: UIColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 1)
        ),
        BarcodeColorScheme(
            name: "深紅配色",
            foregroundColor: UIColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1),
            backgroundColor: UIColor(red: 1.0, green: 0.92, blue: 0.92, alpha: 1)
        )
    ]
    
    // Generate barcode with default black/white color scheme
    static func generateCode128(from text: String) -> UIImage? {
        return generateCode128(from: text, scheme: colorSchemes[0])
    }
    
    // Generate barcode with custom color scheme
    static func generateCode128(from text: String, scheme: BarcodeColorScheme) -> UIImage? {
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
        
        // Apply color scheme
        return applyColorScheme(to: originalImage, scheme: scheme)
    }
    
    // Helper function to apply color scheme to barcode
    private static func applyColorScheme(to image: UIImage, scheme: BarcodeColorScheme) -> UIImage? {
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
        
        // Get color components
        var fgR: CGFloat = 0, fgG: CGFloat = 0, fgB: CGFloat = 0, fgA: CGFloat = 0
        var bgR: CGFloat = 0, bgG: CGFloat = 0, bgB: CGFloat = 0, bgA: CGFloat = 0
        
        scheme.foregroundColor.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        scheme.backgroundColor.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        
        let foregroundR = UInt8(fgR * 255)
        let foregroundG = UInt8(fgG * 255)
        let foregroundB = UInt8(fgB * 255)
        
        let backgroundR = UInt8(bgR * 255)
        let backgroundG = UInt8(bgG * 255)
        let backgroundB = UInt8(bgB * 255)
        
        // Replace colors
        for i in 0..<(width * height) {
            let offset = i * 4
            let r = pixels[offset]
            let g = pixels[offset + 1]
            let b = pixels[offset + 2]
            
            // If pixel is dark (barcode line), replace with foreground color
            // Otherwise replace with background color
            if r < 128 && g < 128 && b < 128 {
                pixels[offset] = foregroundR
                pixels[offset + 1] = foregroundG
                pixels[offset + 2] = foregroundB
            } else {
                pixels[offset] = backgroundR
                pixels[offset + 1] = backgroundG
                pixels[offset + 2] = backgroundB
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
