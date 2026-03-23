import SwiftUI
import PhotosUI

struct ThemePickerSheet: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedColorScheme") private var selectedScheme: String = "dark"
    @AppStorage("selectedAccent") private var selectedAccent: String = "indigo"
    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("contentPosition") private var contentPosition: String = "center"
    @AppStorage("topPadding") private var topPadding: Double = 0
    @AppStorage("backgroundMode") private var backgroundMode: String = "dark"
    @AppStorage("fontColor") private var fontColor: String = "auto"
    @AppStorage("photoBlur") private var photoBlur: Double = 0
    @AppStorage("photoDim") private var photoDim: Double = 0.45

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var bgThumbnail: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Background
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Background")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 4)

                        HStack(spacing: 8) {
                            bgModeButton("Dark", value: "dark", color: Color(UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1)))
                            bgModeButton("Light", value: "light", color: Color(UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)))
                            bgPhotoButton
                        }

                        // Gradients (Pro)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text("Gradients")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !subscriptionManager.isPro {
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.indigo)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 4)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(GradientPreset.allCases) { preset in
                                        gradientPresetButton(preset)
                                    }
                                }
                            }
                        }

                        // Photo thumbnail when photo mode is active
                        if backgroundMode == "photo" {
                            if let thumb = bgThumbnail {
                                HStack(spacing: 12) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Custom photo")
                                            .font(.caption)
                                        Text("A dark overlay is added for text readability")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        backgroundMode = "dark"
                                        bgThumbnail = nil
                                        ExportService.deleteBackgroundImage()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Text("No photo selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                            }

                        }
                    }

                    // Photo Effects (only visible when photo background is active)
                    if backgroundMode == "photo" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo Effects")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 4)

                            // Live preview of photo with effects
                            if let thumb = bgThumbnail {
                                ZStack {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .blur(radius: photoBlur * 0.3)
                                        .clipped()

                                    Color.black.opacity(photoDim)

                                    Text("Aa")
                                        .font(.title.bold())
                                        .foregroundStyle(.white)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "drop.halffull")
                                        .frame(width: 20)
                                    Text("Blur")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(photoBlur == 0 ? "Off" : "\(Int(photoBlur))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $photoBlur, in: 0...30, step: 1)
                                    .tint(.indigo)
                            }

                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .frame(width: 20)
                                    Text("Dim")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(photoDim * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $photoDim, in: 0...0.8, step: 0.05)
                                    .tint(.indigo)
                            }
                        }
                    }

                    // Accent Color
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent Color")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(AccentColorOption.allCases) { option in
                                accentButton(option)
                            }
                        }
                    }

                    // Font Color
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Color")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                            ForEach(FontColorOption.allCases) { option in
                                fontColorButton(option)
                            }
                        }
                    }

                    // Font Size & Text Position moved to Editor Layout section
                }
                .padding(20)
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    ExportService.saveBackgroundImage(image)
                    backgroundMode = "photo"
                    selectedScheme = "dark" // white text on photo overlay
                    bgThumbnail = image
                }
            }
            .onAppear {
                if backgroundMode == "photo" {
                    if let image = UIImage(contentsOfFile: ExportService.backgroundImageURL.path) {
                        bgThumbnail = image
                    }
                }
            }
        }
    }

    private func accentButton(_ option: AccentColorOption) -> some View {
        let isSelected = selectedAccent == option.rawValue
        let isLocked = option.isPro && !subscriptionManager.isPro

        return Button {
            guard !isLocked else { return }
            selectedAccent = option.rawValue
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(option.color)
                        .frame(width: 36, height: 36)

                    if isLocked {
                        Circle()
                            .fill(.black.opacity(0.3))
                            .frame(width: 36, height: 36)
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }

                Text(option.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(isLocked ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? option.color.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.rawValue.capitalized) accent color\(isLocked ? ", Pro required" : "")")
    }

    private func positionButton(_ label: String, value: String, icon: String) -> some View {
        let isSelected = contentPosition == value

        return Button {
            contentPosition = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .indigo : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gradient Preset Button

    private func gradientPresetButton(_ preset: GradientPreset) -> some View {
        let isSelected = backgroundMode == preset.backgroundModeValue
        let isLocked = !subscriptionManager.isPro

        return Button {
            guard !isLocked else { return }
            backgroundMode = preset.backgroundModeValue
            selectedScheme = "dark"
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(preset.topColor), Color(preset.bottomColor)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 40)

                    if isLocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.3))
                            .frame(width: 40, height: 40)
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }
                Text(preset.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 64)
            .padding(.vertical, 8)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background Mode Buttons

    private func bgModeButton(_ label: String, value: String, color: Color) -> some View {
        let isSelected = backgroundMode == value

        return Button {
            backgroundMode = value
            selectedScheme = value // sync color scheme for text colors
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .indigo : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var bgPhotoButton: some View {
        let isSelected = backgroundMode == "photo"
        let isLocked = !subscriptionManager.isPro

        return PhotosPicker(
            selection: $selectedPhoto,
            matching: .images
        ) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "photo")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("Photo")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .indigo : (isLocked ? .secondary : .primary))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .disabled(isLocked)
    }

    private func fontScaleButton(_ option: FontScaleOption) -> some View {
        let isSelected = abs(fontScale - option.scale) < 0.01

        return Button {
            fontScale = option.scale
        } label: {
            VStack(spacing: 4) {
                Text("Aa")
                    .font(.system(size: option.previewSize, weight: .medium))
                Text(option.label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .indigo : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Font size \(option.label)")
    }

    private func fontColorButton(_ option: FontColorOption) -> some View {
        let isSelected = fontColor == option.rawValue

        return Button {
            fontColor = option.rawValue
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(option == .auto
                            ? LinearGradient(colors: [.white, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [option.previewColor, option.previewColor], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                    }
                }
                Text(option.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Font Scale Options

enum FontScaleOption: String, CaseIterable, Identifiable {
    case small, medium, large, extraLarge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        }
    }

    var scale: Double {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        }
    }

    /// Preview text size in the picker button
    var previewSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 20
        case .extraLarge: return 23
        }
    }
}

#Preview {
    ThemePickerSheet()
        .environmentObject(SubscriptionManager())
}
