import AppKit
import Foundation
import SkillDumpsterCore

enum RummageSection: String, CaseIterable, Identifiable {
    case all = "All Skills"
    case local = "Codex Local"
    case claude = "Claude"
    case grok = "Grok"
    case sol = "Sol"
    case plugin = "Codex Plugins"
    case system = "Codex System"
    case fresh = "Fresh Trash"
    case tossed = "Tossed"

    var id: String { rawValue }

    static let sourceCases: [RummageSection] = [.all, .local, .claude, .grok, .sol, .plugin, .system]
    static let statusCases: [RummageSection] = [.fresh, .tossed]

    var symbolName: String {
        switch self {
        case .all: "archivebox"
        case .local: "internaldrive"
        case .claude: "sparkles.rectangle.stack"
        case .grok: "brain.head.profile"
        case .sol: "hammer"
        case .plugin: "shippingbox"
        case .system: "lock"
        case .fresh: "sparkles"
        case .tossed: "archivebox"
        }
    }

    var helpText: String {
        switch self {
        case .all:
            "Every skill from every scanned source."
        case .local:
            "Skills from local Codex skill folders."
        case .claude:
            "Skills from Claude skill and plugin folders."
        case .grok:
            "Skills from Grok local, bundled, and marketplace folders."
        case .sol:
            "Skills found under ~/Sol."
        case .plugin:
            "Skills shipped by installed Codex plugins."
        case .system:
            "Built-in Codex skills."
        case .fresh:
            "Fresh Trash means skills changed in the last 7 days."
        case .tossed:
            "Tossed means skills captured in the latest snapshot."
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var skills: [SkillRecord] = []
    @Published private(set) var snapshots: [SnapshotInfo] = []
    @Published private(set) var visibleSkills: [SkillRecord] = []
    @Published private(set) var selectedSkill: SkillRecord?
    @Published private(set) var sectionCounts: [RummageSection: Int] = [:]
    @Published private(set) var customBackupFolderURL: URL?
    @Published var selectedSection: RummageSection = .all {
        didSet {
            rebuildViewState()
        }
    }
    @Published var searchText = "" {
        didSet {
            rebuildViewState()
        }
    }
    @Published var statusMessage = "Rummaging through the dumpster."
    @Published var isRefreshing = false
    @Published var isBackingUp = false
    @Published var isHelpPresented = false
    @Published private(set) var backupSuccessTick = 0

    private let scanner = SkillScanner()
    private let userDefaults: UserDefaults
    private let backupFolderDefaultsKey = "SkillDumpsterBackupFolder"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let path = userDefaults.string(forKey: backupFolderDefaultsKey), !path.isEmpty {
            customBackupFolderURL = URL(fileURLWithPath: path, isDirectory: true)
        }
    }

    var skillSources: [SkillRoot] {
        scanner.roots
    }

    var backupFolderURL: URL? {
        try? makeBackupService().backupDirectory()
    }

    var isUsingCustomBackupFolder: Bool {
        customBackupFolderURL != nil
    }

    func refresh() async {
        isRefreshing = true
        statusMessage = "Rummaging through the heap."
        defer { isRefreshing = false }

        do {
            let scanner = self.scanner
            let backupService = makeBackupService()
            let scannedSkills = try await Task.detached {
                try scanner.scan()
            }.value
            let foundSnapshots = try await Task.detached {
                try backupService.snapshots()
            }.value

            skills = scannedSkills
            snapshots = foundSnapshots
            rebuildViewState()

            statusMessage = "Rummaged up \(skills.count) skills and \(snapshots.count) snapshots."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func backUpAllSkills() async {
        isBackingUp = true
        statusMessage = "Tossing \(skills.count) skills into a fresh snapshot."
        defer { isBackingUp = false }

        do {
            let currentSkills = skills
            let backupService = makeBackupService()
            let snapshot = try await Task.detached {
                try backupService.createSnapshot(skills: currentSkills)
            }.value

            snapshots = (try? backupService.snapshots()) ?? [snapshot]
            selectedSection = .tossed
            rebuildViewState()
            backupSuccessTick += 1
            statusMessage = "Tossed \(currentSkills.count) skills into \(snapshot.url.lastPathComponent)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func deleteSnapshot(_ snapshot: SnapshotInfo) async {
        do {
            let backupService = makeBackupService()
            try await Task.detached {
                try backupService.deleteSnapshot(snapshot)
            }.value

            snapshots = try backupService.snapshots()
            rebuildViewState()
            statusMessage = "Removed \(snapshot.url.lastPathComponent) from the heap."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func showHelp() {
        isHelpPresented = true
    }

    func select(_ skill: SkillRecord) {
        guard selectedSkill?.id != skill.id else { return }
        selectedSkill = skill
    }

    func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    func edit(_ skill: SkillRecord) {
        NSWorkspace.shared.open(URL(fileURLWithPath: skill.skillFilePath))
    }

    func revealSource(_ source: SkillRoot) {
        NSWorkspace.shared.open(source.url.resolvingSymlinksInPath())
    }

    func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    func openLatestSnapshot() {
        open(snapshots.first?.url)
    }

    func chooseBackupFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Backup Location"
        panel.message = "Skill Dumpster will store snapshots in this folder."
        panel.prompt = "Use This Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            customBackupFolderURL = url
            userDefaults.set(url.path, forKey: backupFolderDefaultsKey)
            statusMessage = "Backup location set to \(url.lastPathComponent)."
            Task { await refresh() }
        }
    }

    func useDefaultBackupFolder() {
        customBackupFolderURL = nil
        userDefaults.removeObject(forKey: backupFolderDefaultsKey)
        statusMessage = "Backup location reset to the default Sol folder."
        Task { await refresh() }
    }

    func count(for section: RummageSection) -> Int {
        sectionCounts[section, default: 0]
    }

    private func rebuildViewState() {
        sectionCounts = Dictionary(
            uniqueKeysWithValues: RummageSection.allCases.map { section in
                (section, skills.filter { matchesSection($0, section: section) }.count)
            }
        )

        let selectedID = selectedSkill?.id
        let nextVisibleSkills = skills.filter { skill in
            matchesSection(skill, section: selectedSection) && matchesSearch(skill)
        }

        visibleSkills = nextVisibleSkills

        if let selectedID,
           let preservedSelection = nextVisibleSkills.first(where: { $0.id == selectedID }) {
            selectedSkill = preservedSelection
        } else {
            selectedSkill = nextVisibleSkills.first
        }
    }

    private func makeBackupService() -> BackupService {
        BackupService(baseDirectoryOverride: customBackupFolderURL)
    }

    private func matchesSection(_ skill: SkillRecord, section: RummageSection) -> Bool {
        switch section {
        case .all:
            true
        case .local:
            skill.kind == .personal
        case .claude:
            skill.kind == .claude
        case .grok:
            skill.kind == .grok
        case .sol:
            skill.kind == .sol
        case .plugin:
            skill.kind == .plugin
        case .system:
            skill.kind == .system
        case .fresh:
            isFresh(skill)
        case .tossed:
            isInLatestSnapshot(skill)
        }
    }

    private func matchesSearch(_ skill: SkillRecord) -> Bool {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return true
        }

        let needle = trimmedSearch.lowercased()
        return skill.slug.lowercased().contains(needle)
            || skill.description.lowercased().contains(needle)
            || skill.kind.rawValue.lowercased().contains(needle)
            || skill.path.lowercased().contains(needle)
            || (skill.declaredName?.lowercased().contains(needle) ?? false)
    }

    private func isFresh(_ skill: SkillRecord) -> Bool {
        guard let modifiedAt = skill.stats.modifiedAt else { return false }
        return modifiedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
    }

    private func isInLatestSnapshot(_ skill: SkillRecord) -> Bool {
        guard let latest = snapshots.first else { return false }
        guard let modifiedAt = skill.stats.modifiedAt else { return true }
        return latest.createdAt >= modifiedAt
    }
}
