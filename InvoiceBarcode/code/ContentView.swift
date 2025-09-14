// ===============================
// File: ContentView.swift (Main App Target)
// ===============================
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var carrierNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTheme: BackgroundTheme = ThemeManager.shared.getDefaultTheme()
    @State private var availableThemes: [BackgroundTheme] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                // Title Section
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("發票載具條碼")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("輸入載具編號，生成鎖定畫面條碼")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("載具編號")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("請輸入載具編號 (例: /ABC123)", text: $carrierNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.title3, design: .monospaced))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    
                    Text("請輸入完整的載具編號，包含開頭的符號")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Widget 背景主題")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Refresh button for future server integration
                        Button(action: refreshThemes) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(availableThemes) { theme in
                            Button(action: {
                                selectedTheme = theme
                                // Immediately update Widget preview
                                WidgetCenter.shared.reloadAllTimelines()
                            }) {
                                HStack {
                                    Text(theme.preview)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(theme.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        if let description = theme.description {
                                            Text(description)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    if selectedTheme.id == theme.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTheme.id == theme.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                        .strokeBorder(selectedTheme.id == theme.id ? Color.blue : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                
                // Preview Section - Use themed barcode generation
                if !carrierNumber.isEmpty {
                    VStack(spacing: 12) {
                        Text("Widget 預覽（實際顯示效果）")
                            .font(.headline)
                        
                        if let themedBarcodeImage = generateThemedBarcodeForPreview() {
                            CarrierBarcodeWidgetView(
                                barcodeImage: themedBarcodeImage,
                                carrierNumber: carrierNumber,
                                theme: selectedTheme
                            )
                            .frame(height: 80)
                            .frame(maxWidth: 200)
                            .shadow(radius: 2)
                        }
                        
                        // Show theme barcode colors info
                        HStack(spacing: 16) {
                            if let barcodeColor = selectedTheme.barcodeColor {
                                VStack(spacing: 4) {
                                    Text("條碼顏色")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color(hex: barcodeColor))
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                }
                            }
                            
                            if let backgroundColor = selectedTheme.barcodeBackground {
                                VStack(spacing: 4) {
                                    Text("背景顏色")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(Color(hex: backgroundColor))
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                        
                        Text(carrierNumber)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Save Button
                Button(action: saveCarrierNumber) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("儲存到 Widget")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(carrierNumber.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(carrierNumber.isEmpty)
                .padding(.horizontal)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 8) {
                    Text("使用說明")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("鎖定 iPhone 螢幕", systemImage: "1.circle.fill")
                        Label("長按鎖定畫面進入編輯模式", systemImage: "2.circle.fill")
                        Label("點選「自訂」→「鎖定畫面」", systemImage: "3.circle.fill")
                        Label("點選時間下方的 Widget 區域", systemImage: "4.circle.fill")
                        Label("選擇「發票載具條碼」", systemImage: "5.circle.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("發票載具")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("儲存結果", isPresented: $showingAlert) {
            Button("確定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadInitialData()
        }
        .refreshable {
            // Update themes from server
            await refreshThemesFromServer()
        }
    }
    
    private func loadInitialData() {
        carrierNumber = SharedUserDefaults.getCarrierNumber()
        selectedTheme = SharedUserDefaults.getBackgroundTheme()
        
        // Initialize default themes if needed
        SharedUserDefaults.initializeDefaultThemes()
        availableThemes = ThemeManager.shared.availableThemes
    }
    
    private func refreshThemes() {
        availableThemes = ThemeManager.shared.availableThemes
    }
    
    // Generate themed barcode for preview using new renderer
    private func generateThemedBarcodeForPreview() -> UIImage? {
        return ThemedBarcodeRenderer.generateThemedBarcode(
            carrierNumber: carrierNumber,
            theme: selectedTheme,
            size: CGSize(width: 300, height: 100)
        )
    }
    
    private func saveCarrierNumber() {
        let trimmedNumber = carrierNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedNumber.isEmpty else {
            alertMessage = "請輸入有效的載具編號"
            showingAlert = true
            return
        }
        
        SharedUserDefaults.saveCarrierNumber(trimmedNumber)
        SharedUserDefaults.saveBackgroundTheme(selectedTheme)
        WidgetCenter.shared.reloadAllTimelines()
        
        // Verify save success
        let saved = SharedUserDefaults.getCarrierNumber()
        print("Saved carrier number: \(saved)")
        print("Saved background theme: \(selectedTheme.displayName)")
        
        // Show barcode colors info
        if let barcodeColor = selectedTheme.barcodeColor, let bgColor = selectedTheme.barcodeBackground {
            print("Barcode color: \(barcodeColor), Background color: \(bgColor)")
        }
        
        alertMessage = "載具編號和主題已儲存！\n請到鎖定畫面新增 Widget"
        showingAlert = true
    }
    
    // Update themes from server
    private func refreshThemesFromServer() async {
        do {
            try await ThemeManager.shared.loadThemesFromServer()
            await MainActor.run {
                availableThemes = ThemeManager.shared.availableThemes
            }
        } catch {
            print("Failed to fetch themes: \(error)")
            // Could show error message to user
        }
    }
}

#Preview {
    ContentView()
}
