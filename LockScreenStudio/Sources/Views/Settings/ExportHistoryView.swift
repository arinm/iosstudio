import SwiftUI
import SwiftData

struct ExportHistoryView: View {
    @Query(sort: \ExportHistoryItem.createdAt, order: .reverse)
    private var historyItems: [ExportHistoryItem]

    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirm = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if historyItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(historyItems) { item in
                            historyCard(item)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Export History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !historyItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        showClearConfirm = true
                    }
                }
            }
        }
        .confirmationDialog("Clear all export history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                for item in historyItems {
                    modelContext.delete(item)
                }
                try? modelContext.save()
            }
        }
    }

    private func historyCard(_ item: ExportHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let uiImage = UIImage(data: item.thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(item.templateName)
                .font(.caption2.bold())
                .lineLimit(1)
            Text(item.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(.secondary)
            Text("No exports yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        ExportHistoryView()
    }
}
