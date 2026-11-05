import Foundation

public enum BackupError: LocalizedError {
    case noSkills
    case archiveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noSkills:
            return "No skills were found to back up."
        case .archiveFailed(let message):
            return "Snapshot archive failed: \(message)"
        }
    }
}

public struct BackupService: @unchecked Sendable {
    public let fileManager: FileManager
    public let homeDirectory: URL
    public let baseDirectoryOverride: URL?

    public init(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil,
        baseDirectoryOverride: URL? = nil
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        self.baseDirectoryOverride = baseDirectoryOverride
    }

    /// Where snapshots go when the user hasn't picked a folder.
    public static func defaultBackupDirectory(homeDirectory: URL) -> URL {
        homeDirectory.appendingPathComponent("Documents/Skill Dumpster", isDirectory: true)
    }

    public func backupDirectory() throws -> URL {
        if let baseDirectoryOverride {
            try fileManager.createDirectory(at: baseDirectoryOverride, withIntermediateDirectories: true)
            return baseDirectoryOverride
        }

        let backupDirectory = Self.defaultBackupDirectory(homeDirectory: homeDirectory)
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        return backupDirectory
    }

    public func snapshotDirectory() throws -> URL {
        let snapshots = try backupDirectory()
            .appendingPathComponent("Snapshots", isDirectory: true)

        try fileManager.createDirectory(at: snapshots, withIntermediateDirectories: true)
        return snapshots
    }

    public func snapshots() throws -> [SnapshotInfo] {
        let directory = try snapshotDirectory()
        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return try files
            .filter { $0.pathExtension.lowercased() == "zip" }
            .map { url in
                let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                return SnapshotInfo(
                    url: url,
                    createdAt: values.contentModificationDate ?? .distantPast,
                    byteCount: Int64(values.fileSize ?? 0)
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func deleteSnapshot(_ snapshot: SnapshotInfo) throws {
        guard fileManager.fileExists(atPath: snapshot.url.path) else { return }
        try fileManager.removeItem(at: snapshot.url)
    }

    public func createSnapshot(skills: [SkillRecord]) throws -> SnapshotInfo {
        let stamp = SkillFormatting.snapshotDateFormatter.string(from: Date())
        let archiveURL = try snapshotDirectory().appendingPathComponent("skill-dumpster-\(stamp).zip")
        return try writeArchive(skills: skills, to: archiveURL)
    }

    /// Zips the given skills plus a manifest to any location, such as a
    /// collection exported for sharing.
    @discardableResult
    public func writeArchive(skills: [SkillRecord], to archiveURL: URL) throws -> SnapshotInfo {
        guard !skills.isEmpty else { throw BackupError.noSkills }

        let rootName = archiveURL.deletingPathExtension().lastPathComponent
        let stagingParent = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stagingURL = stagingParent.appendingPathComponent(rootName, isDirectory: true)
        try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: stagingParent) }

        let manifest = SnapshotManifest(
            appName: "Skill Dumpster",
            snapshotDate: Date(),
            sourceHome: homeDirectory.path,
            skills: skills
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: stagingURL.appendingPathComponent("manifest.json"))

        let skillsRoot = stagingURL.appendingPathComponent("Skills", isDirectory: true)
        try fileManager.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        for skill in skills {
            let kindDirectory = skillsRoot.appendingPathComponent(skill.kind.rawValue, isDirectory: true)
            try fileManager.createDirectory(at: kindDirectory, withIntermediateDirectories: true)

            var destinationURL = kindDirectory.appendingPathComponent(skill.slug, isDirectory: true)
            if fileManager.fileExists(atPath: destinationURL.path) {
                destinationURL = kindDirectory.appendingPathComponent(
                    "\(skill.slug)-\(SkillFormatting.compactHash(skill.stats.contentHash))",
                    isDirectory: true
                )
            }
            try fileManager.copyItem(at: URL(fileURLWithPath: skill.path), to: destinationURL)
        }

        try fileManager.createDirectory(at: archiveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }
        try archive(stagingURL: stagingURL, archiveURL: archiveURL)

        let values = try archiveURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        return SnapshotInfo(
            url: archiveURL,
            createdAt: values.contentModificationDate ?? Date(),
            byteCount: Int64(values.fileSize ?? 0)
        )
    }

    private func archive(stagingURL: URL, archiveURL: URL) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", stagingURL.path, archiveURL.path]
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw BackupError.archiveFailed(message ?? "ditto exited with \(process.terminationStatus)")
        }
    }
}
