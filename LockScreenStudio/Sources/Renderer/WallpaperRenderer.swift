import SwiftUI
import UIKit

/// Core wallpaper rendering engine.
/// Converts a composed panel layout into a UIImage at a specific resolution.
///
/// Design choices:
/// - Uses UIGraphicsImageRenderer (not SwiftUI ImageRenderer) for reliability
///   across all iOS 17+ devices and deterministic pixel output.
/// - Renders panels top-to-bottom in a single-column layout, with configurable
///   margins that respect Lock Screen safe areas.
/// - Deterministic: same inputs always produce identical output (no random elements).
@MainActor
final class WallpaperRenderer {

    // MARK: - Public API

    struct RenderRequest {
        let panels: [PanelRenderData]
        let theme: RenderTheme
        let devicePreset: DevicePreset
        let format: ImageFormat
        let jpegQuality: CGFloat
        let contentPosition: ContentPosition
        let clockTopPadding: CGFloat
        let backgroundImage: UIImage?
        /// Normalized offset for photo background (-1...1 range, where 0 is centered)
        let photoOffsetX: CGFloat
        let photoOffsetY: CGFloat
        /// Blur radius for photo background (0...30)
        let photoBlur: CGFloat
        /// Dim overlay opacity for photo background (0...0.8)
        let photoDim: CGFloat

        init(
            panels: [PanelRenderData],
            theme: RenderTheme = .defaultDark,
            devicePreset: DevicePreset = .current,
            format: ImageFormat = .png,
            jpegQuality: CGFloat = 0.9,
            contentPosition: ContentPosition = .center,
            clockTopPadding: CGFloat = 0,
            backgroundImage: UIImage? = nil,
            photoOffsetX: CGFloat = 0,
            photoOffsetY: CGFloat = 0,
            photoBlur: CGFloat = 0,
            photoDim: CGFloat = 0.45
        ) {
            self.panels = panels
            self.theme = theme
            self.devicePreset = devicePreset
            self.format = format
            self.jpegQuality = jpegQuality
            self.contentPosition = contentPosition
            self.clockTopPadding = clockTopPadding
            self.backgroundImage = backgroundImage
            self.photoOffsetX = photoOffsetX
            self.photoOffsetY = photoOffsetY
            self.photoBlur = photoBlur
            self.photoDim = photoDim
        }
    }

    enum ContentPosition: String {
        case top, center, bottom
    }

    struct RenderResult {
        let image: UIImage
        let imageData: Data
        let resolution: CGSize
        let format: ImageFormat
    }

