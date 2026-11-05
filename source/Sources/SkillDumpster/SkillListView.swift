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
                .contextMenu {
                    Button("Show in Finder") { model.reveal(URL(fileURLWithPath: skill.path)) }
                    Button("Open SKILL.md") { model.open(URL(fileURLWithPath: skill.skillFilePath)) }
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
            ContentUnavailableView.search(text: model.searchText)
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
