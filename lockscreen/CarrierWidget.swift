//
//  CarrierWidget.swift
//  InvoiceBarcode
//
//  Created by Kris Lin on 2025/9/13.
//



// ===============================
// 檔案 4: CarrierWidget.swift (Widget Extension Target)
// ===============================
import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
struct CarrierEntry: TimelineEntry {
    let date: Date
    let carrierNumber: String
    let barcodeImage: UIImage?
}

// MARK: - Widget Timeline Provider
struct CarrierProvider: TimelineProvider {
    func placeholder(in context: Context) -> CarrierEntry {
        let placeholderImage = BarcodeGenerator.generateCode128(from: "/ABC123")
        return CarrierEntry(
            date: Date(),
            carrierNumber: "/ABC123",
            barcodeImage: placeholderImage
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CarrierEntry) -> ()) {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let barcodeImage = BarcodeGenerator.generateCode128(from: carrierNumber)
        
        let entry = CarrierEntry(
            date: Date(),
            carrierNumber: carrierNumber,
            barcodeImage: barcodeImage
        )
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CarrierEntry>) -> ()) {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let barcodeImage = BarcodeGenerator.generateCode128(from: carrierNumber)
        
        let entry = CarrierEntry(
            date: Date(),
            carrierNumber: carrierNumber,
            barcodeImage: barcodeImage
        )
        
        // Update every 24 hours
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

// MARK: - Lock Screen Widget View
struct CarrierWidgetView: View {
    var entry: CarrierProvider.Entry
    
    var body: some View {
        ZStack {
            // Official background for consistency
            AccessoryWidgetBackground()
            
            if let barcodeImage = entry.barcodeImage, !entry.carrierNumber.isEmpty {
                // Show barcode with white background for scanning
                VStack(spacing: 0) {
                    Image(uiImage: barcodeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                }
                .background(Color.white)
                .cornerRadius(4)
                .padding(3)
            } else {
                // Show setup message when no carrier number
                VStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16))
                    Text("請設定載具")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
            }
        }
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
    let sampleImage = BarcodeGenerator.generateCode128(from: "/ABC123")
    CarrierEntry(date: Date(), carrierNumber: "/ABC123", barcodeImage: sampleImage)
    
    CarrierEntry(date: .now, carrierNumber: "", barcodeImage: nil)
}