    /// Generates a wallpaper image from the given request.
    /// This is the primary entry point for all wallpaper generation.
    func render(_ request: RenderRequest) throws -> RenderResult {
        let size = request.devicePreset.resolution
        let safeArea = request.devicePreset.safeArea
        let theme = request.theme

        // One pixel per point, because the preset's resolution is already in
        // pixels. The default format draws at the screen's scale, which made
        // every wallpaper three times too large each way on a 3x iPhone —
        // 3960x8604 for a 1320x2868 screen, a ~136 MB bitmap for the
        // background automation to hold.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // 1. Draw background (solid/gradient or custom photo)
            drawBackground(in: rect, theme: theme, backgroundImage: request.backgroundImage, photoOffsetX: request.photoOffsetX, photoOffsetY: request.photoOffsetY, photoBlur: request.photoBlur, photoDim: request.photoDim, context: cgContext)

            // 2. Calculate content area (respecting safe areas)
            // clockTopPadding is a bipolar vertical offset applied AFTER position
            // calculation, so it shifts text up (negative) or down (positive)
            // regardless of whether content is top/center/bottom aligned.
            let verticalOffset = request.clockTopPadding
            let contentRect = CGRect(
                x: safeArea.leading + theme.margins.left,
                y: safeArea.top + theme.margins.top,
                width: size.width - safeArea.leading - safeArea.trailing - theme.margins.left - theme.margins.right,
                height: size.height - safeArea.top - safeArea.bottom - theme.margins.top - theme.margins.bottom
            )

            // 3. Calculate total content height to vertically distribute
            let totalContentHeight = request.panels.reduce(CGFloat(0)) { sum, panel in
                sum + panel.estimatedHeight(forWidth: contentRect.width, theme: theme)
            }
            let totalSpacing = CGFloat(max(0, request.panels.count - 1)) * theme.panelSpacing
            let neededHeight = totalContentHeight + totalSpacing

            // 3b. Content position (top/center/bottom)
            let startY: CGFloat
            switch request.contentPosition {
            case .top:
                startY = contentRect.minY
            case .center:
                if neededHeight < contentRect.height {
                    startY = contentRect.minY + (contentRect.height - neededHeight) * 0.5
                } else {
                    startY = contentRect.minY
                }
            case .bottom:
                if neededHeight < contentRect.height {
                    startY = contentRect.maxY - neededHeight
                } else {
                    startY = contentRect.minY
                }
            }

            // 4. Render panels sequentially (apply bipolar vertical offset)
            var currentY = startY + verticalOffset
            // The slack the layout has always allowed below the content area.
            let bottom = contentRect.maxY + 20

            for (index, panelData) in request.panels.enumerated() {
                // A panel that runs past the bottom is cut short, not left out.
                // With exact heights, leaving out every panel that overran
                // dropped a whole To-Do panel from a small screen at a large
                // text size, over a single line too many. A panel is skipped
                // only when not even its title and first line fit.
                let room = bottom - currentY
                guard room >= panelData.minimumHeight(forWidth: contentRect.width, theme: theme) else { break }

                // Drawn above the panel rather than below the previous one, so
                // there is never a divider with nothing under it.
                if theme.showSeparators && index > 0 {
                    let separatorY = currentY - theme.panelSpacing * 0.5
                    cgContext.saveGState()
                    cgContext.setStrokeColor(theme.separatorColor.cgColor)
                    cgContext.setLineWidth(1.0)
                    let lineInset = contentRect.width * 0.05
                    cgContext.move(to: CGPoint(x: contentRect.minX + lineInset, y: separatorY))
                    cgContext.addLine(to: CGPoint(x: contentRect.maxX - lineInset, y: separatorY))
                    cgContext.strokePath()
                    cgContext.restoreGState()
                }

                let panelHeight = panelData.estimatedHeight(forWidth: contentRect.width, theme: theme)
                let panelRect = CGRect(
                    x: contentRect.minX,
                    y: currentY,
                    width: contentRect.width,
                    height: min(panelHeight, room)
                )
                drawPanel(panelData, in: panelRect, theme: theme, context: cgContext)

                guard panelHeight <= room else { break }
                currentY = panelRect.maxY + theme.panelSpacing
            }
        }

        // Encode to the requested format
        let imageData: Data
        switch request.format {
        case .png:
            guard let data = image.pngData() else {
                throw RenderError.encodingFailed
            }
            imageData = data
        case .jpeg:
            guard let data = image.jpegData(compressionQuality: request.jpegQuality) else {
                throw RenderError.encodingFailed
            }
            imageData = data
        }

