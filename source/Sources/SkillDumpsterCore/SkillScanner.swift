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

    public static func defaultRoots(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [SkillRoot] {
        [
            SkillRoot(url: homeDirectory.appendingPathComponent(".agents/skills"), kind: .personal),
            SkillRoot(url: homeDirectory.appendingPathComponent(".codex/skills"), kind: .personal),
            SkillRoot(url: homeDirectory.appendingPathComponent(".codex/skills/.system"), kind: .system),
            SkillRoot(url: homeDirectory.appendingPathComponent(".codex/plugins/cache"), kind: .plugin, recursive: true),
            SkillRoot(url: homeDirectory.appendingPathComponent(".claude/skills"), kind: .claude),
            SkillRoot(url: homeDirectory.appendingPathComponent(".claude/plugins"), kind: .claude, recursive: true),
            SkillRoot(url: homeDirectory.appendingPathComponent(".grok/skills"), kind: .grok),
            SkillRoot(url: homeDirectory.appendingPathComponent(".grok/bundled/skills"), kind: .grok),
            SkillRoot(url: homeDirectory.appendingPathComponent(".grok/marketplace-cache"), kind: .grok, recursive: true),
            SkillRoot(
                url: homeDirectory.appendingPathComponent("Sol"),
                kind: .sol,
                recursive: true,
                includeHiddenDirectories: true
            )
        ]
    }

    public func scan() throws -> [SkillRecord] {
        var skillURLs: [URL: SkillKind] = [:]

        for root in roots where fileManager.fileExists(atPath: root.url.path) {
            let rootURL = root.url.resolvingSymlinksInPath()
            if root.recursive {
                for url in recursiveSkillDirectories(
                    in: rootURL,
                    includeHiddenDirectories: root.includeHiddenDirectories
                ) {
                    skillURLs[url] = root.kind
                }
            } else {
                for url in directSkillDirectories(in: rootURL, kind: root.kind) {
                    skillURLs[url] = root.kind
                }
            }
        }

        return try skillURLs
            .map { try readSkill(at: $0.key, kind: $0.value) }
            .sorted {
                if $0.kind == $1.kind {
                    return $0.slug.localizedCaseInsensitiveCompare($1.slug) == .orderedAscending
                }
                return $0.kind.sortOrder < $1.kind.sortOrder
            }
    }

    private func directSkillDirectories(in root: URL, kind: SkillKind) -> [URL] {
        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        return children.compactMap { child in
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDirectory else { return nil }

            if child.lastPathComponent == ".system", kind == .personal {
                return nil
            }

            let skillFile = child.appendingPathComponent("SKILL.md")
            return fileManager.fileExists(atPath: skillFile.path) ? child.standardizedFileURL : nil
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
            if values?.isDirectory == true,
               Self.prunedRecursiveDirectoryNames.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            let skillFile = url.appendingPathComponent("SKILL.md")
            if fileManager.fileExists(atPath: skillFile.path) {
                results.append(url.standardizedFileURL)
                enumerator.skipDescendants()
            }
        }
        return results
    }

    private func readSkill(at directory: URL, kind: SkillKind) throws -> SkillRecord {
        let skillFile = directory.appendingPathComponent("SKILL.md")
        let contents = try String(contentsOf: skillFile, encoding: .utf8)
        let metadata = SkillScanner.parseSkillMarkdown(contents)
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
