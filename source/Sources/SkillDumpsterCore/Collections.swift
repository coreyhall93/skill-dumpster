import Foundation

/// A pointer to a skill that survives plugin updates and other Macs.
///
/// Matching tries the exact path first (stored with `~` so it works under any
/// home folder), then falls back to the same folder name from the same source,
/// which is what changes when a plugin moves to a new version folder.
public struct SkillReference: Codable, Hashable, Sendable {
    public let path: String
    public let kind: SkillKind
    public let slug: String

    public init(path: String, kind: SkillKind, slug: String) {
        self.path = path
        self.kind = kind
        self.slug = slug
    }

    public init(_ skill: SkillRecord) {
        self.init(path: (skill.path as NSString).abbreviatingWithTildeInPath, kind: skill.kind, slug: skill.slug)
    }

    func matches(_ skill: SkillRecord) -> Bool {
        (path as NSString).expandingTildeInPath == skill.path
    }

    func looselyMatches(_ skill: SkillRecord) -> Bool {
        kind == skill.kind && slug == skill.slug
    }
}

/// A named, user-curated group of skills.
public struct SkillCollection: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var members: [SkillReference]

    public init(id: UUID = UUID(), name: String, members: [SkillReference] = []) {
        self.id = id
        self.name = name
        self.members = members
    }

    public func contains(_ skill: SkillRecord) -> Bool {
        members.contains { $0.matches(skill) } || members.contains { $0.looselyMatches(skill) }
    }

    /// The scanned skills this collection points at. Members that no longer
    /// exist on this Mac are skipped, not dropped from the file.
    public func resolve(in skills: [SkillRecord]) -> [SkillRecord] {
        var seen = Set<String>()
        return members.compactMap { member in
            let match = skills.first(where: member.matches) ?? skills.first(where: member.looselyMatches)
            guard let match, seen.insert(match.id).inserted else { return nil }
            return match
        }
    }

    public mutating func add(_ skill: SkillRecord) {
        guard !contains(skill) else { return }
        members.append(SkillReference(skill))
    }

    public mutating func remove(_ skill: SkillRecord) {
        members.removeAll { $0.matches(skill) || $0.looselyMatches(skill) }
    }
}

/// Reads and writes `collections.json`.
public struct CollectionStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    private struct File: Codable {
        var version = 1
        var collections: [SkillCollection]
    }

    public func load() throws -> [SkillCollection] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(File.self, from: data).collections
    }

    public func save(_ collections: [SkillCollection]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(File(collections: collections)).write(to: fileURL, options: .atomic)
    }
}
