import SwiftUI
import Photos

struct ExportView: View {
    let image: UIImage
    let template: WallpaperTemplate
    let priorities: [PriorityItem]
    let todos: [TodoItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var selectedPreset: DevicePreset = .current
    @State private var selectedFormat: ImageFormat = .png
    @State private var jpegQuality: Double = 0.9
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var showPaywall = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview thumbnail
                    thumbnailSection

                    // Settings
                    presetSection
                    formatSection

                    // Actions
                    actionButtons

                    // Free tier info
                    if !subscriptionManager.isPro {
                        freeTierInfo
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $exportSuccess) {
                PostExportSheet(onDismiss: { dismiss() })
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Thumbnail

    private var thumbnailSection: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            Text("\(selectedPreset.screenWidth) x \(selectedPreset.screenHeight) px")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Preset Picker

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Preset")
                .font(.subheadline.bold())

            Picker("Device", selection: $selectedPreset) {
                ForEach(DevicePreset.allPresets, id: \.id) { preset in
                    Text(preset.name).tag(preset)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Format

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Format")
                .font(.subheadline.bold())

            HStack(spacing: 12) {
                ForEach(ImageFormat.allCases, id: \.self) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        Text(format.displayName)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedFormat == format ? Color.indigo : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedFormat == format ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedFormat == .jpeg {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quality: \(Int(jpegQuality * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $jpegQuality, in: 0.5...1.0, step: 0.1)
                        .tint(.indigo)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await saveToPhotos() }
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Save to Photos")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(isExporting || !subscriptionManager.canExport)

            ShareLink(item: Image(uiImage: image), preview: SharePreview("Wallpaper", image: Image(uiImage: image))) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.bordered)
            .tint(.indigo)
        }
    }

    // MARK: - Free Tier Info

    private var freeTierInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("\(subscriptionManager.remainingFreeExports) of \(SubscriptionManager.freeExportLimit) free exports remaining today")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Upgrade") {
                showPaywall = true
            }
            .font(.caption.bold())
            .foregroundStyle(.indigo)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Export Logic

    private func saveToPhotos() async {
        guard subscriptionManager.canExport else {
            showPaywall = true
            return
        }

        isExporting = true
        defer { isExporting = false }

        do {
            // Generate at full resolution
            let service = ExportService()
            let result = try await service.generateWallpaper(
                panels: template.panels,
                theme: nil,
                devicePreset: selectedPreset,
                priorities: priorities,
                todos: todos,
                format: selectedFormat,
                jpegQuality: jpegQuality
            )

            try await service.saveToPhotos(result.image)
            subscriptionManager.recordExport()
            saveHistoryEntry(image: result.image)
            exportSuccess = true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func saveHistoryEntry(image: UIImage) {
        let thumbnailWidth: CGFloat = 300
        let scale = thumbnailWidth / image.size.width
        let thumbnailSize = CGSize(
            width: thumbnailWidth,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnailData = renderer.jpegData(withCompressionQuality: 0.7) { context in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }

        let entry = ExportHistoryItem(
            thumbnailData: thumbnailData,
            devicePresetName: selectedPreset.name,
            templateName: template.name,
            resolution: "\(selectedPreset.screenWidth)x\(selectedPreset.screenHeight)"
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

// MARK: - Post-Export Sheet

struct PostExportSheet: View {
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Success indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                VStack(spacing: 6) {
                    Text("Saved to Photos")
                        .font(.title3.bold())
                    Text("Your wallpaper is ready to use")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "photos-redirect://") {
                            UIApplication.shared.open(url)
                        }
                        dismiss()
                        onDismiss()
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Open Photos")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    NavigationLink {
                        WallpaperSetupGuide()
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap")
                            Text("How to Set as Wallpaper")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)

                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Wallpaper Setup Guide

struct WallpaperSetupGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Set your Lock Screen wallpaper in a few taps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                guideStep(
                    number: 1,
                    title: "Open Photos",
                    detail: "Find the wallpaper you just saved (it's the most recent image)."
                )
                guideStep(
                    number: 2,
                    title: "Tap Share",
                    detail: "Tap the share icon in the bottom-left corner."
                )
                guideStep(
                    number: 3,
                    title: "Use as Wallpaper",
                    detail: "Scroll down and tap \"Use as Wallpaper\"."
                )
                guideStep(
                    number: 4,
                    title: "Adjust & Set",
                    detail: "Pinch to adjust if needed, then tap \"Set\" and choose Lock Screen."
                )

                // Alternative method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alternative: From Lock Screen")
                        .font(.subheadline.bold())

                    Text("Long-press your Lock Screen, tap \"+\" or \"Customize\", then choose your photo from the gallery.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(20)
        }
        .navigationTitle("Set as Wallpaper")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func guideStep(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.indigo)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ExportView(
        image: UIImage(systemName: "photo")!,
        template: WallpaperTemplate(name: "Test", panels: []),
        priorities: [],
        todos: []
    )
    .environmentObject(SubscriptionManager())
}
