import AppKit
import Foundation
import Observation
import SkillDumpsterCore
import UniformTypeIdentifiers

/// A filter in the sidebar.
enum SidebarItem: Hashable {
    case all
    case fresh
    case tossed
    case kind(SkillKind)
    case collection(UUID)

    var help: String {
        switch self {
        case .all: "Every skill from every scanned folder."
        case .fresh: "Skills changed in the last 7 days."
        case .tossed: "Skills unchanged since the latest snapshot."
        case .kind(let kind): kind.summary
        case .collection: "A collection you made. Drag skills here to add them."
        }
    }
}

struct CollectionNaming {
    enum Mode {
        case create(adding: SkillRecord.ID?)
        case rename(UUID)
    }

    let mode: Mode
    var draft: String

    var title: String {
        if case .rename = mode { return "Rename Collection" }
        return "New Collection"
    }
}

enum SkillSort: String, CaseIterable, Identifiable {
    case name = "Name"
    case modified = "Last Changed"
    case size = "Size"

    var id: String { rawValue }
}

@MainActor
@Observable
final class AppModel {
    private(set) var skills: [SkillRecord] = []
    private(set) var snapshots: [SnapshotInfo] = []
    private(set) var customFolders: [URL] = []
    private(set) var customBackupFolder: URL?
    private(set) var collections: [SkillCollection] = []

    /// Drives the name prompt for creating or renaming a collection.
    var collectionNaming: CollectionNaming?
    private(set) var isRefreshing = false
    private(set) var isBackingUp = false
    private(set) var hasLoaded = false

    var selection: SidebarItem = .all
    var selectedSkillID: SkillRecord.ID?
    var searchText = ""
    var sort: SkillSort = .name
    var isHelpPresented = false
    var errorMessage: String?
    /// Bumped after a successful backup so views can celebrate briefly.
    private(set) var backupTick = 0

    private let defaults: UserDefaults
    private let fileManager = FileManager.default

    private enum Keys {
        static let backupFolder = "SkillDumpsterBackupFolder"
        static let customFolders = "SkillDumpsterCustomFolders"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let path = defaults.string(forKey: Keys.backupFolder), !path.isEmpty {
            customBackupFolder = URL(fileURLWithPath: path, isDirectory: true)
        }
        customFolders = (defaults.stringArray(forKey: Keys.customFolders) ?? [])
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
        loadCollections()
    }

    func title(for item: SidebarItem) -> String {
        switch item {
        case .all: "All Skills"
        case .fresh: "Fresh Trash"
        case .tossed: "Tossed"
        case .kind(let kind): kind.rawValue
        case .collection(let id): collection(id)?.name ?? "Collection"
        }
    }

    // MARK: Derived state

    var roots: [SkillRoot] {
        SkillScanner.defaultRoots() + customFolders.map(SkillScanner.customRoot)
    }

    /// Kinds that have at least one skill, in display order.
    var presentKinds: [SkillKind] {
        let kinds = Set(skills.map(\.kind))
        return SkillKind.allCases.filter(kinds.contains)
    }

    var visibleSkills: [SkillRecord] {
        let filtered = skills.filter { matches($0, selection) && matchesSearch($0) }
        switch sort {
        case .name:
            return filtered
        case .modified:
            return filtered.sorted { ($0.stats.modifiedAt ?? .distantPast) > ($1.stats.modifiedAt ?? .distantPast) }
        case .size:
            return filtered.sorted { $0.stats.byteCount > $1.stats.byteCount }
        }
    }

    var selectedSkill: SkillRecord? {
        guard let selectedSkillID else { return nil }
        return skills.first { $0.id == selectedSkillID }
    }

    var backupFolder: URL {
        customBackupFolder ?? BackupService.defaultBackupDirectory(homeDirectory: fileManager.homeDirectoryForCurrentUser)
    }

    /// Collections live beside the snapshots, so they travel with the backup folder.
    var collectionsFile: URL {
        backupFolder.appendingPathComponent("collections.json")
    }

    var snapshotFolder: URL {
        backupFolder.appendingPathComponent("Snapshots", isDirectory: true)
    }

    func count(for item: SidebarItem) -> Int {
        skills.reduce(0) { $0 + (matches($1, item) ? 1 : 0) }
    }

    func isFresh(_ skill: SkillRecord) -> Bool {
        guard let modifiedAt = skill.stats.modifiedAt,
              let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { return false }
        return modifiedAt >= cutoff
    }

