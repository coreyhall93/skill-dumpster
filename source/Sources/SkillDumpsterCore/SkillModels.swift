import Foundation

public enum SkillKind: String, Codable, CaseIterable, Sendable {
    case personal = "Codex Local"
    case claude = "Claude"
    case grok = "Grok"
    case sol = "Sol"
    case system = "Codex System"
    case plugin = "Codex Plugins"

    public var isManaged: Bool {
        switch self {
        case .system, .plugin:
            return true
        case .personal, .claude, .grok, .sol:
            return false
        }
    }

    public var sortOrder: Int {
        switch self {
        case .personal:
            return 0
        case .claude:
            return 1
        case .grok:
            return 2
        case .sol:
            return 3
        case .plugin:
            return 4
        case .system:
            return 5
        }
    }
}

public struct SkillRoot: Hashable, Sendable {
    public let url: URL
    public let kind: SkillKind
    public let recursive: Bool
    public let includeHiddenDirectories: Bool

    public init(
        url: URL,
        kind: SkillKind,
        recursive: Bool = false,
        includeHiddenDirectories: Bool = false
    ) {
        self.url = url
        self.kind = kind
        self.recursive = recursive
        self.includeHiddenDirectories = includeHiddenDirectories
    }
}

public struct SkillStats: Codable, Hashable, Sendable {
    public let fileCount: Int
    public let byteCount: Int64
    public let modifiedAt: Date?
    public let contentHash: String

    public init(fileCount: Int, byteCount: Int64, modifiedAt: Date?, contentHash: String) {
        self.fileCount = fileCount
        self.byteCount = byteCount
        self.modifiedAt = modifiedAt
        self.contentHash = contentHash
    }
}

public struct SkillRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: String { path }

    public let slug: String
    public let declaredName: String?
    public let description: String
    public let kind: SkillKind
    public let path: String
    public let skillFilePath: String
    public let stats: SkillStats

    public init(
        slug: String,
        declaredName: String?,
        description: String,
        kind: SkillKind,
        path: String,
        skillFilePath: String,
        stats: SkillStats
    ) {
        self.slug = slug
        self.declaredName = declaredName
        self.description = description
        self.kind = kind
        self.path = path
        self.skillFilePath = skillFilePath
        self.stats = stats
    }
}

public struct SnapshotInfo: Identifiable, Hashable, Sendable {
    public var id: String { url.path }

    public let url: URL
    public let createdAt: Date
    public let byteCount: Int64

    public init(url: URL, createdAt: Date, byteCount: Int64) {
        self.url = url
        self.createdAt = createdAt
        self.byteCount = byteCount
    }
}

public struct SnapshotManifest: Codable, Sendable {
    public let appName: String
    public let snapshotDate: Date
    public let sourceHome: String
    public let skills: [SkillRecord]

    public init(appName: String, snapshotDate: Date, sourceHome: String, skills: [SkillRecord]) {
        self.appName = appName
        self.snapshotDate = snapshotDate
        self.sourceHome = sourceHome
        self.skills = skills
    }
}
