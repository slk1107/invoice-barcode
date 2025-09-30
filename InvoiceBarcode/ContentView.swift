// ===============================
// File: ContentView.swift (Main App Target)
// ===============================
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var carrierNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPhotoEditor = false
    
    // Helper function to ensure carrier number starts with "/"
    private func normalizeCarrierNumber(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        
        return trimmed.hasPrefix("/") ? trimmed : "/" + trimmed
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Title Section
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("發票載具條碼")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("輸入載具編號,生成鎖定畫面條碼")
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
                    }
                    .padding(.horizontal)
                    
                    // Preview Section
                    if !carrierNumber.isEmpty {
                        let normalizedNumber = normalizeCarrierNumber(carrierNumber)
                        
                        VStack(spacing: 12) {
                            Text("條碼預覽")
                                .font(.headline)
                            
                            if let barcodeImage = BarcodeGenerator.generateCode128(from: normalizedNumber) {
                                Image(uiImage: barcodeImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                            
                            Text(normalizedNumber)
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
                    
                    // Photo Editor Button
                    Button(action: { showingPhotoEditor = true }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("編輯照片")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
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
            }
            
            .navigationTitle("發票載具")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("儲存結果", isPresented: $showingAlert) {
            Button("確定") { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showingPhotoEditor) {
            PhotoEditorView()
        }
        .onAppear {
            carrierNumber = SharedUserDefaults.getCarrierNumber()
        }
    }
    
    private func saveCarrierNumber() {
        let normalizedNumber = normalizeCarrierNumber(carrierNumber)
        
        guard !normalizedNumber.isEmpty else {
            alertMessage = "請輸入有效的載具編號"
            showingAlert = true
            return
        }
        
        SharedUserDefaults.saveCarrierNumber(normalizedNumber)
        WidgetCenter.shared.reloadAllTimelines()
        
        // Verify save success
        let saved = SharedUserDefaults.getCarrierNumber()
        print("已儲存載具編號: \(saved)")
        
        alertMessage = "載具編號已儲存!\n請到鎖定畫面新增 Widget"
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