        return RenderResult(
            image: image,
            imageData: imageData,
            resolution: size,
            format: request.format
        )
    }

    /// The preview, drawn exactly as the export is: same size, same type.
    ///
    /// It used to be typeset at a third of the size, where the system font's
    /// optical sizing sets text measurably wider, so lines wrapped in the
    /// preview that didn't in the export — and with the layout measuring
    /// wrapped text, the two could disagree about where every panel sat. At
    /// one pixel per point the full-size render has the same pixels the
    /// third-size one had at 3x.
    func renderPreview(
        panels: [PanelRenderData],
        theme: RenderTheme,
        devicePreset: DevicePreset,
        contentPosition: ContentPosition = .center,
        clockTopPadding: CGFloat = 0,
        backgroundImage: UIImage? = nil,
        photoOffsetX: CGFloat = 0,
        photoOffsetY: CGFloat = 0,
        photoBlur: CGFloat = 0,
        photoDim: CGFloat = 0.45
    ) throws -> UIImage {
        try render(RenderRequest(
            panels: panels,
            theme: theme,
            devicePreset: devicePreset,
            contentPosition: contentPosition,
            clockTopPadding: clockTopPadding,
            backgroundImage: backgroundImage,
            photoOffsetX: photoOffsetX,
            photoOffsetY: photoOffsetY,
            photoBlur: photoBlur,
            photoDim: photoDim
        )).image
    }

    // MARK: - Private Drawing Methods

    private func drawBackground(in rect: CGRect, theme: RenderTheme, backgroundImage: UIImage?, photoOffsetX: CGFloat = 0, photoOffsetY: CGFloat = 0, photoBlur: CGFloat = 0, photoDim: CGFloat = 0.45, context: CGContext) {
        // Custom photo background
        if let bgImage = backgroundImage {
            // Draw image scaled to fill (aspect fill + offset crop)
            // Use the UIImage with blur applied, or original
            let drawImage: UIImage
            if photoBlur > 0, let blurredUI = Self.applyBlur(to: bgImage, radius: photoBlur) {
                drawImage = blurredUI
            } else {
                drawImage = bgImage
            }
            // Use UIImage.size which respects EXIF orientation
            let imageSize = drawImage.size
            let scaleX = rect.width / imageSize.width
            let scaleY = rect.height / imageSize.height
            let fillScale = max(scaleX, scaleY)
            let drawWidth = imageSize.width * fillScale
            let drawHeight = imageSize.height * fillScale
            // Calculate max pan range (how much the image overflows the frame)
            let overflowX = drawWidth - rect.width
            let overflowY = drawHeight - rect.height
            // Apply offset: 0 = centered, -1 = fully left/up, +1 = fully right/down
            let offsetX = (rect.width - drawWidth) / 2 + photoOffsetX * overflowX / 2
            let offsetY = (rect.height - drawHeight) / 2 + photoOffsetY * overflowY / 2
            let drawRect = CGRect(
                x: offsetX,
                y: offsetY,
                width: drawWidth,
                height: drawHeight
            )

            // UIImage.draw respects EXIF orientation automatically
            drawImage.draw(in: drawRect)

            // Dark overlay for text readability (user-controlled dim)
            if photoDim > 0 {
                context.setFillColor(UIColor.black.withAlphaComponent(photoDim).cgColor)
                context.fill(rect)
            }
            return
        }

        // Solid color background
        context.setFillColor(theme.backgroundColor.cgColor)
        context.fill(rect)

        // Subtle gradient overlay for depth
        if let gradientColors = theme.backgroundGradient {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = gradientColors.map(\.cgColor) as CFArray
            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors,
                locations: [0.0, 1.0]
            ) else { return }

            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: 0),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
        }
    }

    private static func applyBlur(to image: UIImage, radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter?.outputImage else { return nil }
        let ciContext = CIContext()
        // Crop to original extent (blur expands edges)
        let cropped = output.cropped(to: ciImage.extent)
        guard let cgImage = ciContext.createCGImage(cropped, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func drawPanel(
        _ panel: PanelRenderData,
        in rect: CGRect,
        theme: RenderTheme,
        context: CGContext
    ) {
        // Panel background card (subtle rounded rect)
        if theme.showPanelBackground {
            let cardRect = rect.insetBy(dx: -8, dy: -4)
            let cardPath = UIBezierPath(
                roundedRect: cardRect,
                cornerRadius: theme.panelCornerRadius
            )
            context.saveGState()
            context.setFillColor(theme.panelBackgroundColor.cgColor)
            context.addPath(cardPath.cgPath)
            context.fillPath()
            context.restoreGState()
        }

        // Panel title (small caps style header)
        var currentY = rect.minY
        if let title = panel.title {
            let titleString = Self.titleString(title, theme: theme)
            titleString.draw(at: CGPoint(x: rect.minX, y: currentY))
            currentY += Self.measuredHeight(titleString, width: rect.width) + theme.titleBottomSpacing
        }

        // Panel content lines
        // A line stops at the panel's edge: heights are exact, so only a panel
        // cut short at the bottom of the wallpaper has lines that don't fit.
        lines: for line in panel.lines {
            switch line {
            case .heatmapGrid(let weeks, let data):
                // Draw a GitHub-style contribution heatmap grid
                let (cellSize, gap) = Self.heatmapMetrics(
                    weeks: weeks, width: rect.width, theme: theme
                )
                guard currentY + 7 * (cellSize + gap) <= rect.maxY + 1 else { break lines }
                let cornerRadius: CGFloat = cellSize * 0.25

                for week in 0..<weeks {
                    for day in 0..<7 {
                        let index = week * 7 + day
                        let level = index < data.count ? min(data[index], 4) : 0
                        let alpha: CGFloat = switch level {
                        case 0: 0.08
                        case 1: 0.25
                        case 2: 0.45
                        case 3: 0.7
                        default: 1.0
                        }
                        let color = theme.accentUIColor.withAlphaComponent(alpha)
                        let x = rect.minX + CGFloat(week) * (cellSize + gap)
                        let y = currentY + CGFloat(day) * (cellSize + gap)
                        let cellRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                        let cellPath = UIBezierPath(roundedRect: cellRect, cornerRadius: cornerRadius)
                        context.saveGState()
                        context.setFillColor(color.cgColor)
                        context.addPath(cellPath.cgPath)
                        context.fillPath()
                        context.restoreGState()
                    }
                }
                currentY += 7 * (cellSize + gap) + theme.lineSpacing
                continue

            case .calendarGrid(let year, let month, let today, let eventDays):
                // Draw a monthly calendar grid (7 columns x 6 rows max)
                let calendar = Calendar.current
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = 1
                guard let firstOfMonth = calendar.date(from: components) else { continue }
                let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
                let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7 // Monday = 0

                let cols = 7
                let gap: CGFloat = 3
                let cellSize: CGFloat = min(
                    (rect.width - CGFloat(cols - 1) * gap) / CGFloat(cols),
                    theme.bodyFontSize * 1.2
                )
                let totalRows = ((daysInMonth - 1 + firstWeekday) / cols) + 1
                guard currentY + cellSize * 0.6 + gap + CGFloat(totalRows) * (cellSize + gap)
                        <= rect.maxY + 1 else { break lines }
                let totalGridWidth = CGFloat(cols) * cellSize + CGFloat(cols - 1) * gap
                let gridOffsetX = rect.minX

                // Draw weekday headers (M T W T F S S)
                let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                let headerFont = UIFont.systemFont(ofSize: cellSize * 0.45, weight: .medium)
                let headerParagraph = NSMutableParagraphStyle()
                headerParagraph.alignment = .center

                for (i, label) in weekdayLabels.enumerated() {
                    let x = gridOffsetX + CGFloat(i) * (cellSize + gap)
                    let headerRect = CGRect(x: x, y: currentY, width: cellSize, height: cellSize * 0.6)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: headerFont,
                        .foregroundColor: theme.secondaryTextColor,
                        .paragraphStyle: headerParagraph
                    ]
                    NSAttributedString(string: label, attributes: attrs).draw(in: headerRect)
                }
                currentY += cellSize * 0.6 + gap

                // Draw day numbers
                let dayFont = UIFont.systemFont(ofSize: cellSize * 0.5, weight: .regular)
                let todayFont = UIFont.systemFont(ofSize: cellSize * 0.5, weight: .bold)
                let dayParagraph = NSMutableParagraphStyle()
                dayParagraph.alignment = .center

                for day in 1...daysInMonth {
                    let gridIndex = day - 1 + firstWeekday
                    let col = gridIndex % cols
                    let row = gridIndex / cols

                    let x = gridOffsetX + CGFloat(col) * (cellSize + gap)
                    let y = currentY + CGFloat(row) * (cellSize + gap)
                    let dayRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)

                    let isToday = day == today

                    // Today highlight circle
                    if isToday {
                        let circlePath = UIBezierPath(ovalIn: dayRect.insetBy(dx: 1, dy: 1))
                        context.saveGState()
                        context.setFillColor(theme.accentUIColor.cgColor)
                        context.addPath(circlePath.cgPath)
                        context.fillPath()
                        context.restoreGState()
                    }

                    // Day number
                    let textColor: UIColor = isToday
                        ? (theme.backgroundColor.cgColor.alpha < 0.5 ? .white : UIColor(white: 0.05, alpha: 1))
                        : theme.textColor
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: isToday ? todayFont : dayFont,
                        .foregroundColor: textColor,
                        .paragraphStyle: dayParagraph
                    ]
                    let textRect = CGRect(x: x, y: y + cellSize * 0.2, width: cellSize, height: cellSize * 0.6)
                    NSAttributedString(string: "\(day)", attributes: attrs).draw(in: textRect)

                    // Event dot
                    if eventDays.contains(day) && !isToday {
                        let dotSize: CGFloat = cellSize * 0.12
                        let dotX = x + (cellSize - dotSize) / 2
                        let dotY = y + cellSize * 0.82
                        let dotRect = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
                        context.saveGState()
                        context.setFillColor(theme.accentUIColor.cgColor)
                        context.fillEllipse(in: dotRect)
                        context.restoreGState()
                    }
                }

                currentY += CGFloat(totalRows) * (cellSize + gap) + theme.lineSpacing
                continue
            default:
                break
            }

            guard let lineString = Self.attributedLine(line, panelTitle: panel.title, theme: theme) else {
                continue
            }
            // Measured exactly as `PanelRenderData.estimatedHeight` measures it,
            // so the line lands inside the rect the layout gave this panel.
            let lineRect = CGRect(
                x: rect.minX,
                y: currentY,
                width: rect.width,
                height: Self.measuredHeight(lineString, width: rect.width)
            )
            guard lineRect.maxY <= rect.maxY + 1 else { break }
            lineString.draw(in: lineRect)
            currentY = lineRect.maxY + theme.lineSpacing
        }
    }

    // MARK: - Typesetting

    /// Drawing and layout both measure text through these, so a panel is laid
    /// out at the height it is drawn at. The layout used to assume one font
    /// size per line while drawing used the font's real line height, about a
    /// fifth taller: over five or six lines the panel outgrew its slot, the
    /// separator cut through its last line, and lines past the slot were
    /// dropped — at the XL text size, the last event or to-do went missing.
    nonisolated static func titleString(_ title: String, theme: RenderTheme) -> NSAttributedString {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: theme.titleFontSize, weight: .semibold),
            .foregroundColor: theme.titleColor,
            .kern: theme.titleFontSize * 0.15, // Letter spacing for small-caps feel
        ]
        return NSAttributedString(string: title.uppercased(), attributes: titleAttrs)
    }

    /// The typeset text for a line, or nil for the grids, which are drawn
    /// rather than typeset.
    nonisolated static func attributedLine(
        _ line: PanelLine,
        panelTitle: String?,
        theme: RenderTheme
    ) -> NSAttributedString? {
        switch line {
        case .text(let text):
            // Check if it's a date header (all-caps, no title = date panel)
            let isDateHeader = panelTitle == nil
            if isDateHeader && text == text.uppercased() && text.count > 2 {
                // Day of week — render large bold
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: theme.heroFontSize, weight: .heavy),
                    .foregroundColor: theme.textColor,
                    .kern: theme.heroFontSize * 0.03,
                ]
                return NSAttributedString(string: text, attributes: attrs)
            } else if isDateHeader {
                // Date line — render medium, visible
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: theme.dateFontSize, weight: .light),
                    .foregroundColor: theme.textColor.withAlphaComponent(0.6),
                ]
                return NSAttributedString(string: text, attributes: attrs)
            } else {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .regular),
                    .foregroundColor: theme.textColor,
                ]
                return NSAttributedString(string: text, attributes: attrs)
            }

        case .event(let time, let title):
            let timeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: theme.bodyFontSize, weight: .medium),
                .foregroundColor: theme.accentUIColor,
            ]
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .regular),
                .foregroundColor: theme.textColor,
            ]
            let combined = NSMutableAttributedString(string: time, attributes: timeAttrs)
            combined.append(NSAttributedString(string: "  ", attributes: timeAttrs))
            combined.append(NSAttributedString(string: title, attributes: titleAttrs))
            return combined

        case .priority(let rank, let text):
            let rankAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .bold),
                .foregroundColor: theme.accentUIColor,
            ]
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .regular),
                .foregroundColor: theme.textColor,
            ]
            let combined = NSMutableAttributedString(string: "\(rank). ", attributes: rankAttrs)
            combined.append(NSAttributedString(string: text, attributes: textAttrs))
            return combined

        case .todoItem(let text, let completed):
            let checkmark = completed ? "\u{2611}" : "\u{2610}"
            let checkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .regular),
                .foregroundColor: completed ? theme.secondaryTextColor : theme.accentUIColor,
            ]
            let textColor = completed ? theme.secondaryTextColor : theme.textColor
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .regular),
                .foregroundColor: textColor,
                .strikethroughStyle: completed ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughColor: theme.secondaryTextColor,
            ]
            let combined = NSMutableAttributedString(string: checkmark + " ", attributes: checkAttrs)
            combined.append(NSAttributedString(string: text, attributes: textAttrs))
            return combined

        case .heroText(let text):
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.heroFontSize * 1.2, weight: .heavy),
                .foregroundColor: theme.accentUIColor,
                .kern: theme.heroFontSize * 0.02,
            ]
            return NSAttributedString(string: text, attributes: attrs)

        case .subtitle(let text):
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: theme.bodyFontSize, weight: .medium),
                .foregroundColor: theme.secondaryTextColor,
            ]
            return NSAttributedString(string: text, attributes: attrs)

        case .heatmapGrid, .calendarGrid:
            return nil
        }
    }

    nonisolated static func measuredHeight(_ string: NSAttributedString, width: CGFloat) -> CGFloat {
        string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        ).height
    }
}

