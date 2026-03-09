import SwiftUI

struct PreviewView: View {
    let template: WallpaperTemplate
    let priorities: [PriorityItem]
    let todos: [TodoItem]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var previewImage: UIImage?
    @State private var showSafeArea = false
    @State private var selectedPreset: DevicePreset = .current
    @State private var isLoading = true
    @State private var showExport = false
    @State private var errorMessage: String?

    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("contentPosition") private var contentPosition: String = "center"
    @AppStorage("topPadding") private var topPadding: Double = 0
    @AppStorage("backgroundMode") private var backgroundMode: String = "dark"
    @AppStorage("photoOffsetX") private var photoOffsetX: Double = 0
    @AppStorage("photoOffsetY") private var photoOffsetY: Double = 0
    @AppStorage("fontColor") private var fontColor: String = "auto"
    @AppStorage("photoBlur") private var photoBlur: Double = 0
    @AppStorage("photoDim") private var photoDim: Double = 0.45

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    // Device frame with wallpaper preview
                    previewArea
                        .padding(.top, 8)

                    // Photo position controls
                    if backgroundMode == "photo" {
                        photoOffsetControls
                    }

                    // Controls
                    controlsArea

                    // Export button
                    exportButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $showSafeArea) {
                        Image(systemName: "rectangle.dashed")
                    }
                    .toggleStyle(.button)
                    .tint(showSafeArea ? .indigo : .secondary)
                    .accessibilityLabel("Safe area overlay")
                    .accessibilityValue(showSafeArea ? "Showing" : "Hidden")
                }
            }
            .sheet(isPresented: $showExport) {
                if let image = previewImage {
                    ExportView(
                        image: image,
                        template: template,
                        priorities: priorities,
                        todos: todos
                    )
                }
            }
            .task { await generatePreview() }
            .onChange(of: fontScale) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: contentPosition) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: topPadding) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: backgroundMode) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: photoOffsetX) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: photoOffsetY) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: fontColor) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: photoBlur) { _, _ in
                Task { await generatePreview() }
            }
            .onChange(of: photoDim) { _, _ in
                Task { await generatePreview() }
            }
        }
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height * 0.7
            let aspectRatio = selectedPreset.resolution.width / selectedPreset.resolution.height
            let previewWidth = min(geometry.size.width - 40, maxHeight * aspectRatio)
            let previewHeight = previewWidth / aspectRatio

            ZStack {
                // Phone frame
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color(.systemGray3), lineWidth: 3)
                    .frame(width: previewWidth + 8, height: previewHeight + 8)

                // Wallpaper image
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: previewWidth, height: previewHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                } else if isLoading {
                    ProgressView()
                        .frame(width: previewWidth, height: previewHeight)
                } else {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: previewWidth, height: previewHeight)
                        .overlay {
                            Text("Preview unavailable")
                                .foregroundStyle(.secondary)
                        }
                }

                // Safe area overlay
                if showSafeArea {
                    safeAreaOverlay(width: previewWidth, height: previewHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func safeAreaOverlay(width: CGFloat, height: CGFloat) -> some View {
        let preset = selectedPreset
        let scaleX = width / CGFloat(preset.screenWidth)
        let scaleY = height / CGFloat(preset.screenHeight)

        return ZStack {
            // Top safe area (clock / Dynamic Island)
            VStack {
                Rectangle()
                    .fill(Color.red.opacity(0.25))
                    .frame(height: preset.safeArea.top * scaleY)
                    .overlay {
                        VStack(spacing: 2) {
                            if preset.hasDynamicIsland {
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 80 * scaleX, height: 24 * scaleY)
                            }
                            Text("Clock Zone")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                        }
                    }
                Spacer()
            }

            // Bottom safe area (home indicator)
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.red.opacity(0.25))
                    .frame(height: preset.safeArea.bottom * scaleY)
                    .overlay {
                        Text("Home")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .allowsHitTesting(false)
    }

    // MARK: - Controls

    private var controlsArea: some View {
        HStack {
            Text("Device")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Device", selection: $selectedPreset) {
                ForEach(DevicePreset.allPresets, id: \.id) { preset in
                    Text(preset.name).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .tint(.indigo)
            .onChange(of: selectedPreset) { _, _ in
                Task { await generatePreview() }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Photo Offset

    private var photoOffsetControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.and.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Slider(value: $photoOffsetX, in: -1...1, step: 0.05)
                    .tint(.indigo)
            }
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.and.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Slider(value: $photoOffsetY, in: -1...1, step: 0.05)
                    .tint(.indigo)
            }
            Button("Reset Position") {
                photoOffsetX = 0
                photoOffsetY = 0
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Export

    private var exportButton: some View {
        Button {
            showExport = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .disabled(previewImage == nil)
    }

    // MARK: - Generation

    private func generatePreview() async {
        isLoading = true
        errorMessage = nil

        do {
            let service = ExportService()
            previewImage = try await service.generatePreview(
                panels: template.panels,
                theme: nil,
                devicePreset: selectedPreset,
                priorities: priorities,
                todos: todos
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    PreviewView(
        template: WallpaperTemplate(name: "Test", panels: []),
        priorities: [],
        todos: []
    )
    .environmentObject(SubscriptionManager())
}
