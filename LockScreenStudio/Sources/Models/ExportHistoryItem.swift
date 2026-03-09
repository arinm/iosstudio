import Foundation
import SwiftData

@Model
final class ExportHistoryItem {
    var id: UUID
    var createdAt: Date
    var thumbnailData: Data
    var devicePresetName: String
    var templateName: String
    var resolution: String

    init(
        thumbnailData: Data,
        devicePresetName: String,
        templateName: String,
        resolution: String
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.thumbnailData = thumbnailData
        self.devicePresetName = devicePresetName
        self.templateName = templateName
        self.resolution = resolution
    }
}
