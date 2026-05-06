import Foundation
import SwiftData
import SQLite3

/// Centralizes the SwiftData ModelContainer used by both the main app and the
/// widget extension. Each process keeps a single cached container to avoid
/// re-opening SQLite on every widget tick / intent invocation.
enum SharedContainer {

    static let appGroupID = "group.com.lockscreenstudio.shared"

    static let schema = Schema([
        DashboardProject.self,
        WallpaperTemplate.self,
        PanelConfiguration.self,
        ThemeConfiguration.self,
        ExportPreset.self,
        TodoItem.self,
        PriorityItem.self,
        ExportHistoryItem.self,
    ])

    /// Process-wide cached container. Built lazily on first access.
    private static let cachedContainer: ModelContainer = buildContainer()

    static func makeModelContainer() -> ModelContainer { cachedContainer }

    // MARK: - Construction

    private static func buildContainer() -> ModelContainer {
        let storeURL = sharedStoreURL()
        // Migration is the main app's responsibility; the widget's sandbox can't
        // see the legacy app-only Application Support directory anyway.
        if isMainApp {
            migrateLegacyStoreIfNeeded(to: storeURL)
        }

        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Last-ditch fallback: keep the app usable but don't persist.
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let memContainer = try? ModelContainer(for: schema, configurations: [memConfig]) {
                return memContainer
            }
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static var isMainApp: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    private static func sharedStoreURL() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return groupURL.appendingPathComponent("LockScreenStudio.sqlite")
        }
        return URL.applicationSupportDirectory.appendingPathComponent("default.store")
    }

    // MARK: - Legacy migration

    /// On first launch after moving the SwiftData store into the App Group
    /// container, copy the legacy SQLite file so users keep their data.
    /// Skips work if the new store already exists.
    ///
    /// Safety:
    ///  - Checkpoints the legacy WAL into the main file before copying so the
    ///    copied database is self-consistent (no -wal / -shm needed).
    ///  - Copies to a temporary path then atomically renames into place so a
    ///    crash mid-copy can't leave a half-migrated store.
    private static func migrateLegacyStoreIfNeeded(to newURL: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: newURL.path) else { return }

        let legacyURL = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        guard fm.fileExists(atPath: legacyURL.path) else { return }

        checkpointWAL(at: legacyURL)

        // Copy main file to a temp path next to the destination, then atomically
        // rename. Any -wal / -shm sidecars are now obsolete (checkpointed) and
        // are intentionally skipped.
        let tempURL = newURL.appendingPathExtension("migrating")
        try? fm.removeItem(at: tempURL)
        do {
            try fm.copyItem(at: legacyURL, to: tempURL)
            try fm.moveItem(at: tempURL, to: newURL)
        } catch {
            try? fm.removeItem(at: tempURL)
        }
    }

    /// Force the SQLite WAL into the main file so it's safe to copy on its own.
    private static func checkpointWAL(at url: URL) {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return
        }
        defer { sqlite3_close(db) }
        sqlite3_exec(db, "PRAGMA wal_checkpoint(TRUNCATE);", nil, nil, nil)
    }
}
