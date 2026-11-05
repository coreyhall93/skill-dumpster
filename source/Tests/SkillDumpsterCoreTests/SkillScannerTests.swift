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

        let scanner = SkillScanner(roots: [SkillRoot(url: temporary, kind: .agents)])
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "tiny-skill")
        #expect(skills.first?.kind == .agents)
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

        let scanner = SkillScanner(roots: [SkillRoot(url: symlinkRoot, kind: .custom, recursive: true)])
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "example-skill")
        #expect(skills.first?.kind == .custom)
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
                    kind: .custom,
                    recursive: true,
                    includeHiddenDirectories: true
                )
            ]
        )
        let skills = try scanner.scan()

        #expect(skills.count == 1)
        #expect(skills.first?.slug == "hidden-skill")
        #expect(skills.first?.kind == .custom)
    }

    @Test("default roots cover the common agent folders")
    func defaultRootsIncludeKnownAgentSources() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
        let roots = SkillScanner.defaultRoots(homeDirectory: home)
        let rootMap = Dictionary(uniqueKeysWithValues: roots.map { ($0.url.path, $0.kind) })

        #expect(rootMap["/Users/example/.agents/skills"] == .agents)
        #expect(rootMap["/Users/example/.claude/skills"] == .claude)
        #expect(rootMap["/Users/example/.claude/plugins/cache"] == .claudePlugin)
        #expect(rootMap["/Users/example/.codex/skills"] == .codex)
        #expect(rootMap["/Users/example/.codex/skills/.system"] == .codexSystem)
        #expect(rootMap["/Users/example/.codex/plugins/cache"] == .codexPlugin)
        #expect(rootMap["/Users/example/.grok/skills"] == .grok)
        #expect(rootMap["/Users/example/.grok/bundled/skills"] == .grok)
        #expect(rootMap["/Users/example/.grok/marketplace-cache"] == .grok)
    }

    @Test("scans only installed Claude plugins when the manifest exists")
    func scansInstalledClaudePlugins() throws {
        let home = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: home) }

        let plugins = home.appendingPathComponent(".claude/plugins", isDirectory: true)
        let installed = plugins.appendingPathComponent("cache/market/tool/2.0.0", isDirectory: true)
        let stale = plugins.appendingPathComponent("cache/market/tool/1.0.0", isDirectory: true)
        let catalog = plugins.appendingPathComponent("marketplaces/market/tool", isDirectory: true)
        try writeSkill(named: "tool-skill", in: installed.appendingPathComponent("skills"), body: "v2")
        try writeSkill(named: "tool-skill", in: stale.appendingPathComponent("skills"), body: "v1")
        try writeSkill(named: "tool-skill", in: catalog.appendingPathComponent("skills"), body: "catalog")
        try """
        {"version": 2, "plugins": {"tool@market": [{"installPath": "\(installed.path)"}]}}
        """.write(to: plugins.appendingPathComponent("installed_plugins.json"), atomically: true, encoding: .utf8)

        let roots = SkillScanner.defaultRoots(homeDirectory: home)
        let skills = try SkillScanner(roots: roots).scan()

        #expect(skills.count == 1)
        #expect(skills.first?.kind == .claudePlugin)
        #expect(skills.first?.path.contains("2.0.0") == true)
    }

    @Test("a symlinked skill is counted once, under the first root that reaches it")
    func dedupesSymlinkedSkills() throws {
        let temporary = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }

        let shared = temporary.appendingPathComponent("agents", isDirectory: true)
        let claude = temporary.appendingPathComponent("claude", isDirectory: true)
        try writeSkill(named: "linked", in: shared)
        try FileManager.default.createDirectory(at: claude, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: claude.appendingPathComponent("linked"),
            withDestinationURL: shared.appendingPathComponent("linked")
        )

        let skills = try SkillScanner(roots: [
            SkillRoot(url: shared, kind: .agents),
            SkillRoot(url: claude, kind: .claude)
        ]).scan()

        #expect(skills.count == 1)
        #expect(skills.first?.kind == .agents)
    }

    @Test("symlinked skill folders are found in direct roots")
    func followsSymlinkedSkillFolders() throws {
        let temporary = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }

        let elsewhere = temporary.appendingPathComponent("elsewhere", isDirectory: true)
        let claude = temporary.appendingPathComponent("claude", isDirectory: true)
        try writeSkill(named: "remote", in: elsewhere)
        try FileManager.default.createDirectory(at: claude, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: claude.appendingPathComponent("remote"),
            withDestinationURL: elsewhere.appendingPathComponent("remote")
        )

        let skills = try SkillScanner(roots: [SkillRoot(url: claude, kind: .claude)]).scan()

        #expect(skills.map(\.slug) == ["remote"])
        #expect(skills.first?.kind == .claude)
    }

    @Test("identical copies collapse into one record")
    func collapsesIdenticalCopies() throws {
        let temporary = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }

        try writeSkill(named: "twin", in: temporary.appendingPathComponent("a"))
        try writeSkill(named: "twin", in: temporary.appendingPathComponent("b"))
        try writeSkill(named: "twin", in: temporary.appendingPathComponent("c"), body: "different")

        let skills = try SkillScanner(roots: [
            SkillRoot(url: temporary, kind: .custom, recursive: true)
        ]).scan()

        #expect(skills.count == 2)
        #expect(skills.contains { $0.duplicatePaths.count == 1 })
    }

    @Test("hidden folders in direct roots are ignored")
    func ignoresHiddenFoldersInDirectRoots() throws {
        let temporary = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }

        try writeSkill(named: ".trash", in: temporary)
        try writeSkill(named: "visible", in: temporary)

        let skills = try SkillScanner(roots: [SkillRoot(url: temporary, kind: .claude)]).scan()

        #expect(skills.map(\.slug) == ["visible"])
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeSkill(named name: String, in parent: URL, body: String = "") throws {
        let directory = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try """
        ---
        name: \(name)
        description: Test skill.
        ---
        \(body)
        """.write(to: directory.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }
}
