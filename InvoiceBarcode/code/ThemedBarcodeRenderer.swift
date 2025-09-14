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
        
        // For debugging
        print("Generating themed barcode for: \(carrierNumber)")
        print("Theme: \(theme.displayName)")
        
        // Step 1: Generate colored barcode using CIFilter
        guard let coloredBarcode = generateColoredBarcode(
            from: carrierNumber,
            barcodeColor: getThemeBarcodeColor(theme: theme),
            backgroundColor: getThemeBarcodeBackgroundColor(theme: theme)
        ) else {
            print("Failed to generate colored barcode")
            return nil
        }
        
        print("Colored barcode generated successfully")
        
        // Step 2: Composite with theme elements
        let result = compositeThemedBarcode(
            coloredBarcode: coloredBarcode,
            theme: theme,
            canvasSize: size
        )
        
        print("Themed barcode composite result: \(result != nil ? "success" : "failed")")
        
        return result
    }
    
    // MARK: - Generate colored barcode using custom renderer
    private static func generateColoredBarcode(from text: String, barcodeColor: UIColor, backgroundColor: UIColor) -> UIImage? {
        // Use custom Code128Renderer for direct color support
        return Code128Renderer.generateColoredBarcode(
            text: text,
            barColor: barcodeColor,
            backgroundColor: backgroundColor,
            size: CGSize(width: 400, height: 120) // Higher res for quality
        )
    }
    
    // MARK: - Composite everything together (3 layers)
    private static func compositeThemedBarcode(coloredBarcode: UIImage, theme: BackgroundTheme, canvasSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { rendererContext in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let cgContext = rendererContext.cgContext
            
            // Layer 1: Draw solid background color
            let backgroundColor = getThemeBackgroundColor(theme: theme)
            backgroundColor.setFill()
            cgContext.fill(rect)
            
            // Layer 2: Draw background image with alpha (if exists)
            if let backgroundImage = loadBackgroundImage(theme: theme) {
                // Draw image maintaining its alpha channel
                backgroundImage.draw(in: rect)
            }
            
            // Layer 3: Draw colored barcode
            // Calculate barcode size and position
            let barcodeHeight = canvasSize.height * 0.6
            let barcodeAspectRatio: CGFloat = 3.0 // Typical barcode width:height ratio
            let barcodeWidth = min(canvasSize.width * 0.8, barcodeHeight * barcodeAspectRatio)
            
            let barcodeRect = CGRect(
                x: (canvasSize.width - barcodeWidth) / 2,
                y: (canvasSize.height - barcodeHeight) / 2,
                width: barcodeWidth,
                height: barcodeHeight
            )
            
            // Scale the colored barcode to fit
            let scaledBarcode = scaleImage(coloredBarcode, to: barcodeRect.size)
            scaledBarcode?.draw(in: barcodeRect)
        }
    }
    
    // MARK: - Helper: Scale image to target size
    private static func scaleImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Color helpers
    private static func getThemeBackgroundColor(theme: BackgroundTheme) -> UIColor {
        // Use first gradient color as solid background, or fallback
        if let gradientColors = theme.gradientColors, let firstColor = gradientColors.first {
            return hexToUIColor(firstColor)
        }
        return UIColor.systemYellow.withAlphaComponent(0.3)
    }
    
    private static func getThemeBarcodeBackgroundColor(theme: BackgroundTheme) -> UIColor {
        // Barcode background (the white parts)
        if let backgroundHex = theme.barcodeBackground {
            return hexToUIColor(backgroundHex)
        }
        return UIColor.white
    }
    
    private static func getThemeBarcodeColor(theme: BackgroundTheme) -> UIColor {
        // Barcode bars color (the black parts)
        if let colorHex = theme.barcodeColor {
            return hexToUIColor(colorHex)
        }
        return UIColor.black
    }
    
    // MARK: - Hex to UIColor converter
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    // MARK: - Background image loading
    private static func loadBackgroundImage(theme: BackgroundTheme) -> UIImage? {
        print("Attempting to load background image for theme: \(theme.id)")
        
        // Try local image first
        if let imageName = theme.backgroundImageName {
            print("Trying local image: \(imageName)")
            if let localImage = UIImage(named: imageName) {
                print("Local image loaded successfully")
                return localImage
            } else {
                print("Local image not found: \(imageName)")
            }
        }
        
        // TODO: Add remote image loading here if needed
        if let imageURL = theme.backgroundImageURL {
            print("Remote image URL found but not implemented: \(imageURL)")
            // Future: Implement async image loading from URL
        }
        
        print("No background image loaded")
        return nil
    }
}
