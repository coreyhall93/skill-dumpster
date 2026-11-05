import SkillDumpsterCore
import SwiftUI

struct SkillListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let skills = model.visibleSkills

        List(skills, selection: $model.selectedSkillID) { skill in
            SkillRow(skill: skill, isFresh: model.isFresh(skill))
                .tag(skill.id)
                .draggable(skill.id) {
                    Label(skill.displayName, systemImage: skill.kind.symbolName)
                        .padding(6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                .contextMenu {
                    Button("Show in Finder") { model.reveal(URL(fileURLWithPath: skill.path)) }
                    Button("Open SKILL.md") { model.open(URL(fileURLWithPath: skill.skillFilePath)) }
                    Divider()
                    CollectionMenu(skill: skill)
                    if case .collection(let id) = model.selection, let collection = model.collection(id) {
                        Button("Remove from “\(collection.name)”") { model.remove(skill, from: id) }
                    }
                    Divider()
                    Button("Copy Path") { model.copyToPasteboard(skill.path) }
                }
        }
        .listStyle(.inset)
        .overlay {
            if !model.hasLoaded {
                ProgressView("Rummaging…")
            } else if skills.isEmpty {
                emptyState
            }
        }
        .onChange(of: model.selection) { selectFirstIfNeeded() }
        .onChange(of: model.searchText) { selectFirstIfNeeded() }
    }

    @ViewBuilder
    private var emptyState: some View {
        if !model.searchText.isEmpty {
            ContentUnavailableView {
                Label("No results for “\(model.searchText)”", systemImage: "magnifyingglass")
            } description: {
                Text("Nothing in \(model.title(for: model.selection)) matches this search.")
            } actions: {
                Button("Clear Search") { model.searchText = "" }
                    .keyboardShortcut(.cancelAction)
            }
        } else if case .collection = model.selection {
            ContentUnavailableView(
                "This collection is empty",
                systemImage: "square.stack",
                description: Text("Drag skills onto it in the sidebar, or right-click a skill and choose Add to Collection.")
            )
        } else if model.selection == .tossed {
            ContentUnavailableView(
                "Nothing tossed yet",
                systemImage: "archivebox",
                description: Text("Back up your skills to see which ones a snapshot covers.")
            )
        } else {
            ContentUnavailableView(
                "The heap is quiet",
                systemImage: "tray",
                description: Text("No skills here. Add folders to scan in Settings.")
            )
        }
    }

    private func selectFirstIfNeeded() {
        let visible = model.visibleSkills
        if let id = model.selectedSkillID, visible.contains(where: { $0.id == id }) { return }
        model.selectedSkillID = visible.first?.id
    }
}

private struct SkillRow: View {
    let skill: SkillRecord
    let isFresh: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            KindIcon(kind: skill.kind)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(skill.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    if isFresh {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .help("Changed in the last 7 days")
                            .accessibilityLabel("Fresh")
                    }

                    Spacer(minLength: 4)

                    if let modifiedAt = skill.stats.modifiedAt {
                        Text(Format.relative(modifiedAt))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }

                Text(skill.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(skill.kind.rawValue)
                    if !skill.duplicatePaths.isEmpty {
                        Text("·")
                        Text("\(skill.duplicatePaths.count + 1) copies")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}
