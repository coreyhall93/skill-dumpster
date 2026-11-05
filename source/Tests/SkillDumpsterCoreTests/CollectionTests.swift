import Foundation
import Testing
@testable import SkillDumpsterCore

@Suite("Collections")
struct CollectionTests {
    private func skill(_ slug: String, kind: SkillKind = .claudePlugin, path: String? = nil) -> SkillRecord {
        SkillRecord(
            slug: slug,
            declaredName: slug,
            description: "",
            kind: kind,
            path: path ?? "/tmp/\(kind.rawValue)/\(slug)",
            skillFilePath: "",
            stats: SkillStats(fileCount: 1, byteCount: 1, modifiedAt: nil, contentHash: slug)
        )
    }

    @Test("adding is idempotent and removing works")
    func addAndRemove() {
        var collection = SkillCollection(name: "Daily")
        let a = skill("a")
        collection.add(a)
        collection.add(a)
        #expect(collection.members.count == 1)
        #expect(collection.contains(a))
        collection.remove(a)
        #expect(collection.members.isEmpty)
    }

    @Test("a member survives a plugin moving to a new version folder")
    func resolvesAcrossVersionFolders() {
        var collection = SkillCollection(name: "Design")
        collection.add(skill("tokens", path: "/plugins/design/1.0.0/skills/tokens"))

        let upgraded = skill("tokens", path: "/plugins/design/2.0.0/skills/tokens")
        let sameNameOtherSource = skill("tokens", kind: .custom, path: "/projects/tokens")

        let resolved = collection.resolve(in: [sameNameOtherSource, upgraded])
        #expect(resolved.map(\.path) == ["/plugins/design/2.0.0/skills/tokens"])
    }

    @Test("missing members are skipped, not dropped")
    func skipsMissingMembers() {
        var collection = SkillCollection(name: "Gone")
        collection.add(skill("ghost"))
        #expect(collection.resolve(in: []).isEmpty)
        #expect(collection.members.count == 1)
    }

    @Test("paths are stored relative to home")
    func storesTildePaths() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let reference = SkillReference(skill("x", path: home + "/.claude/skills/x"))
        #expect(reference.path == "~/.claude/skills/x")
        #expect(reference.matches(skill("x", path: home + "/.claude/skills/x")))
    }

    @Test("collections round-trip through the store")
    func roundTrips() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("collections.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }

        let store = CollectionStore(fileURL: file)
        #expect(try store.load().isEmpty)

        var collection = SkillCollection(name: "Writing")
        collection.add(skill("draft"))
        try store.save([collection])

        #expect(try store.load() == [collection])
    }

    @Test("a collection exports to a zip anywhere")
    func exportsArchive() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let skillDirectory = temporary.appendingPathComponent("source/packed", isDirectory: true)
        try FileManager.default.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        try "---\nname: packed\n---\n".write(to: skillDirectory.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        let skills = try SkillScanner(roots: [SkillRoot(url: skillDirectory.deletingLastPathComponent(), kind: .custom)]).scan()

        let destination = temporary.appendingPathComponent("out/My Pack.zip")
        let info = try BackupService(homeDirectory: temporary).writeArchive(skills: skills, to: destination)

        #expect(FileManager.default.fileExists(atPath: destination.path))
        #expect(info.byteCount > 0)
    }
}