// MARK: - Render Data Types

/// Processed panel data ready for rendering (decoupled from SwiftData models).
struct PanelRenderData {
    let title: String?
    let lines: [PanelLine]

    /// The least of a panel worth drawing: its title and first line.
    func minimumHeight(forWidth width: CGFloat, theme: RenderTheme) -> CGFloat {
        PanelRenderData(title: title, lines: Array(lines.prefix(1)))
            .estimatedHeight(forWidth: width, theme: theme)
    }

    func estimatedHeight(forWidth width: CGFloat, theme: RenderTheme) -> CGFloat {
        var height: CGFloat = 0

        if let title {
            let titleString = WallpaperRenderer.titleString(title, theme: theme)
            height += WallpaperRenderer.measuredHeight(titleString, width: width) + theme.titleBottomSpacing
        }

        for line in lines {
            switch line {
            case .heatmapGrid(let weeks, _):
                let (cellSize, gap) = WallpaperRenderer.heatmapMetrics(
                    weeks: weeks, width: width, theme: theme
                )
                height += 7 * (cellSize + gap) + theme.lineSpacing
            case .calendarGrid:
                let cellSize = min((width - 6 * 3) / 7, theme.bodyFontSize * 1.2)
                let gap: CGFloat = 3
                // header row + up to 6 week rows
                height += cellSize * 0.6 + gap + 6 * (cellSize + gap) + theme.lineSpacing
            default:
                if let string = WallpaperRenderer.attributedLine(line, panelTitle: title, theme: theme) {
                    height += WallpaperRenderer.measuredHeight(string, width: width) + theme.lineSpacing
                }
            }
        }

        return height
    }
}

