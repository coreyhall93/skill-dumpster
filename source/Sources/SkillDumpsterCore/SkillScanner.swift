import CryptoKit
import Foundation

public struct SkillScanner: @unchecked Sendable {
    public let roots: [SkillRoot]
    public let fileManager: FileManager

    public init(
        roots: [SkillRoot] = SkillScanner.defaultRoots(),
        fileManager: FileManager = .default
    ) {
        self.roots = roots
        self.fileManager = fileManager
    }

    /// The folders every agent install is expected to use. Missing folders are skipped.
    public static func defaultRoots(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) -> [SkillRoot] {
        func root(_ path: String, _ kind: SkillKind, recursive: Bool = false) -> SkillRoot {
            SkillRoot(url: homeDirectory.appendingPathComponent(path), kind: kind, recursive: recursive)
        }

        return [root(".agents/skills", .agents)]
            + [root(".claude/skills", .claude)]
            + claudePluginRoots(homeDirectory: homeDirectory, fileManager: fileManager)
            + [
                root(".codex/skills", .codex),
                root(".codex/skills/.system", .codexSystem),
                root(".codex/plugins/cache", .codexPlugin, recursive: true),
                root(".grok/skills", .grok),
                root(".grok/bundled/skills", .grok),
                root(".grok/marketplace-cache", .grok, recursive: true)
            ]
    }

    /// Roots for folders the user adds by hand. These are searched deeply,
    /// including hidden project folders such as `.claude/skills`.
    public static func customRoot(_ url: URL) -> SkillRoot {
        SkillRoot(url: url, kind: .custom, recursive: true, includeHiddenDirectories: true)
    }

    /// Claude Code keeps marketplace catalogs and every cached plugin version under
    /// `~/.claude/plugins`. Only the install paths listed in `installed_plugins.json`
    /// are live, so scan those and fall back to the cache when the manifest is missing.
    static func claudePluginRoots(homeDirectory: URL, fileManager: FileManager) -> [SkillRoot] {
        let pluginsDirectory = homeDirectory.appendingPathComponent(".claude/plugins", isDirectory: true)
        let manifestURL = pluginsDirectory.appendingPathComponent("installed_plugins.json")

        struct Manifest: Decodable {
            struct Install: Decodable { let installPath: String }
            let plugins: [String: [Install]]
        }

        guard let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            return [SkillRoot(url: pluginsDirectory.appendingPathComponent("cache"), kind: .claudePlugin, recursive: true)]
        }

