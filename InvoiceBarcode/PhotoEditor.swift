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
    @State private var displayedImageSize: CGSize = .zero
    
    // Barcode state
    @State private var barcodeImage: UIImage?
    @State private var barcodeOffset: CGSize = .zero
    @State private var barcodeScale: CGFloat = 1.0
    @State private var barcodeRotation: Angle = .zero
    @State private var selectedColorSchemeIndex: Int = 0
    
    // Background image transform state
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageScale: CGFloat = 1.0
    @State private var lastImageOffset: CGSize = .zero
    
    // UI state
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var showingPermissionAlert = false
    
    // Constants
    private let barcodeInitialWidth: CGFloat = 150
    private let edgeMargin: CGFloat = 32
    private let rotationSnapThreshold: Double = 5.0 // Degrees for snapping
    private let minimumImageScale: CGFloat = 1.0 // Minimum scale to fill screen
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main canvas area with iPhone screen ratio container
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
                Text(saveAlertMessage + "\n\n如何設定為桌布：\n1. 開啟「照片」app\n2. 選擇剛儲存的照片\n3. 點擊分享按鈕\n4. 選擇「用作桌布」")
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
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let containerSize = calculateContainerSize(availableWidth: availableWidth, availableHeight: availableHeight)
            let imageAspect = image.size.width / image.size.height
            let displayHeight = containerSize.width / imageAspect
            
            ZStack {
                // Layer 1: Editable content layer (image + barcode with gestures)
                ZStack {
                    // Background photo with transform
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: containerSize.width * imageScale, height: displayHeight * imageScale)
                        .offset(x: imageOffset.width, y: imageOffset.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastImageScale * value
                                    imageScale = max(minimumImageScale, newScale)
                                }
                                .onEnded { value in
                                    lastImageScale = imageScale
                                    enforceMinimumScale()
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let currentHeight = displayHeight * imageScale
                                    let currentWidth = containerSize.width * imageScale
                                    
                                    // Calculate potential new offset
                                    var newOffsetX = lastImageOffset.width + value.translation.width
                                    var newOffsetY = lastImageOffset.height + value.translation.height
                                    
                                    // Lock horizontal movement if image width equals container width
                                    if currentWidth <= containerSize.width {
                                        newOffsetX = 0
                                    } else {
                                        // Allow horizontal movement but limit range
                                        let maxOffsetX = (currentWidth - containerSize.width) / 2
                                        newOffsetX = max(-maxOffsetX, min(maxOffsetX, newOffsetX))
                                    }
                                    
                                    // Lock vertical movement if image height is smaller than container
                                    if currentHeight <= containerSize.height {
                                        newOffsetY = 0
                                    } else {
                                        // Allow vertical movement but limit range
                                        let maxOffsetY = (currentHeight - containerSize.height) / 2
                                        newOffsetY = max(-maxOffsetY, min(maxOffsetY, newOffsetY))
                                    }
                                    
                                    imageOffset = CGSize(width: newOffsetX, height: newOffsetY)
                                }
                                .onEnded { _ in
                                    lastImageOffset = imageOffset
                                }
                        )
                    
                    // Barcode overlay (follows background image transform)
                    if let barcode = barcodeImage {
                        Image(uiImage: barcode)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: barcodeInitialWidth * barcodeScale)
                            .rotationEffect(barcodeRotation)
                            .offset(barcodeOffset)
                            .scaleEffect(imageScale)
                            .offset(imageOffset)
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
                                        barcodeRotation = snapRotation(value)
                                    }
                            )
                    }
                }
                .frame(width: containerSize.width, height: containerSize.height)
                .clipped()
                .background(Color.black)
                
                // Layer 2: Fixed UI overlay (completely independent, same bounds as Layer 1)
                lockScreenOverlay(screenWidth: containerSize.width, screenHeight: containerSize.height)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                displayedImageSize = CGSize(width: containerSize.width, height: displayHeight)
            }
            .onChange(of: geometry.size) { _, _ in
                displayedImageSize = CGSize(width: containerSize.width, height: displayHeight)
            }
        }
    }
    
    private func calculateContainerSize(availableWidth: CGFloat, availableHeight: CGFloat) -> CGSize {
        let screenAspect = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        let availableAspect = availableWidth / availableHeight
        
        if availableAspect > screenAspect {
            // Available space is wider, fit to height
            return CGSize(width: availableHeight * screenAspect, height: availableHeight)
        } else {
            // Available space is taller, fit to width
            return CGSize(width: availableWidth, height: availableWidth / screenAspect)
        }
    }
    
    // MARK: - Lock Screen Overlay
    private func lockScreenOverlay(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ZStack {
            // Date
            Text(formattedDate())
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .position(x: screenWidth / 2, y: screenHeight * 0.12)
            
            // Time
            Text(formattedTime())
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.white)
                .position(x: screenWidth / 2, y: screenHeight * 0.2)
            
            // Flashlight (bottom left)
            Image(systemName: "flashlight.off.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .position(x: 50, y: screenHeight - 50)
            
            // Camera (bottom right)
            Image(systemName: "camera.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .position(x: screenWidth - 50, y: screenHeight - 50)
        }
        .allowsHitTesting(false)
    }
    
    private func calculateDisplayedSize(imageSize: CGSize, viewSize: CGSize) -> CGSize {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        if imageAspect > viewAspect {
            // Image is wider, fit to width
            return CGSize(
                width: viewSize.width,
                height: viewSize.width / imageAspect
            )
        } else {
            // Image is taller, fit to height
            return CGSize(
                width: viewSize.height * imageAspect,
                height: viewSize.height
            )
        }
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
        VStack(spacing: 12) {
            // Preview disclaimer
            Text("以上元素僅供預覽，不會出現在最終圖片")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal)
            
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
        
        // Reset background image transform
        imageScale = 1.0
        imageOffset = .zero
        lastImageScale = 1.0
        lastImageOffset = .zero
        
        generateBarcode()
    }
    
    private func enforceMinimumScale() {
        if imageScale < minimumImageScale {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                imageScale = minimumImageScale
                lastImageScale = minimumImageScale
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "EEEE M月d日"
        return formatter.string(from: Date())
    }
    
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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
        autoreleasepool {
            let originalSize = backgroundImage.size
            let maxDimension: CGFloat = 3000
            
            // Calculate if we need to resize
            let needsResize = originalSize.width > maxDimension || originalSize.height > maxDimension
            
            let finalSize: CGSize
            let resizeScale: CGFloat
            
            if needsResize {
                if originalSize.width > originalSize.height {
                    resizeScale = maxDimension / originalSize.width
                } else {
                    resizeScale = maxDimension / originalSize.height
                }
                finalSize = CGSize(width: originalSize.width * resizeScale, height: originalSize.height * resizeScale)
            } else {
                resizeScale = 1.0
                finalSize = originalSize
            }
            
            // Calculate scale from displayed size to final size
            guard displayedImageSize.width > 0 && displayedImageSize.height > 0 else {
                saveAlertMessage = "儲存失敗,請重試"
                showingSaveAlert = true
                return
            }
            
            let displayToFinalScale = finalSize.width / displayedImageSize.width
            
            // Create composite image
            let renderer = UIGraphicsImageRenderer(size: finalSize)
            
            let compositeImage = renderer.image { context in
                // Draw background image
                backgroundImage.draw(in: CGRect(origin: .zero, size: finalSize))
                
                // Calculate barcode size considering both user scale and image scale
                let totalBarcodeScale = barcodeScale * imageScale
                let barcodeWidth = barcodeInitialWidth * totalBarcodeScale * displayToFinalScale
                let barcodeHeight = barcodeWidth * (barcodeImg.size.height / barcodeImg.size.width)
                
                // Calculate barcode position considering image offset and scale
                let totalOffsetX = (barcodeOffset.width * imageScale) + imageOffset.width
                let totalOffsetY = (barcodeOffset.height * imageScale) + imageOffset.height
                
                let centerX = (finalSize.width / 2) + (totalOffsetX * displayToFinalScale)
                let centerY = (finalSize.height / 2) + (totalOffsetY * displayToFinalScale)
                
                // Save context state
                context.cgContext.saveGState()
                
                // Apply rotation
                context.cgContext.translateBy(x: centerX, y: centerY)
                context.cgContext.rotate(by: CGFloat(barcodeRotation.radians))
                
                // Draw barcode
                let barcodeRect = CGRect(
                    x: -barcodeWidth / 2,
                    y: -barcodeHeight / 2,
                    width: barcodeWidth,
                    height: barcodeHeight
                )
                
                barcodeImg.draw(in: barcodeRect)
                
                // Restore context state
                context.cgContext.restoreGState()
            }
            
            saveImageToLibrary(compositeImage)
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
