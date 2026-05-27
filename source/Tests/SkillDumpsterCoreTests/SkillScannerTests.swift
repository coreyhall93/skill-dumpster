import Foundation
import Testing
@testable import SkillDumpsterCore

@Suite("Skill scanner")
struct SkillScannerTests {
    @Test("parses front matter name and description")
    func parsesFrontMatter() {
        let markdown = """
        ---
        name: skill-dumpster
        description: Keep precious Codex skills out of the void.
        ---

        # Body
        """

        let parsed = SkillScanner.parseSkillMarkdown(markdown)

        #expect(parsed.name == "skill-dumpster")
        #expect(parsed.description == "Keep precious Codex skills out of the void.")
    }

    @Test("parses folded front matter descriptions")
    func parsesFoldedFrontMatterDescription() {
        let markdown = """
        ---
        name: queue-quickhits
        description: >
          Start-of-shift tool: scans the queue
          and surfaces quick wins.
        user-invokable: true
        ---
        """

        let parsed = SkillScanner.parseSkillMarkdown(markdown)

        #expect(parsed.name == "queue-quickhits")
        #expect(parsed.description == "Start-of-shift tool: scans the queue and surfaces quick wins.")
    }

    @Test("scans direct skill folders")
    func scansDirectSkillFolders() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let skillDirectory = temporary.appendingPathComponent("tiny-skill", isDirectory: true)
        try FileManager.default.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        try """
        ---
        name: tiny-skill
        description: A small skill for testing.
        ---
        """.write(to: skillDirectory.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let scanner = SkillScanner(roots: [SkillRoot(url: temporary, kind: .personal)])
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "tiny-skill")
        #expect(skills.first?.kind == .personal)
        #expect(skills.first?.stats.fileCount == 1)
    }

    @Test("scans recursive symlink roots")
    func scansRecursiveSymlinkRoots() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let realRoot = temporary.appendingPathComponent("real-root", isDirectory: true)
        let symlinkRoot = temporary.appendingPathComponent("linked-root", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let skillDirectory = realRoot.appendingPathComponent("project/example-skill", isDirectory: true)
        try FileManager.default.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        try """
        ---
        name: example-skill
        description: Found through a symlinked root.
        ---
        """.write(to: skillDirectory.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try FileManager.default.createSymbolicLink(at: symlinkRoot, withDestinationURL: realRoot)

        let scanner = SkillScanner(roots: [SkillRoot(url: symlinkRoot, kind: .developer, recursive: true)])
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "example-skill")
        #expect(skills.first?.kind == .developer)
    }

    @Test("can scan hidden skill folders in recursive roots")
    func scansHiddenSkillFoldersWhenRequested() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let skillDirectory = temporary.appendingPathComponent("project/.claude/skills/hidden-skill", isDirectory: true)
        try FileManager.default.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        try """
        ---
        name: hidden-skill
        description: Found inside a hidden project skill folder.
        ---
        """.write(to: skillDirectory.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let scanner = SkillScanner(
            roots: [
                SkillRoot(
                    url: temporary,
                    kind: .developer,
                    recursive: true,
                    includeHiddenDirectories: true
                )
            ]
        )
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "hidden-skill")
        #expect(skills.first?.kind == .developer)
    }

    @Test("default roots include Codex, Claude, Grok, and Developer sources")
    func defaultRootsIncludeKnownAgentSources() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
        let roots = SkillScanner.defaultRoots(homeDirectory: home)

        let rootMap = Dictionary(uniqueKeysWithValues: roots.map { ($0.url.path, $0.kind) })

        #expect(rootMap["/Users/example/.agents/skills"] == .personal)
        #expect(rootMap["/Users/example/.codex/skills"] == .personal)
        #expect(rootMap["/Users/example/.codex/skills/.system"] == .system)
        #expect(rootMap["/Users/example/.codex/plugins/cache"] == .plugin)
        #expect(rootMap["/Users/example/.claude/skills"] == .claude)
        #expect(rootMap["/Users/example/.claude/plugins"] == .claude)
        #expect(rootMap["/Users/example/.grok/skills"] == .grok)
        #expect(rootMap["/Users/example/.grok/bundled/skills"] == .grok)
        #expect(rootMap["/Users/example/.grok/marketplace-cache"] == .grok)
        #expect(rootMap["/Users/example/Developer"] == .developer)
        #expect(roots.first { $0.url.path == "/Users/example/Developer" }?.includeHiddenDirectories == true)
    }
}