extension WallpaperRenderer {

    /// Cell and gap size for the contribution grid, shared by the layout pass
    /// and the drawing pass so the reserved height always matches what is
    /// painted.
    ///
    /// Sizes derive from `bodyFontSize` rather than absolute units: the
    /// renderer works in device pixels, so the old hard-coded 8-unit ceiling
    /// drew a grid roughly 2.7pt wide — invisible on a real wallpaper. The
    /// monthly calendar grid already scaled this way; the heatmap was the
    /// outlier.
    nonisolated static func heatmapMetrics(
        weeks: Int,
        width: CGFloat,
        theme: RenderTheme
    ) -> (cell: CGFloat, gap: CGFloat) {
        let gap = max(1, theme.bodyFontSize * 0.09)
        let available = width - CGFloat(max(0, weeks - 1)) * gap
        // Capped so a short 4-week grid doesn't render as giant slabs, and
        // floored so a full 53-week year still has a visible cell.
        let cell = max(gap * 2, min(theme.bodyFontSize * 1.1, available / CGFloat(max(1, weeks))))
        return (cell, gap)
    }
}

enum PanelLine {
    case text(String)
    case event(time: String, title: String)
    case priority(rank: Int, text: String)
    case todoItem(text: String, completed: Bool)
    case heroText(String)
    case subtitle(String)
    /// Habits heatmap grid: weeks = number of columns, data = flat array of activity levels (0–4), one per day.
    case heatmapGrid(weeks: Int, data: [Int])
    /// Monthly calendar grid: year, month (1-12), today day number (0 if not current month), days with events
    case calendarGrid(year: Int, month: Int, today: Int, eventDays: Set<Int>)
}

