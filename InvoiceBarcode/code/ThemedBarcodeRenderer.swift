// ===============================
// File: ThemedBarcodeRenderer.swift (Both Targets)
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Themed Barcode Rendering Pipeline
class ThemedBarcodeRenderer {
    
    // MARK: - Main rendering pipeline
    static func generateThemedBarcode(carrierNumber: String, theme: BackgroundTheme, size: CGSize = CGSize(width: 300, height: 100)) -> UIImage? {
        guard !carrierNumber.isEmpty else { return nil }
        
        // Step 1: Generate transparent base barcode
        guard let baseBarcode = generateTransparentBarcode(from: carrierNumber, targetSize: size) else {
            return nil
        }
        
        // Step 2: Composite with background image and barcode
        return compositeThemedBarcode(baseBarcode: baseBarcode, theme: theme, canvasSize: size)
    }
    
    // MARK: - Step 1: Generate transparent barcode
    private static func generateTransparentBarcode(from text: String, targetSize: CGSize) -> UIImage? {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(text.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Calculate barcode area (centered with padding)
        let barcodeHeight = targetSize.height * 0.6
        let barcodeWidth = targetSize.width * 0.8
        let barcodeSize = CGSize(width: barcodeWidth, height: barcodeHeight)
        
        // Scale to barcode area size
        let scaleX = barcodeSize.width / outputImage.extent.width
        let scaleY = barcodeSize.height / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage with proper alpha handling
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        // Create transparent background version
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
            
            // Calculate centered position for barcode
            let barcodeRect = CGRect(
                x: (targetSize.width - barcodeSize.width) / 2,
                y: (targetSize.height - barcodeSize.height) / 2,
                width: barcodeSize.width,
                height: barcodeSize.height
            )
            
            // Set barcode color
            let barcodeColor = getThemeBarcodeColor(theme: BackgroundTheme(id: "", displayName: "", preview: ""))
            barcodeColor.setFill()
            
            // Draw barcode with color replacement
            cgContext.setBlendMode(.normal)
            cgContext.draw(cgImage, in: barcodeRect)
            
            // Apply color to barcode
            cgContext.setBlendMode(.sourceIn)
            cgContext.fill(CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Step 2: Composite with background and barcode
    private static func compositeThemedBarcode(baseBarcode: UIImage, theme: BackgroundTheme, canvasSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: canvasSize)
            
            // Step 1: Draw background (image or solid color)
            if let backgroundImage = loadBackgroundImage(theme: theme) {
                // Scale background image to fit canvas
                backgroundImage.draw(in: rect)
            } else {
                // Fallback to solid background color
                let backgroundColor = getThemeBackgroundColor(theme: theme)
                backgroundColor.setFill()
                rendererContext.fill(rect)
            }
            
            // Step 2: Overlay transparent barcode
            baseBarcode.draw(in: rect, blendMode: .normal, alpha: 1.0)
        }
    }
    
    // MARK: - Background image loading
    private static func loadBackgroundImage(theme: BackgroundTheme) -> UIImage? {
        // Add safety checks
        print("Attempting to load background image for theme: \(theme.id)")
        
        // Try local image first (for development/testing)
        if let imageName = theme.backgroundImageName {
            print("Trying local image: \(imageName)")
            if let localImage = UIImage(named: imageName) {
                print("Local image loaded successfully")
                return localImage
            } else {
                print("Local image not found: \(imageName)")
            }
        }
        
        // Try remote image (production) - disabled for now to avoid crashes
        if let imageURL = theme.backgroundImageURL {
            print("Remote image URL found but skipping: \(imageURL)")
            // Skip remote loading for now to avoid potential crashes
            // return loadRemoteImage(from: imageURL)
        }
        
        print("No background image loaded, using fallback")
        return nil
    }
    
    private static func loadRemoteImage(from urlString: String) -> UIImage? {
        // TODO: Implement proper async loading with caching
        // Disabled for now to prevent crashes
        return nil
    }
    
    // MARK: - Theme color helpers (Fixed)
    private static func getThemeBackgroundColor(theme: BackgroundTheme) -> UIColor {
        if let gradientColors = theme.gradientColors, let firstColor = gradientColors.first {
            return hexToUIColor(firstColor)
        }
        return UIColor.systemYellow.withAlphaComponent(0.3) // Default fallback
    }
    
    private static func getThemeBarcodeBackgroundColor(theme: BackgroundTheme) -> UIColor {
        if let backgroundHex = theme.barcodeBackground {
            return hexToUIColor(backgroundHex)
        }
        return UIColor.white
    }
    
    private static func getThemeBarcodeColor(theme: BackgroundTheme) -> UIColor {
        if let colorHex = theme.barcodeColor {
            return hexToUIColor(colorHex)
        }
        return UIColor.black
    }
    
    // MARK: - Hex to UIColor conversion
    private static func hexToUIColor(_ hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }

        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
