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
    @State private var barcodeColor: UIColor = .black
    
    // UI state
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var showingPermissionAlert = false
    
    // Constants
    private let barcodeInitialWidth: CGFloat = 150
    private let edgeMargin: CGFloat = 32
    
    // Available barcode colors
    private let availableColors: [(name: String, color: UIColor)] = [
        ("黑色", .black),
        ("深藍", UIColor(red: 0, green: 0.2, blue: 0.4, alpha: 1)),
        ("深綠", UIColor(red: 0, green: 0.3, blue: 0.2, alpha: 1))
    ]
    
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
            // Color selector
            HStack(spacing: 20) {
                ForEach(availableColors, id: \.name) { colorOption in
                    Button(action: {
                        barcodeColor = colorOption.color
                        generateBarcode()
                    }) {
                        Circle()
                            .fill(Color(colorOption.color))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(
                                        barcodeColor == colorOption.color ? Color.white : Color.clear,
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
        barcodeImage = BarcodeGenerator.generateCode128(from: number, color: barcodeColor)
    }
    
    private func resetBarcode() {
        guard let image = selectedImage else { return }
        
        // Calculate initial position at bottom right
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        let barcodeWidth = barcodeInitialWidth
        let barcodeHeight = barcodeWidth * 0.36 // Approximate barcode aspect ratio
        
        // Calculate offset to place barcode at bottom right with margin
        let offsetX = (imageWidth / 2) - (barcodeWidth / 2) - edgeMargin
        let offsetY = (imageHeight / 2) - (barcodeHeight / 2) - edgeMargin
        
        barcodeOffset = CGSize(width: offsetX, height: offsetY)
        barcodeScale = 1.0
        barcodeRotation = .zero
        barcodeColor = .black
        generateBarcode()
    }
    
    private func saveCompositeImage() {
        guard let backgroundImage = selectedImage,
              let barcodeImg = barcodeImage else {
            return
        }
        
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        performImageComposite(backgroundImage: backgroundImage, barcodeImg: barcodeImg)
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else if status == .authorized {
            performImageComposite(backgroundImage: backgroundImage, barcodeImg: barcodeImg)
        } else {
            showingPermissionAlert = true
        }
    }
    
    private func performImageComposite(backgroundImage: UIImage, barcodeImg: UIImage) {
        let renderer = UIGraphicsImageRenderer(size: backgroundImage.size)
        
        let compositeImage = renderer.image { context in
            // Draw background image
            backgroundImage.draw(at: .zero)
            
            // Calculate barcode final size and position
            let barcodeWidth = barcodeInitialWidth * barcodeScale
            let barcodeHeight = barcodeWidth * 0.36
            
            // Convert offset from view coordinates to image coordinates
            let imageWidth = backgroundImage.size.width
            let imageHeight = backgroundImage.size.height
            
            let centerX = imageWidth / 2 + barcodeOffset.width
            let centerY = imageHeight / 2 + barcodeOffset.height
            
            let barcodeRect = CGRect(
                x: centerX - barcodeWidth / 2,
                y: centerY - barcodeHeight / 2,
                width: barcodeWidth,
                height: barcodeHeight
            )
            
            // Save context state
            context.cgContext.saveGState()
            
            // Apply rotation around barcode center
            context.cgContext.translateBy(x: centerX, y: centerY)
            context.cgContext.rotate(by: CGFloat(barcodeRotation.radians))
            context.cgContext.translateBy(x: -centerX, y: -centerY)
            
            // Draw barcode
            barcodeImg.draw(in: barcodeRect)
            
            // Restore context state
            context.cgContext.restoreGState()
        }
        
        // Save to photo library using modern PHPhotoLibrary API
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: compositeImage)
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
