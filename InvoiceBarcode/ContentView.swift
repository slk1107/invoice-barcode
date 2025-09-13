
// ===============================
// 檔案 2: ContentView.swift (主 App Target)
// ===============================
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var carrierNumber: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                
                // Preview Section
                if !carrierNumber.isEmpty {
                    VStack(spacing: 12) {
                        Text("條碼預覽")
                            .font(.headline)
                        
                        if let barcodeImage = BarcodeGenerator.generateCode128(from: carrierNumber) {
                            Image(uiImage: barcodeImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
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
                        Label("點選時鐘下方的 Widget 區域", systemImage: "4.circle.fill")
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
            carrierNumber = SharedUserDefaults.getCarrierNumber()
        }
    }
    
    private func saveCarrierNumber() {
        let trimmedNumber = carrierNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedNumber.isEmpty else {
            alertMessage = "請輸入有效的載具編號"
            showingAlert = true
            return
        }
        
        SharedUserDefaults.saveCarrierNumber(trimmedNumber)
        WidgetCenter.shared.reloadAllTimelines()
        
        // 驗證儲存成功
        let saved = SharedUserDefaults.getCarrierNumber()
        print("已儲存載具編號: \(saved)")
        
        alertMessage = "載具編號已儲存！\n請到鎖定畫面新增 Widget"
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
