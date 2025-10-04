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
    @State private var topExtensionImage: UIImage?
    @State private var topExtensionHeight: CGFloat = 0
    
    // Barcode state
    @State private var barcodeImage: UIImage?
    @State private var barcodeOffset: CGSize = .zero
    @State private var barcodeScale: CGFloat = 1.0
    @State private var barcodeRotation: Angle = .zero
    @State private var selectedColorSchemeIndex: Int = 0
    @State private var lastBarcodeOffset: CGSize = .zero
    @State private var lastBarcodeScale: CGFloat = 1.0
    @State private var lastBarcodeRotation: Angle = .zero
    
    // Text layers state
    @State private var text1: String = "你為什麼要打開手機？"
    @State private var text1Offset: CGSize = .zero
    @State private var text1Scale: CGFloat = 1.0
    @State private var text1Rotation: Angle = .zero
    @State private var lastText1Offset: CGSize = .zero
    @State private var lastText1Scale: CGFloat = 1.0
    @State private var lastText1Rotation: Angle = .zero
    
    @State private var text2: String = "你要看多久？"
    @State private var text2Offset: CGSize = .zero
    @State private var text2Scale: CGFloat = 1.0
    @State private var text2Rotation: Angle = .zero
    @State private var lastText2Offset: CGSize = .zero
    @State private var lastText2Scale: CGFloat = 1.0
    @State private var lastText2Rotation: Angle = .zero
    
    @State private var text3: String = "你還能去做什麼？"
    @State private var text3Offset: CGSize = .zero
    @State private var text3Scale: CGFloat = 1.0
    @State private var text3Rotation: Angle = .zero
    @State private var lastText3Offset: CGSize = .zero
    @State private var lastText3Scale: CGFloat = 1.0
    @State private var lastText3Rotation: Angle = .zero
    
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
    private let textBaseFontSize: CGFloat = 20
    private let edgeMargin: CGFloat = 32
    private let rotationSnapThreshold: Double = 5.0
    private let minimumImageScale: CGFloat = 1.0
    private let extensionRatio: CGFloat = 1.0 / 3.0
    
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
            
            let extendedImageHeight = image.size.height + topExtensionHeight
            let baseScale = calculateBaseScale(
                imageWidth: image.size.width,
                extendedHeight: extendedImageHeight,
                containerSize: containerSize
            )
            
            // Calculate minimum scale needed to fill container
            let minRequiredScale = max(
                containerSize.width / (image.size.width * baseScale),
                containerSize.height / (extendedImageHeight * baseScale)
            )
            
            // Use minimum scale if current scale is too small
            let effectiveScale = max(imageScale, minRequiredScale)
            
            // Calculate initial offset to align image bottom with container bottom
            let scaledExtensionHeight = topExtensionHeight * baseScale * effectiveScale
            let initialOffsetY = -scaledExtensionHeight / 2
            let effectiveOffsetY = imageOffset.height == 0 ? initialOffsetY : imageOffset.height
            
            let magnifyGesture = MagnificationGesture()
                .onChanged { value in
                    let newScale = lastImageScale * value
                    imageScale = max(minRequiredScale, newScale)
                }
                .onEnded { _ in
                    lastImageScale = max(minRequiredScale, imageScale)
                }
            
            let panGesture = DragGesture()
                .onChanged { value in
                    let w = image.size.width * baseScale * effectiveScale
                    let h = image.size.height * baseScale * effectiveScale
                    let eh = topExtensionHeight * baseScale * effectiveScale
                    
                    var x = lastImageOffset.width + value.translation.width
                    var y = lastImageOffset.height + value.translation.height
                    
                    let maxX = max(0, (w - containerSize.width) / 2)
                    x = max(-maxX, min(maxX, x))
                    
                    let topY = (h + eh - containerSize.height) / 2
                    let bottomY = (h - containerSize.height) / 2
                    y = max(-bottomY, min(topY, y))
                    
                    imageOffset = CGSize(width: x, height: y)
                }
                .onEnded { _ in
                    lastImageOffset = imageOffset
                }
            
            ZStack {
                // Layer 1: Editable content layer (image + barcode + text with gestures)
                ZStack {
                    // Top extension area (blurred top edge of image)
                    if let topExtension = topExtensionImage {
                        let extensionWidth = image.size.width * baseScale
                        let extensionHeight = topExtensionHeight * baseScale
                        let imageHeight = image.size.height * baseScale * imageScale
                        let extHeight = topExtensionHeight * baseScale * imageScale
                        let offsetY = effectiveOffsetY - (imageHeight / 2) - (extHeight / 2)
                        
                        Image(uiImage: topExtension)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: extensionWidth, height: extensionHeight)
                            .blur(radius: 20)
                            .scaleEffect(effectiveScale)
                            .offset(x: imageOffset.width, y: offsetY)
                    }
                    
                    // Background photo with transform
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: image.size.width * baseScale, height: image.size.height * baseScale)
                        .scaleEffect(effectiveScale)
                        .offset(x: imageOffset.width, y: imageOffset.height)
                        .gesture(magnifyGesture)
                        .simultaneousGesture(panGesture)
                    
                    // Barcode overlay (follows background image transform)
                    if let barcode = barcodeImage {
                        Image(uiImage: barcode)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: barcodeInitialWidth * barcodeScale)
                            .rotationEffect(barcodeRotation)
                            .offset(barcodeOffset)
                            .scaleEffect(effectiveScale)
                            .offset(imageOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        barcodeOffset = CGSize(
                                            width: lastBarcodeOffset.width + value.translation.width / effectiveScale,
                                            height: lastBarcodeOffset.height + value.translation.height / effectiveScale
                                        )
                                    }
                                    .onEnded { _ in
                                        lastBarcodeOffset = barcodeOffset
                                    }
                            )
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        barcodeScale = lastBarcodeScale * value
                                        barcodeScale = max(0.5, min(3.0, barcodeScale))
                                    }
                                    .onEnded { _ in
                                        lastBarcodeScale = barcodeScale
                                    }
                            )
                            .simultaneousGesture(
                                RotationGesture()
                                    .onChanged { value in
                                        barcodeRotation = lastBarcodeRotation + value
                                    }
                                    .onEnded { value in
                                        let finalRotation = lastBarcodeRotation + value
                                        barcodeRotation = snapRotation(finalRotation)
                                        lastBarcodeRotation = barcodeRotation
                                    }
                            )
                    }
                    
                    // Text layer 1
                    textLayerView(
                        text: text1,
                        offset: text1Offset,
                        scale: text1Scale,
                        rotation: text1Rotation,
                        effectiveScale: effectiveScale,
                        onDragChanged: { value in
                            text1Offset = CGSize(
                                width: lastText1Offset.width + value.translation.width / effectiveScale,
                                height: lastText1Offset.height + value.translation.height / effectiveScale
                            )
                        },
                        onDragEnded: { _ in
                            lastText1Offset = text1Offset
                        },
                        onScaleChanged: { value in
                            text1Scale = lastText1Scale * value
                            text1Scale = max(0.5, min(3.0, text1Scale))
                        },
                        onScaleEnded: { _ in
                            lastText1Scale = text1Scale
                        },
                        onRotationChanged: { value in
                            text1Rotation = lastText1Rotation + value
                        },
                        onRotationEnded: { value in
                            let finalRotation = lastText1Rotation + value
                            text1Rotation = snapRotation(finalRotation)
                            lastText1Rotation = text1Rotation
                        }
                    )
                    
                    // Text layer 2
                    textLayerView(
                        text: text2,
                        offset: text2Offset,
                        scale: text2Scale,
                        rotation: text2Rotation,
                        effectiveScale: effectiveScale,
                        onDragChanged: { value in
                            text2Offset = CGSize(
                                width: lastText2Offset.width + value.translation.width / effectiveScale,
                                height: lastText2Offset.height + value.translation.height / effectiveScale
                            )
                        },
                        onDragEnded: { _ in
                            lastText2Offset = text2Offset
                        },
                        onScaleChanged: { value in
                            text2Scale = lastText2Scale * value
                            text2Scale = max(0.5, min(3.0, text2Scale))
                        },
                        onScaleEnded: { _ in
                            lastText2Scale = text2Scale
                        },
                        onRotationChanged: { value in
                            text2Rotation = lastText2Rotation + value
                        },
                        onRotationEnded: { value in
                            let finalRotation = lastText2Rotation + value
                            text2Rotation = snapRotation(finalRotation)
                            lastText2Rotation = text2Rotation
                        }
                    )
                    
                    // Text layer 3
                    textLayerView(
                        text: text3,
                        offset: text3Offset,
                        scale: text3Scale,
                        rotation: text3Rotation,
                        effectiveScale: effectiveScale,
                        onDragChanged: { value in
                            text3Offset = CGSize(
                                width: lastText3Offset.width + value.translation.width / effectiveScale,
                                height: lastText3Offset.height + value.translation.height / effectiveScale
                            )
                        },
                        onDragEnded: { _ in
                            lastText3Offset = text3Offset
                        },
                        onScaleChanged: { value in
                            text3Scale = lastText3Scale * value
                            text3Scale = max(0.5, min(3.0, text3Scale))
                        },
                        onScaleEnded: { _ in
                            lastText3Scale = text3Scale
                        },
                        onRotationChanged: { value in
                            text3Rotation = lastText3Rotation + value
                        },
                        onRotationEnded: { value in
                            let finalRotation = lastText3Rotation + value
                            text3Rotation = snapRotation(finalRotation)
                            lastText3Rotation = text3Rotation
                        }
                    )
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
                // Set initial scale and offset to fill container
                let minScale = max(
                    containerSize.width / (image.size.width * baseScale),
                    containerSize.height / ((image.size.height + topExtensionHeight) * baseScale)
                )
                if imageScale < minScale {
                    imageScale = minScale
                    lastImageScale = minScale
                }
                
                // Set initial Y offset to align bottom edge
                if imageOffset.height == 0 {
                    let scaledExtensionHeight = topExtensionHeight * baseScale * minScale
                    imageOffset.height = scaledExtensionHeight / 2
                    lastImageOffset.height = scaledExtensionHeight / 2
                }
                
                // Store the base displayed size for coordinate conversion
                displayedImageSize = CGSize(
                    width: image.size.width * baseScale,
                    height: image.size.height * baseScale
                )
                
                // Set initial text positions (right bottom area, left-aligned, stacked vertically)
                if text1Offset == .zero && text2Offset == .zero && text3Offset == .zero {
                    let baseWidth = image.size.width * baseScale
                    let baseHeight = image.size.height * baseScale
                    let rightMargin = baseWidth * 0.35
                    let bottomStart = baseHeight * 0.25
                    let spacing: CGFloat = 30
                    
                    text1Offset = CGSize(width: rightMargin, height: bottomStart)
                    text2Offset = CGSize(width: rightMargin, height: bottomStart + spacing)
                    text3Offset = CGSize(width: rightMargin, height: bottomStart + spacing * 2)
                    
                    lastText1Offset = text1Offset
                    lastText2Offset = text2Offset
                    lastText3Offset = text3Offset
                }
            }
        }
    }
    
    // MARK: - Text Layer View
    private func textLayerView(
        text: String,
        offset: CGSize,
        scale: CGFloat,
        rotation: Angle,
        effectiveScale: CGFloat,
        onDragChanged: @escaping (DragGesture.Value) -> Void,
        onDragEnded: @escaping (DragGesture.Value) -> Void,
        onScaleChanged: @escaping (CGFloat) -> Void,
        onScaleEnded: @escaping (CGFloat) -> Void,
        onRotationChanged: @escaping (Angle) -> Void,
        onRotationEnded: @escaping (Angle) -> Void
    ) -> some View {
        Text(text)
            .font(.system(size: textBaseFontSize, weight: .bold))
            .foregroundColor(.white)
            .shadow(color: .black, radius: 0, x: -1, y: -1)
            .shadow(color: .black, radius: 0, x: 1, y: -1)
            .shadow(color: .black, radius: 0, x: -1, y: 1)
            .shadow(color: .black, radius: 0, x: 1, y: 1)
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .offset(offset)
            .scaleEffect(effectiveScale)
            .offset(imageOffset)
            .gesture(
                DragGesture()
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged(onScaleChanged)
                    .onEnded(onScaleEnded)
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged(onRotationChanged)
                    .onEnded(onRotationEnded)
            )
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
    
    private func calculateBaseScale(imageWidth: CGFloat, extendedHeight: CGFloat, containerSize: CGSize) -> CGFloat {
        let extendedImageAspect = imageWidth / extendedHeight
        let containerAspect = containerSize.width / containerSize.height
        
        if extendedImageAspect > containerAspect {
            // Image is wider, fit to height
            return containerSize.height / extendedHeight
        } else {
            // Image is taller, fit to width
            return containerSize.width / imageWidth
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
            Text("以上元素僅供預覽,不會出現在最終圖片")
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
                Button(action: resetAll) {
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
                
                // Calculate extension height based on short edge
                let shortEdge = min(image.size.width, image.size.height)
                topExtensionHeight = shortEdge * extensionRatio
                
                topExtensionImage = createTopExtension(from: image, height: topExtensionHeight)
                
                // Reset and set initial offset for aspect fill
                resetAll()
            }
        }
    }
    
    private func generateBarcode() {
        let carrierNumber = SharedUserDefaults.getCarrierNumber()
        let number = carrierNumber.isEmpty ? "/ABC123" : carrierNumber
        let scheme = BarcodeGenerator.colorSchemes[selectedColorSchemeIndex]
        barcodeImage = BarcodeGenerator.generateCode128(from: number, scheme: scheme)
    }
    
    private func resetAll() {
        // Reset barcode transform
        barcodeOffset = .zero
        barcodeScale = 1.0
        barcodeRotation = .zero
        selectedColorSchemeIndex = 0
        lastBarcodeOffset = .zero
        lastBarcodeScale = 1.0
        lastBarcodeRotation = .zero
        
        // Reset text layers transform
        text1Offset = .zero
        text1Scale = 1.0
        text1Rotation = .zero
        lastText1Offset = .zero
        lastText1Scale = 1.0
        lastText1Rotation = .zero
        
        text2Offset = .zero
        text2Scale = 1.0
        text2Rotation = .zero
        lastText2Offset = .zero
        lastText2Scale = 1.0
        lastText2Rotation = .zero
        
        text3Offset = .zero
        text3Scale = 1.0
        text3Rotation = .zero
        lastText3Offset = .zero
        lastText3Scale = 1.0
        lastText3Rotation = .zero
        
        // Reset background image transform
        imageScale = 1.0
        imageOffset = .zero
        lastImageScale = 1.0
        lastImageOffset = .zero
        
        generateBarcode()
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
    
    private func createTopExtension(from image: UIImage, height: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Crop top 1 pixel row
        let cropHeight: CGFloat = 1
        let scale = image.scale
        
        let cropRect = CGRect(
            x: 0,
            y: 0,
            width: cgImage.width,
            height: Int(cropHeight * scale)
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        // Create extension by stretching the top pixel
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: image.size.width, height: height))
        
        let extendedImage = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: image.size.width, height: height)
            context.cgContext.draw(croppedCGImage, in: rect)
        }
        
        return extendedImage
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
                
                // Draw barcode
                drawBarcodeLayer(
                    image: barcodeImg,
                    offset: barcodeOffset,
                    scale: barcodeScale,
                    rotation: barcodeRotation,
                    baseWidth: barcodeInitialWidth,
                    displayToFinalScale: displayToFinalScale,
                    finalSize: finalSize,
                    context: context
                )
                
                // Draw text layers
                drawTextLayer(
                    text: text1,
                    offset: text1Offset,
                    scale: text1Scale,
                    rotation: text1Rotation,
                    displayToFinalScale: displayToFinalScale,
                    finalSize: finalSize,
                    context: context
                )
                
                drawTextLayer(
                    text: text2,
                    offset: text2Offset,
                    scale: text2Scale,
                    rotation: text2Rotation,
                    displayToFinalScale: displayToFinalScale,
                    finalSize: finalSize,
                    context: context
                )
                
                drawTextLayer(
                    text: text3,
                    offset: text3Offset,
                    scale: text3Scale,
                    rotation: text3Rotation,
                    displayToFinalScale: displayToFinalScale,
                    finalSize: finalSize,
                    context: context
                )
            }
            
            saveImageToLibrary(compositeImage)
        }
    }
    
    private func drawBarcodeLayer(
        image: UIImage,
        offset: CGSize,
        scale: CGFloat,
        rotation: Angle,
        baseWidth: CGFloat,
        displayToFinalScale: CGFloat,
        finalSize: CGSize,
        context: UIGraphicsImageRendererContext
    ) {
        // Calculate barcode size in final output
        let barcodeWidth = baseWidth * scale * displayToFinalScale
        let barcodeHeight = barcodeWidth * (image.size.height / image.size.width)
        
        // Calculate barcode position in final output
        let centerX = (finalSize.width / 2) + (offset.width * displayToFinalScale)
        let centerY = (finalSize.height / 2) + (offset.height * displayToFinalScale)
        
        // Save context state
        context.cgContext.saveGState()
        
        // Apply rotation around barcode center
        context.cgContext.translateBy(x: centerX, y: centerY)
        context.cgContext.rotate(by: CGFloat(rotation.radians))
        
        // Draw barcode
        let barcodeRect = CGRect(
            x: -barcodeWidth / 2,
            y: -barcodeHeight / 2,
            width: barcodeWidth,
            height: barcodeHeight
        )
        
        image.draw(in: barcodeRect)
        
        // Restore context state
        context.cgContext.restoreGState()
    }
    
    private func drawTextLayer(
        text: String,
        offset: CGSize,
        scale: CGFloat,
        rotation: Angle,
        displayToFinalScale: CGFloat,
        finalSize: CGSize,
        context: UIGraphicsImageRendererContext
    ) {
        // Calculate text position in final output
        let centerX = (finalSize.width / 2) + (offset.width * displayToFinalScale)
        let centerY = (finalSize.height / 2) + (offset.height * displayToFinalScale)
        
        // Calculate text size
        let fontSize = textBaseFontSize * scale * displayToFinalScale
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        
        // Text attributes with stroke (black outline)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0  // Negative value for both fill and stroke
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // Save context state
        context.cgContext.saveGState()
        
        // Apply rotation around text center
        context.cgContext.translateBy(x: centerX, y: centerY)
        context.cgContext.rotate(by: CGFloat(rotation.radians))
        
        // Draw text
        let textRect = CGRect(
            x: -textSize.width / 2,
            y: -textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
        
        // Restore context state
        context.cgContext.restoreGState()
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
