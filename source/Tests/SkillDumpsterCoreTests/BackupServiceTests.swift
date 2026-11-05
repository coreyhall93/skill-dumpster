import Foundation
import Testing
@testable import SkillDumpsterCore

@Suite("Backup service")
struct BackupServiceTests {
    @Test("creates zip snapshots in the configured home")
    func createsSnapshotArchive() throws {
        let temporaryHome = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryHome) }

        let sourceSkill = temporaryHome.appendingPathComponent("source/example-skill", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceSkill, withIntermediateDirectories: true)
        try """
        ---
        name: example-skill
        description: Proof that the dumpster accepts offerings.
        ---
        """.write(to: sourceSkill.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let scanner = SkillScanner(roots: [SkillRoot(url: sourceSkill.deletingLastPathComponent(), kind: .agents)])
        let skills = try scanner.scan()
        let backupService = BackupService(homeDirectory: temporaryHome)

        let snapshot = try backupService.createSnapshot(skills: skills)

        #expect(FileManager.default.fileExists(atPath: snapshot.url.path))
        #expect(snapshot.url.path.contains("Documents/Skill Dumpster/Snapshots"))
        #expect(snapshot.byteCount > 0)

        try backupService.deleteSnapshot(snapshot)
        #expect(!FileManager.default.fileExists(atPath: snapshot.url.path))
    }

    @Test("defaults to ~/Documents/Skill Dumpster")
    func defaultsToDocumentsFolder() throws {
        let temporaryHome = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryHome) }

        let snapshots = try BackupService(homeDirectory: temporaryHome).snapshotDirectory()

        #expect(snapshots.path == temporaryHome.appendingPathComponent("Documents/Skill Dumpster/Snapshots").path)
        #expect(FileManager.default.fileExists(atPath: snapshots.path))
    }

    @Test("uses a custom backup directory when configured")
    func usesCustomBackupDirectory() throws {
        let temporaryHome = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryHome) }

        let customBackupDirectory = temporaryHome.appendingPathComponent("Custom Backups", isDirectory: true)
        let backupService = BackupService(
            homeDirectory: temporaryHome,
            baseDirectoryOverride: customBackupDirectory
        )

        let snapshots = try backupService.snapshotDirectory()

        #expect(snapshots.path == customBackupDirectory.appendingPathComponent("Snapshots").path)
        #expect(FileManager.default.fileExists(atPath: snapshots.path))
    }
}
