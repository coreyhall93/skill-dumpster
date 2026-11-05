import SkillDumpsterCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section {
                LabeledContent("Snapshots") {
                    Text((model.snapshotFolder.path as NSString).abbreviatingWithTildeInPath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                HStack {
                    Button("Choose Folder…") { model.chooseBackupFolder() }
                    Button("Show in Finder") { model.open(model.backupFolder) }
                    if model.customBackupFolder != nil {
                        Button("Use Default") { model.resetBackupFolder() }
                    }
                }
            } header: {
                Text("Backups")
            } footer: {
                Text("Each backup is a timestamped zip of every scanned skill plus a manifest.json.")
                    .foregroundStyle(.secondary)
            }

            Section {
                if model.customFolders.isEmpty {
                    Text("No extra folders. Add a projects or notes folder to find skills that live inside it.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.customFolders, id: \.self) { url in
                        HStack {
                            Label((url.path as NSString).abbreviatingWithTildeInPath, systemImage: "folder")
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                model.removeCustomFolder(url)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Stop scanning this folder")
                        }
                    }
                }
                Button("Add Folder…") { model.addCustomFolder() }
            } header: {
                Text("Extra folders to scan")
            } footer: {
                Text("Searched deeply, including hidden folders like .claude/skills. Build and dependency folders are skipped.")
                    .foregroundStyle(.secondary)
            }

            Section("Always scanned") {
                ForEach(model.roots.filter { $0.kind != .custom }, id: \.url) { root in
                    SourceRow(root: root)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 620)
    }
}

private struct SourceRow: View {
    @Environment(AppModel.self) private var model
    let root: SkillRoot

    private var exists: Bool { FileManager.default.fileExists(atPath: root.url.path) }

    var body: some View {
        HStack(spacing: 10) {
            KindIcon(kind: root.kind, size: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(root.kind.rawValue)
                Text((root.url.path as NSString).abbreviatingWithTildeInPath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if exists {
                Button {
                    model.open(root.url.resolvingSymlinksInPath())
                } label: {
                    Image(systemName: "arrow.right.circle")
                }
                .buttonStyle(.borderless)
                .help("Show in Finder")
            } else {
                Text("Not found").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .opacity(exists ? 1 : 0.55)
    }
}