        let installPaths = Set(manifest.plugins.values.flatMap { $0.map(\.installPath) })
        return installPaths.sorted().map {
            SkillRoot(url: URL(fileURLWithPath: $0, isDirectory: true), kind: .claudePlugin, recursive: true)
        }
    }

    public func scan() throws -> [SkillRecord] {
        // One entry per real folder. Roots are visited in order, so a skill symlinked
        // into several agent folders is credited to the first root that reaches it.
        var claimed: [String: SkillKind] = [:]
        var order: [String] = []

        for root in roots where fileManager.fileExists(atPath: root.url.path) {
            let rootURL = root.url.resolvingSymlinksInPath()
            let found = root.recursive
                ? recursiveSkillDirectories(in: rootURL, includeHiddenDirectories: root.includeHiddenDirectories)
                : directSkillDirectories(in: rootURL)

            for url in found {
                let realPath = url.resolvingSymlinksInPath().standardizedFileURL.path
                guard claimed[realPath] == nil else { continue }
                claimed[realPath] = root.kind
                order.append(realPath)
            }
        }

        let records = order.compactMap { path -> SkillRecord? in
            guard let kind = claimed[path] else { return nil }
            return try? readSkill(at: URL(fileURLWithPath: path, isDirectory: true), kind: kind)
        }

        return Self.collapsingCopies(records)
            .sorted {
                let comparison = $0.displayName.localizedCaseInsensitiveCompare($1.displayName)
                if comparison == .orderedSame {
                    return $0.kind.sortOrder < $1.kind.sortOrder
                }
                return comparison == .orderedAscending
            }
    }

    /// Byte-identical copies of the same skill (plugin caches, vendored copies)
    /// collapse into one record that remembers where the other copies live.
    static func collapsingCopies(_ records: [SkillRecord]) -> [SkillRecord] {
        var firstIndex: [String: Int] = [:]
        var result: [SkillRecord] = []

        for record in records {
            let key = "\(record.slug)\u{0}\(record.stats.contentHash)"
            if let index = firstIndex[key] {
                result[index].duplicatePaths.append(record.path)
            } else {
                firstIndex[key] = result.count
                result.append(record)
            }
        }
        return result
    }

    private func directSkillDirectories(in root: URL) -> [URL] {
        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        // Follows symlinked skill folders, which is how most skill installers link
        // one copy into several agents.
        return children.filter { child in
            fileManager.fileExists(atPath: child.appendingPathComponent("SKILL.md").path)
        }
    }

    private func recursiveSkillDirectories(in root: URL, includeHiddenDirectories: Bool) -> [URL] {
        let options: FileManager.DirectoryEnumerationOptions = includeHiddenDirectories
            ? [.skipsPackageDescendants]
            : [.skipsHiddenFiles, .skipsPackageDescendants]

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: options
        ) else {
            return []
        }

        var results: [URL] = []
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { continue }

            if Self.prunedRecursiveDirectoryNames.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            if fileManager.fileExists(atPath: url.appendingPathComponent("SKILL.md").path) {
                results.append(url.standardizedFileURL)
                enumerator.skipDescendants()
            }
        }
        return results
    }

    private func readSkill(at directory: URL, kind: SkillKind) throws -> SkillRecord {
        let skillFile = directory.appendingPathComponent("SKILL.md")
        let data = try Data(contentsOf: skillFile)
        let metadata = SkillScanner.parseSkillMarkdown(String(decoding: data, as: UTF8.self))
        let stats = try collectStats(for: directory)

        return SkillRecord(
            slug: directory.lastPathComponent,
            declaredName: metadata.name,
            description: metadata.description,
            kind: kind,
            path: directory.path,
            skillFilePath: skillFile.path,
            stats: stats
        )
    }

    public static func parseSkillMarkdown(_ markdown: String) -> (name: String?, description: String) {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var name: String?
        var description: String?

        if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
           let endIndex = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---" }) {
            let frontMatter = lines[1..<endIndex]

            var index = frontMatter.startIndex
            while index < frontMatter.endIndex {
                let line = frontMatter[index]

                if let value = yamlValue(from: line, key: "name") {
                    name = value
                } else if let value = yamlValue(from: line, key: "description") {
                    if value == ">" || value == "|" {
                        let block = yamlBlockValue(
                            in: frontMatter,
                            after: index,
                            folded: value == ">"
                        )
                        description = block.value
                        index = block.nextIndex
                        continue
                    } else {
                        description = value
                    }
                }

                index = frontMatter.index(after: index)
            }
        }

        let fallbackDescription = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { line in
                !line.isEmpty && !line.hasPrefix("---") && !line.hasPrefix("#") && !line.contains(":")
            }

        return (
            name: name,
            description: description ?? fallbackDescription ?? "No description found in SKILL.md."
        )
    }

    private static func yamlValue(from line: String, key: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("\(key.lowercased()):") else {
            return nil
        }

        let rawValue = trimmed.dropFirst(key.count + 1)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private static func yamlBlockValue(
        in lines: ArraySlice<String>,
        after index: ArraySlice<String>.Index,
        folded: Bool
    ) -> (value: String, nextIndex: ArraySlice<String>.Index) {
        var cursor = lines.index(after: index)
        var blockLines: [String] = []

        while cursor < lines.endIndex {
            let line = lines[cursor]
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let isContinuation = line.hasPrefix(" ") || line.hasPrefix("\t") || trimmed.isEmpty

            guard isContinuation else { break }

            if !trimmed.isEmpty {
                blockLines.append(trimmed)
            }
            cursor = lines.index(after: cursor)
        }

        return (
            folded ? blockLines.joined(separator: " ") : blockLines.joined(separator: "\n"),
            cursor
        )
    }

    private static let prunedRecursiveDirectoryNames: Set<String> = [
        ".build",
        ".cache",
        ".direnv",
        ".git",
        ".mypy_cache",
        ".next",
        ".nuxt",
        ".pytest_cache",
        ".ruff_cache",
        ".swiftpm",
        ".turbo",
        ".venv",
        ".vscode",
        "DerivedData",
        "Pods",
        "build",
        "dist",
        "node_modules",
        "target",
        "vendor"
    ]

    private func collectStats(for directory: URL) throws -> SkillStats {
        var files: [(url: URL, relativePath: String)] = []
        var byteCount: Int64 = 0
        var modifiedAt: Date?

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsPackageDescendants]
        ) else {
            return SkillStats(fileCount: 0, byteCount: 0, modifiedAt: nil, contentHash: "")
        }

        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
            guard values.isRegularFile == true else { continue }

            let relative = url.path.replacingOccurrences(of: directory.path + "/", with: "")
            files.append((url, relative))
            byteCount += Int64(values.fileSize ?? 0)

            if let modified = values.contentModificationDate {
                modifiedAt = max(modifiedAt ?? modified, modified)
            }
        }

        return SkillStats(
            fileCount: files.count,
            byteCount: byteCount,
            modifiedAt: modifiedAt,
            contentHash: try hash(files: files)
        )
    }

    private func hash(files: [(url: URL, relativePath: String)]) throws -> String {
        var hasher = SHA256()

        for file in files.sorted(by: { $0.relativePath < $1.relativePath }) {
            hasher.update(data: Data(file.relativePath.utf8))
            hasher.update(data: try Data(contentsOf: file.url))
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
