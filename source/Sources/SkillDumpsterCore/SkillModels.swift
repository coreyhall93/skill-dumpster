import Foundation

/// Where a skill was found. Inferred from the scanned folder, never edited by hand.
public enum SkillKind: String, Codable, CaseIterable, Sendable {
    case agents = "Shared"
    case claude = "Claude"
    case claudePlugin = "Claude Plugins"
    case codex = "Codex"
    case codexPlugin = "Codex Plugins"
    case codexSystem = "Codex System"
    case grok = "Grok"
    case custom = "Custom Folders"

    /// Plugin and built-in skills live on disk but are owned by an installer,
    /// so local edits can be overwritten.
    public var isManaged: Bool {
        switch self {
        case .claudePlugin, .codexPlugin, .codexSystem:
            true
        case .agents, .claude, .codex, .grok, .custom:
            false
        }
    }

    public var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    public var summary: String {
        switch self {
        case .agents: "Cross-agent skills in ~/.agents/skills."
        case .claude: "Personal Claude Code skills."
        case .claudePlugin: "Skills from installed Claude Code plugins."
        case .codex: "Personal Codex skills."
        case .codexPlugin: "Skills from installed Codex plugins."
        case .codexSystem: "Skills built into Codex."
        case .grok: "Grok local, bundled, and marketplace skills."
        case .custom: "Folders you added in Settings."
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
    /// Other folders holding a byte-identical copy of this skill.
    public var duplicatePaths: [String]

    public init(
        slug: String,
        declaredName: String?,
        description: String,
        kind: SkillKind,
        path: String,
        skillFilePath: String,
        stats: SkillStats,
        duplicatePaths: [String] = []
    ) {
        self.slug = slug
        self.declaredName = declaredName
        self.description = description
        self.kind = kind
        self.path = path
        self.skillFilePath = skillFilePath
        self.stats = stats
        self.duplicatePaths = duplicatePaths
    }

    /// The name to show: the front matter `name` when present, else the folder name.
    public var displayName: String {
        guard let declaredName, !declaredName.isEmpty else { return slug }
        return declaredName
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
