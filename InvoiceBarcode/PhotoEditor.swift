// ===============================
// File: PhotoEditorView.swift (Main App Target)
// ===============================
import SwiftUI
import PhotosUI
import Photos

struct PhotoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Photo picker state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Barcode state
    @State private var barcodeImage: UIImage?
    @State private var barcodeOffset: CGSize = .zero
    @State private var barcodeScale: CGFloat = 1.0
    @State private var barcodeRotation: Angle = .zero
    @State private var selectedColorSchemeIndex: Int = 0
    
    // UI state
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var showingPermissionAlert = false
    
    // Constants
    private let barcodeInitialWidth: CGFloat = 150
    private let edgeMargin: CGFloat = 32
    private let rotationSnapThreshold: Double = 5.0 // Degrees for snapping
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main canvas area
                    if let image = selectedImage {
                        canvasView(image: image)
                    } else {
                        photoPickerPlaceholder
                    }
                    
                    // Bottom toolbar
                    if selectedImage != nil {
                        toolbarView
                    }
                }
            }
            .navigationTitle("編輯照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("儲存結果", isPresented: $showingSaveAlert) {
                Button("確定") {
                    if saveAlertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(saveAlertMessage)
            }
            .alert("需要權限", isPresented: $showingPermissionAlert) {
                Button("前往設定", role: .none) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("請在設定中允許存取照片,才能儲存編輯後的圖片")
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            loadSelectedPhoto(newValue)
        }
        .onAppear {
            generateBarcode()
        }
    }
    
    // MARK: - Canvas View
    private func canvasView(image: UIImage) -> some View {
        ZStack {
            // Background photo
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            // Barcode overlay
            if let barcode = barcodeImage {
                Image(uiImage: barcode)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: barcodeInitialWidth * barcodeScale)
                    .rotationEffect(barcodeRotation)
                    .offset(barcodeOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                barcodeOffset = CGSize(
                                    width: value.translation.width,
                                    height: value.translation.height
                                )
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                barcodeScale = max(0.5, min(3.0, value))
                            }
                    )
                    .simultaneousGesture(
                        RotationGesture()
                            .onChanged { value in
                                barcodeRotation = value
                            }
                            .onEnded { value in
                                // Apply rotation snapping to 90 degree increments
                                barcodeRotation = snapRotation(value)
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Photo Picker Placeholder
    private var photoPickerPlaceholder: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("選擇照片")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("點擊選擇相簿中的照片")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Toolbar View
    private var toolbarView: some View {
        VStack(spacing: 16) {
            // Color scheme selector
            HStack(spacing: 20) {
                ForEach(0..<BarcodeGenerator.colorSchemes.count, id: \.self) { index in
                    let scheme = BarcodeGenerator.colorSchemes[index]
                    Button(action: {
                        selectedColorSchemeIndex = index
                        generateBarcode()
                    }) {
                        Circle()
                            .fill(Color(scheme.foregroundColor))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color(scheme.backgroundColor),
                                        lineWidth: 4
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedColorSchemeIndex == index ? Color.white : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Reset button
                Button(action: resetBarcode) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("重置")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                // Save button
                Button(action: saveCompositeImage) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("儲存")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Helper Functions
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                resetBarcode()
            }
        }
    }
    
    private func generateBarcode() {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let number = carrierNumber.isEmpty ? "/ABC123" : carrierNumber
        let scheme = BarcodeGenerator.colorSchemes[selectedColorSchemeIndex]
        barcodeImage = BarcodeGenerator.generateCode128(from: number, scheme: scheme)
    }
    
    private func resetBarcode() {
        // Reset to center position
        barcodeOffset = .zero
        barcodeScale = 1.0
        barcodeRotation = .zero
        selectedColorSchemeIndex = 0
        generateBarcode()
    }
    
    private func snapRotation(_ angle: Angle) -> Angle {
        let degrees = angle.degrees.truncatingRemainder(dividingBy: 360)
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        
        // Check proximity to 0, 90, 180, 270 degrees
        let snapAngles: [Double] = [0, 90, 180, 270, 360]
        
        for snapAngle in snapAngles {
            if abs(normalizedDegrees - snapAngle) <= rotationSnapThreshold {
                return Angle(degrees: snapAngle == 360 ? 0 : snapAngle)
            }
        }
        
        return Angle(degrees: normalizedDegrees)
    }
    
    private func saveCompositeImage() {
        guard let backgroundImage = selectedImage else {
            return
        }
        
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        // Temporarily save original image only for testing
                        saveImageToLibrary(backgroundImage)
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else if status == .authorized {
            // Temporarily save original image only for testing
            saveImageToLibrary(backgroundImage)
        } else {
            showingPermissionAlert = true
        }
    }
    
    private func saveImageToLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveAlertMessage = "照片已成功儲存到相簿!"
                } else if let error = error {
                    saveAlertMessage = "儲存失敗: \(error.localizedDescription)"
                } else {
                    saveAlertMessage = "儲存失敗,請稍後再試"
                }
                showingSaveAlert = true
            }
        }
    }
}

#Preview {
    PhotoEditorView()
}