    // MARK: Actions

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false; hasLoaded = true }

        let scanner = SkillScanner(roots: roots)
        let backup = makeBackupService()

        do {
            async let scanned = Task.detached(priority: .userInitiated) { try scanner.scan() }.value
            async let found = Task.detached(priority: .userInitiated) { try backup.snapshots() }.value
            skills = try await scanned
            snapshots = try await found
            keepSelectionVisible()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func backUpAllSkills() async {
        guard !isBackingUp, !skills.isEmpty else { return }
        isBackingUp = true
        defer { isBackingUp = false }

        let current = skills
        let backup = makeBackupService()
        do {
            _ = try await Task.detached(priority: .userInitiated) {
                try backup.createSnapshot(skills: current)
            }.value
            snapshots = try backup.snapshots()
            backupTick += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ snapshot: SnapshotInfo) {
        let backup = makeBackupService()
        do {
            try backup.deleteSnapshot(snapshot)
            snapshots = try backup.snapshots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    // MARK: Settings

    // MARK: Collections

    func collection(_ id: UUID) -> SkillCollection? {
        collections.first { $0.id == id }
    }

    func collections(containing skill: SkillRecord) -> [SkillCollection] {
        collections.filter { $0.contains(skill) }
    }

    func beginNewCollection(adding skill: SkillRecord? = nil) {
        collectionNaming = CollectionNaming(mode: .create(adding: skill?.id), draft: "")
    }

    func beginRename(_ collection: SkillCollection) {
        collectionNaming = CollectionNaming(mode: .rename(collection.id), draft: collection.name)
    }

    func commitCollectionName() {
        guard let naming = collectionNaming else { return }
        collectionNaming = nil
        let name = naming.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        switch naming.mode {
        case .create(let skillID):
            var collection = SkillCollection(name: name)
            if let skillID, let skill = skills.first(where: { $0.id == skillID }) {
                collection.add(skill)
            }
            collections.append(collection)
            selection = .collection(collection.id)
        case .rename(let id):
            updateCollection(id) { $0.name = name }
        }
        saveCollections()
    }

    func deleteCollection(_ id: UUID) {
        collections.removeAll { $0.id == id }
        if selection == .collection(id) { selection = .all }
        saveCollections()
    }

    func toggle(_ skill: SkillRecord, in id: UUID) {
        updateCollection(id) { collection in
            if collection.contains(skill) { collection.remove(skill) } else { collection.add(skill) }
        }
        saveCollections()
    }

    func add(skillIDs: [String], to id: UUID) -> Bool {
        let dropped = skills.filter { skillIDs.contains($0.id) }
        guard !dropped.isEmpty else { return false }
        updateCollection(id) { collection in dropped.forEach { collection.add($0) } }
        saveCollections()
        return true
    }

    func remove(_ skill: SkillRecord, from id: UUID) {
        updateCollection(id) { $0.remove(skill) }
        saveCollections()
    }

    func export(_ collection: SkillCollection) {
        let members = collection.resolve(in: skills)
        guard !members.isEmpty else {
            errorMessage = "“\(collection.name)” has no skills on this Mac to export."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Collection"
        panel.nameFieldStringValue = "\(collection.name).zip"
        panel.allowedContentTypes = [.zip]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let backup = makeBackupService()
        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try backup.writeArchive(skills: members, to: url)
                }.value
                reveal(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func updateCollection(_ id: UUID, _ change: (inout SkillCollection) -> Void) {
        guard let index = collections.firstIndex(where: { $0.id == id }) else { return }
        change(&collections[index])
    }

    private func loadCollections() {
        do {
            collections = try CollectionStore(fileURL: collectionsFile).load()
        } catch {
            errorMessage = "Couldn't read collections.json: \(error.localizedDescription)"
        }
    }

    private func saveCollections() {
        do {
            try CollectionStore(fileURL: collectionsFile).save(collections)
        } catch {
            errorMessage = "Couldn't save collections: \(error.localizedDescription)"
        }
    }

    /// When the backup folder moves, bring collections along unless the new
    /// folder already has its own.
    private func moveCollections(applying change: () -> Void) {
        let current = collections
        change()
        if FileManager.default.fileExists(atPath: collectionsFile.path) {
            loadCollections()
        } else {
            collections = current
            if !current.isEmpty { saveCollections() }
        }
    }

    // MARK: Backup folder

    func chooseBackupFolder() {
        guard let url = pickFolder(
            title: "Choose Backup Folder",
            message: "Snapshots will be saved in a Snapshots folder inside it."
        ) else { return }
        moveCollections {
            customBackupFolder = url
            defaults.set(url.path, forKey: Keys.backupFolder)
        }
        Task { await refresh() }
    }

    func resetBackupFolder() {
        moveCollections {
            customBackupFolder = nil
            defaults.removeObject(forKey: Keys.backupFolder)
        }
        Task { await refresh() }
    }

    func addCustomFolder() {
        guard let url = pickFolder(
            title: "Add Folder to Scan",
            message: "Skill Dumpster searches this folder and its subfolders for SKILL.md files."
        ), !customFolders.contains(url) else { return }
        customFolders.append(url)
        saveCustomFolders()
        Task { await refresh() }
    }

    func removeCustomFolder(_ url: URL) {
        customFolders.removeAll { $0 == url }
        saveCustomFolders()
        Task { await refresh() }
    }

    // MARK: Private

    private func saveCustomFolders() {
        defaults.set(customFolders.map(\.path), forKey: Keys.customFolders)
    }

    private func pickFolder(title: String, message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = message
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func makeBackupService() -> BackupService {
        BackupService(baseDirectoryOverride: customBackupFolder)
    }

    private func keepSelectionVisible() {
        let visible = visibleSkills
        if let selectedSkillID, visible.contains(where: { $0.id == selectedSkillID }) { return }
        selectedSkillID = visible.first?.id
    }

    private func matches(_ skill: SkillRecord, _ item: SidebarItem) -> Bool {
        switch item {
        case .all: true
        case .fresh: isFresh(skill)
        case .tossed: isInLatestSnapshot(skill)
        case .kind(let kind): skill.kind == kind
        case .collection(let id): collection(id)?.contains(skill) ?? false
        }
    }

    private func matchesSearch(_ skill: SkillRecord) -> Bool {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return [skill.displayName, skill.slug, skill.description, skill.kind.rawValue, skill.path]
            .contains { $0.localizedCaseInsensitiveContains(needle) }
    }

    private func isInLatestSnapshot(_ skill: SkillRecord) -> Bool {
        guard let latest = snapshots.first, let modifiedAt = skill.stats.modifiedAt else { return false }
        return latest.createdAt >= modifiedAt
    }
}
