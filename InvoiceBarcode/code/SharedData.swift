// ===============================
// File: SharedData.swift (Both Targets) - Updated with background image support
// ===============================
import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Background Theme Struct (Updated)
struct BackgroundTheme: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let preview: String
    let description: String?
    
    // Background image support
    let backgroundImageURL: String?    // Remote background image URL
    let backgroundImageName: String?   // Local background image name (for development)
    
    // Fallback gradient colors (used when no background image available)
    let gradientColors: [String]?      // Hex color codes
    let iconName: String?
    
    // Barcode customization
    let barcodeColor: String?          // Hex color for barcode bars
    let barcodeBackground: String?     // Hex color for barcode background (fallback only)
    
    init(id: String,
         displayName: String,
         preview: String,
         description: String? = nil,
         backgroundImageURL: String? = nil,
         backgroundImageName: String? = nil,
         gradientColors: [String]? = nil,
         iconName: String? = nil,
         barcodeColor: String? = nil,
         barcodeBackground: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.preview = preview
        self.description = description
        self.backgroundImageURL = backgroundImageURL
        self.backgroundImageName = backgroundImageName
        self.gradientColors = gradientColors
        self.iconName = iconName
        self.barcodeColor = barcodeColor
        self.barcodeBackground = barcodeBackground
    }
}

// MARK: - Theme Manager (Updated)
class ThemeManager {
    static let shared = ThemeManager()
    private init() {}
    
    // Default themes with background image support
    private let defaultThemes: [BackgroundTheme] = [
        BackgroundTheme(
            id: "winnie",
            displayName: "小熊維尼風格",
            preview: "🐻🍯",
            description: "溫暖的蜂蜜色調配上可愛小熊",
            backgroundImageName: "winnie_background", // Designer will provide this
            gradientColors: ["#FFE135", "#FF8C00"],   // Fallback
            iconName: "teddybear.fill",
            barcodeColor: "#8B4513",
            barcodeBackground: "#FFF8DC"
        ),
        BackgroundTheme(
            id: "minimal",
            displayName: "簡約風格",
            preview: "⬜️⚪️",
            description: "簡潔俐落的設計風格",
            backgroundImageName: "minimal_background",
            gradientColors: ["#F5F5F5", "#E0E0E0"],
            iconName: "circle.fill",
            barcodeColor: "#000000",
            barcodeBackground: "#FFFFFF"
        ),
        BackgroundTheme(
            id: "gradient",
            displayName: "漸層風格",
            preview: "🌈✨",
            description: "繽紛的彩虹漸層效果",
            backgroundImageName: "gradient_background",
            gradientColors: ["#9C27B0", "#2196F3", "#00BCD4"],
            iconName: "sparkles",
            barcodeColor: "#4A148C",
            barcodeBackground: "#E1F5FE"
        ),
        BackgroundTheme(
            id: "cute",
            displayName: "可愛動物風格",
            preview: "🐱🐶",
            description: "粉嫩色系配上萌萌小動物",
            backgroundImageName: "snoopy_background", // Snoopy lying on barcode
            gradientColors: ["#FFB6C1", "#98FB98"],
            iconName: "cat.fill",
            barcodeColor: "#FF1493",
            barcodeBackground: "#FFF0F5"
        )
    ]
    
    var availableThemes: [BackgroundTheme] {
        return SharedUserDefaults.getAvailableThemes()
    }
    
    func getTheme(by id: String) -> BackgroundTheme? {
        return availableThemes.first { $0.id == id }
    }
    
    func getDefaultTheme() -> BackgroundTheme {
        return getTheme(by: "winnie") ?? defaultThemes[0]
    }
    
    func loadDefaultThemes() {
        SharedUserDefaults.saveAvailableThemes(defaultThemes)
    }
    
    // Load themes from server with background images
    func loadThemesFromServer() async throws {
        // TODO: Implement API call to fetch themes with background image URLs
        /*
        let url = URL(string: "https://api.yourserver.com/themes")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let serverThemes = try JSONDecoder().decode([BackgroundTheme].self, from: data)
        
        // Server response example:
        // {
        //   "id": "winnie_v2",
        //   "displayName": "小熊維尼風格 V2",
        //   "preview": "🐻🍯",
        //   "backgroundImageURL": "https://cdn.yourserver.com/themes/winnie_v2_background.png",
        //   "barcodeColor": "#8B4513"
        // }
        
        SharedUserDefaults.saveAvailableThemes(serverThemes)
        */
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Simplified Widget View (now uses ThemedBarcodeRenderer)
struct CarrierBarcodeWidgetView: View {
    let barcodeImage: UIImage?
    let carrierNumber: String
    let theme: BackgroundTheme
    
    var body: some View {
        ZStack {
            if let barcodeImage = barcodeImage, !carrierNumber.isEmpty {
                // Show themed barcode image (includes background and barcode)
                Image(uiImage: barcodeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                // Show setup message when no carrier number
                ZStack {
                    // Fallback background
                    backgroundView(for: theme)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1)
                        Text("請設定載具")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func backgroundView(for theme: BackgroundTheme) -> some View {
        if let gradientColors = theme.gradientColors, gradientColors.count >= 2 {
            LinearGradient(
                colors: gradientColors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if let backgroundHex = theme.barcodeBackground {
            Color(hex: backgroundHex)
        } else {
            Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Shared User Defaults for App Groups
class SharedUserDefaults {
    private static let appGroupID = "group.idlevillager.InvoiceBarcode"
    private static let carrierNumberKey = "carrierNumber"
    private static let updatedDateKey = "updatedDate"
    private static let backgroundThemeKey = "backgroundTheme"
    private static let availableThemesKey = "availableThemes"
    
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
    
    // Background theme management
    static func saveBackgroundTheme(_ theme: BackgroundTheme) {
        if let encoded = try? JSONEncoder().encode(theme) {
            sharedDefaults?.set(encoded, forKey: backgroundThemeKey)
            sharedDefaults?.synchronize()
        }
    }
    
    static func getBackgroundTheme() -> BackgroundTheme {
        guard let data = sharedDefaults?.data(forKey: backgroundThemeKey),
              let theme = try? JSONDecoder().decode(BackgroundTheme.self, from: data) else {
            return ThemeManager.shared.getDefaultTheme()
        }
        return theme
    }
    
    // Available themes management
    static func saveAvailableThemes(_ themes: [BackgroundTheme]) {
        if let encoded = try? JSONEncoder().encode(themes) {
            sharedDefaults?.set(encoded, forKey: availableThemesKey)
            sharedDefaults?.synchronize()
        }
    }
    
    static func getAvailableThemes() -> [BackgroundTheme] {
        guard let data = sharedDefaults?.data(forKey: availableThemesKey),
              let themes = try? JSONDecoder().decode([BackgroundTheme].self, from: data) else {
            return []
        }
        return themes
    }
    
    static func initializeDefaultThemes() {
        if getAvailableThemes().isEmpty {
            ThemeManager.shared.loadDefaultThemes()
        }
    }
}
