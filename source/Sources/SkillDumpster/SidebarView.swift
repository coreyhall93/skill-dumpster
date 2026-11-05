import SkillDumpsterCore
import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingDeletion: SnapshotInfo?

    var body: some View {
        @Bindable var model = model

        List(selection: Binding(
            get: { model.selection },
            set: { if let item = $0 { model.selection = item } }
        )) {
            Section("Library") {
                row(.all, systemImage: "tray.full")
                row(.fresh, systemImage: "sparkles")
                row(.tossed, systemImage: "checkmark.seal")
            }

            if !model.presentKinds.isEmpty {
                Section("Sources") {
                    ForEach(model.presentKinds, id: \.self) { kind in
                        row(.kind(kind), systemImage: kind.symbolName, tint: kind.tint)
                    }
                }
            }

            Section("Snapshots") {
                if model.snapshots.isEmpty {
                    Text("Nothing tossed yet")
                        .foregroundStyle(.secondary)
                        .selectionDisabled()
                } else {
                    ForEach(model.snapshots.prefix(6)) { snapshot in
                        SnapshotRow(snapshot: snapshot)
                            .selectionDisabled()
                            .contextMenu {
                                Button("Show in Finder") { model.reveal(snapshot.url) }
                                Divider()
                                Button("Delete Snapshot…", role: .destructive) { pendingDeletion = snapshot }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .confirmationDialog(
            "Delete this snapshot?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            presenting: pendingDeletion
        ) { snapshot in
            Button("Delete", role: .destructive) { model.delete(snapshot) }
        } message: { snapshot in
            Text("\(snapshot.url.lastPathComponent) will be removed. This can't be undone.")
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                model.open(model.snapshotFolder)
            } label: {
                Label("Open Snapshots Folder", systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func row(_ item: SidebarItem, systemImage: String, tint: Color = .accentColor) -> some View {
        Label {
            Text(item.title)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(tint)
        }
        .badge(model.count(for: item))
        .help(item.help)
        .tag(item)
    }
}

private struct SnapshotRow: View {
    @Environment(AppModel.self) private var model
    let snapshot: SnapshotInfo

    var body: some View {
        Button {
            model.reveal(snapshot.url)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 1) {
                    Text(snapshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                    Text(SkillFormatting.bytes(snapshot.byteCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "doc.zipper").foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .help("Show in Finder. Right-click for more.")
    }
}