// MARK: - Render Theme

struct RenderTheme {
    let backgroundColor: UIColor
    let backgroundGradient: [UIColor]?
    let textColor: UIColor
    let secondaryTextColor: UIColor
    let titleColor: UIColor
    let accentUIColor: UIColor
    let panelBackgroundColor: UIColor
    let showPanelBackground: Bool
    let separatorColor: UIColor
    let showSeparators: Bool

    let heroFontSize: CGFloat      // Day of week
    let dateFontSize: CGFloat      // Date line
    let titleFontSize: CGFloat     // Section headers (AGENDA, TOP 3)
    let titleBottomSpacing: CGFloat
    let bodyFontSize: CGFloat      // Content lines
    let lineSpacing: CGFloat
    let panelSpacing: CGFloat
    let panelPadding: CGFloat
    let panelCornerRadius: CGFloat
    let margins: UIEdgeInsets

    static let defaultDark = RenderTheme(
        backgroundColor: UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1),
        backgroundGradient: [
            UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1),
            UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1),
        ],
        textColor: UIColor(white: 0.95, alpha: 1),
        secondaryTextColor: UIColor(white: 0.45, alpha: 1),
        titleColor: UIColor(white: 0.40, alpha: 1),
        accentUIColor: UIColor(red: 0.42, green: 0.35, blue: 0.94, alpha: 1), // Soft indigo
        panelBackgroundColor: UIColor(white: 1.0, alpha: 0.04),
        showPanelBackground: false,
        separatorColor: UIColor(white: 1.0, alpha: 0.08),
        showSeparators: true,
        heroFontSize: 56,
        dateFontSize: 40,
        titleFontSize: 22,
        titleBottomSpacing: 12,
        bodyFontSize: 36,
        lineSpacing: 16,
        panelSpacing: 48,
        panelPadding: 0,
        panelCornerRadius: 20,
        margins: UIEdgeInsets(top: 40, left: 72, bottom: 80, right: 72)
    )

    static let defaultLight = RenderTheme(
        backgroundColor: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1),
        backgroundGradient: [
            UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
            UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1),
        ],
        textColor: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
        secondaryTextColor: UIColor(white: 0.50, alpha: 1),
        titleColor: UIColor(white: 0.45, alpha: 1),
        accentUIColor: UIColor(red: 0.42, green: 0.35, blue: 0.94, alpha: 1),
        panelBackgroundColor: UIColor(white: 1.0, alpha: 0.7),
        showPanelBackground: false,
        separatorColor: UIColor(white: 0.0, alpha: 0.08),
        showSeparators: true,
        heroFontSize: 56,
        dateFontSize: 40,
        titleFontSize: 22,
        titleBottomSpacing: 12,
        bodyFontSize: 36,
        lineSpacing: 16,
        panelSpacing: 48,
        panelPadding: 0,
        panelCornerRadius: 20,
        margins: UIEdgeInsets(top: 40, left: 72, bottom: 80, right: 72)
    )

    /// Returns a new theme with only font sizes and line spacing scaled.
    /// Used for user font size preference (doesn't affect layout/margins).
    func withFontScale(_ scale: CGFloat) -> RenderTheme {
        guard scale != 1.0 else { return self }
        return RenderTheme(
            backgroundColor: backgroundColor,
            backgroundGradient: backgroundGradient,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            titleColor: titleColor,
            accentUIColor: accentUIColor,
            panelBackgroundColor: panelBackgroundColor,
            showPanelBackground: showPanelBackground,
            separatorColor: separatorColor,
            showSeparators: showSeparators,
            heroFontSize: heroFontSize * scale,
            dateFontSize: dateFontSize * scale,
            titleFontSize: titleFontSize * scale,
            titleBottomSpacing: titleBottomSpacing * scale,
            bodyFontSize: bodyFontSize * scale,
            lineSpacing: lineSpacing * scale,
            panelSpacing: panelSpacing,
            panelPadding: panelPadding,
            panelCornerRadius: panelCornerRadius,
            margins: margins
        )
    }

    /// Creates a theme variant with gradient background and appropriate text colors.
    func withGradient(_ preset: GradientPreset) -> RenderTheme {
        RenderTheme(
            backgroundColor: preset.topColor,
            backgroundGradient: preset.gradientColors,
            textColor: UIColor(white: 0.95, alpha: 1),
            secondaryTextColor: UIColor(white: 0.45, alpha: 1),
            titleColor: UIColor(white: 0.40, alpha: 1),
            accentUIColor: accentUIColor,
            panelBackgroundColor: panelBackgroundColor,
            showPanelBackground: showPanelBackground,
            separatorColor: UIColor(white: 1.0, alpha: 0.08),
            showSeparators: showSeparators,
            heroFontSize: heroFontSize,
            dateFontSize: dateFontSize,
            titleFontSize: titleFontSize,
            titleBottomSpacing: titleBottomSpacing,
            bodyFontSize: bodyFontSize,
            lineSpacing: lineSpacing,
            panelSpacing: panelSpacing,
            panelPadding: panelPadding,
            panelCornerRadius: panelCornerRadius,
            margins: margins
        )
    }

    /// Creates a theme variant with a custom text color.
    func withTextColor(_ color: UIColor) -> RenderTheme {
        RenderTheme(
            backgroundColor: backgroundColor,
            backgroundGradient: backgroundGradient,
            textColor: color,
            secondaryTextColor: color.withAlphaComponent(0.45),
            titleColor: color.withAlphaComponent(0.40),
            accentUIColor: accentUIColor,
            panelBackgroundColor: panelBackgroundColor,
            showPanelBackground: showPanelBackground,
            separatorColor: separatorColor,
            showSeparators: showSeparators,
            heroFontSize: heroFontSize,
            dateFontSize: dateFontSize,
            titleFontSize: titleFontSize,
            titleBottomSpacing: titleBottomSpacing,
            bodyFontSize: bodyFontSize,
            lineSpacing: lineSpacing,
            panelSpacing: panelSpacing,
            panelPadding: panelPadding,
            panelCornerRadius: panelCornerRadius,
            margins: margins
        )
    }

    /// Creates a theme variant with a custom accent color.
    func withAccent(_ color: UIColor) -> RenderTheme {
        RenderTheme(
            backgroundColor: backgroundColor,
            backgroundGradient: backgroundGradient,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            titleColor: titleColor,
            accentUIColor: color,
            panelBackgroundColor: panelBackgroundColor,
            showPanelBackground: showPanelBackground,
            separatorColor: separatorColor,
            showSeparators: showSeparators,
            heroFontSize: heroFontSize,
            dateFontSize: dateFontSize,
            titleFontSize: titleFontSize,
            titleBottomSpacing: titleBottomSpacing,
            bodyFontSize: bodyFontSize,
            lineSpacing: lineSpacing,
            panelSpacing: panelSpacing,
            panelPadding: panelPadding,
            panelCornerRadius: panelCornerRadius,
            margins: margins
        )
    }
}

// MARK: - Errors

enum RenderError: LocalizedError {
    case encodingFailed
    case invalidDimensions
    case panelRenderFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode the wallpaper image."
        case .invalidDimensions:
            return "Invalid wallpaper dimensions."
        case .panelRenderFailed(let panel):
            return "Failed to render panel: \(panel)"
        }
    }
}
