// ===============================
// File: CarrierWidget.swift (Widget Extension Target)
// ===============================
import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
struct CarrierEntry: TimelineEntry {
    let date: Date
    let carrierNumber: String
    let barcodeImage: UIImage?
    let theme: BackgroundTheme
}

// MARK: - Widget Timeline Provider
struct CarrierProvider: TimelineProvider {
    func placeholder(in context: Context) -> CarrierEntry {
        let defaultTheme = ThemeManager.shared.getDefaultTheme()
        let placeholderImage = generateThemedBarcode(carrierNumber: "/ABC123", theme: defaultTheme)
        
        return CarrierEntry(
            date: Date(),
            carrierNumber: "/ABC123",
            barcodeImage: placeholderImage,
            theme: defaultTheme
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CarrierEntry) -> ()) {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let currentTheme = SharedUserDefaults.getBackgroundTheme()
        let barcodeImage = generateThemedBarcode(carrierNumber: carrierNumber, theme: currentTheme)
        
        let entry = CarrierEntry(
            date: Date(),
            carrierNumber: carrierNumber,
            barcodeImage: barcodeImage,
            theme: currentTheme
        )
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CarrierEntry>) -> ()) {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let currentTheme = SharedUserDefaults.getBackgroundTheme()
        let barcodeImage = generateThemedBarcode(carrierNumber: carrierNumber, theme: currentTheme)
        
        let entry = CarrierEntry(
            date: Date(),
            carrierNumber: carrierNumber,
            barcodeImage: barcodeImage,
            theme: currentTheme
        )
        
        // Update every 24 hours
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // Generate themed barcode using new renderer
    private func generateThemedBarcode(carrierNumber: String, theme: BackgroundTheme) -> UIImage? {
        return ThemedBarcodeRenderer.generateThemedBarcode(
            carrierNumber: carrierNumber,
            theme: theme,
            size: CGSize(width: 300, height: 100)
        )
    }
}

// MARK: - Lock Screen Widget View (simplified)
struct CarrierWidgetView: View {
    var entry: CarrierProvider.Entry
    
    var body: some View {
        // Use the shared view with entry data
        CarrierBarcodeWidgetView(
            barcodeImage: entry.barcodeImage,
            carrierNumber: entry.carrierNumber,
            theme: entry.theme
        )
    }
}

// MARK: - Widget Configuration
struct CarrierWidget: Widget {
    let kind: String = "CarrierWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CarrierProvider()) { entry in
            CarrierWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    // Required for iOS 17+
                    Color.clear
                }
        }
        .configurationDisplayName("發票載具條碼")
        .description("在鎖定畫面顯示您的發票載具條碼，方便快速結帳時使用")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Widget Bundle (Entry Point)
@main
struct CarrierWidgetBundle: WidgetBundle {
    var body: some Widget {
        CarrierWidget()
    }
}

// MARK: - Preview
#Preview(as: .accessoryRectangular) {
    CarrierWidget()
} timeline: {
    let defaultTheme = ThemeManager.shared.getDefaultTheme()
    let sampleImage = ThemedBarcodeRenderer.generateThemedBarcode(
        carrierNumber: "/ABC123",
        theme: defaultTheme,
        size: CGSize(width: 300, height: 100)
    )
    CarrierEntry(date: Date(), carrierNumber: "/ABC123", barcodeImage: sampleImage, theme: defaultTheme)
    
    CarrierEntry(date: .now, carrierNumber: "", barcodeImage: nil, theme: defaultTheme)
}
