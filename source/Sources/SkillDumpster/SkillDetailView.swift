import SkillDumpsterCore
import SwiftUI

struct SkillDetailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let skill = model.selectedSkill {
            SkillDetail(skill: skill)
                .id(skill.id)
        } else {
            ContentUnavailableView(
                "Pick a skill",
                systemImage: "sidebar.right",
                description: Text("Details slide into this little pocket.")
            )
        }
    }
}

private struct SkillDetail: View {
    @Environment(AppModel.self) private var model
    let skill: SkillRecord
    @State private var markdown: String?
    @State private var isDescriptionExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                actions
                facts

                if !skill.duplicatePaths.isEmpty {
                    section("Identical copies") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(skill.duplicatePaths, id: \.self) { path in
                                PathLine(path: path) { model.reveal(URL(fileURLWithPath: path)) }
                            }
                        }
                    }
                }

                section("SKILL.md") {
                    Group {
                        if let markdown {
                            Text(markdown)
                                .font(.system(.callout, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: skill.id) { await loadMarkdown() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            KindIcon(kind: skill.kind, size: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(skill.displayName)
                    .font(.title.weight(.semibold))
                    .textSelection(.enabled)

                Text(skill.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(isDescriptionExpanded ? nil : 4)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if skill.description.count > 280 {
                    Button(isDescriptionExpanded ? "Show less" : "Show more") {
                        withAnimation(.snappy) { isDescriptionExpanded.toggle() }
                    }
                    .buttonStyle(.link)
                    .font(.callout)
                }

                HStack(spacing: 6) {
                    Pill(text: skill.kind.rawValue, systemImage: skill.kind.symbolName, tint: skill.kind.tint)
                    if skill.kind.isManaged {
                        Pill(text: "Managed", systemImage: "lock")
                            .help("Owned by an installer. Local edits may be overwritten on update.")
                    }
                    if model.isFresh(skill) {
                        Pill(text: "Fresh", systemImage: "sparkles", tint: .green)
                    }
                    ForEach(model.collections(containing: skill)) { collection in
                        Button {
                            model.selection = .collection(collection.id)
                        } label: {
                            Pill(text: collection.name, systemImage: "square.stack", tint: .accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Show this collection")
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button {
                model.open(URL(fileURLWithPath: skill.skillFilePath))
            } label: {
                Label("Open SKILL.md", systemImage: "doc.text")
            }
            .buttonStyle(.borderedProminent)

            Button {
                model.reveal(URL(fileURLWithPath: skill.path))
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }

            Button {
                model.copyToPasteboard(skill.path)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }

            Menu {
                CollectionMenuItems(skill: skill)
            } label: {
                Label("Collections", systemImage: "square.stack")
            }
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .controlSize(.large)
    }

    private var facts: some View {
        section("Details") {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                fact("Folder", skill.slug)
                fact("Files", skill.stats.fileCount.formatted())
                fact("Size", SkillFormatting.bytes(skill.stats.byteCount))
                if let modifiedAt = skill.stats.modifiedAt {
                    fact("Changed", modifiedAt.formatted(date: .abbreviated, time: .shortened))
                }
                fact("Hash", SkillFormatting.compactHash(skill.stats.contentHash), monospaced: true)
                GridRow {
                    Text("Path").foregroundStyle(.secondary).gridColumnAlignment(.trailing)
                    PathLine(path: skill.path) { model.reveal(URL(fileURLWithPath: skill.path)) }
                }
            }
            .font(.callout)
        }
    }

    private func fact(_ label: String, _ value: String, monospaced: Bool = false) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary).gridColumnAlignment(.trailing)
            Text(value)
                .fontDesign(monospaced ? .monospaced : .default)
                .textSelection(.enabled)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    /// The name and description already show in the header, so the preview starts at the body.
    nonisolated static func strippingFrontMatter(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---",
              let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" })
        else { return text }
        let body = lines[(end + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? "(No body beyond the front matter.)" : body
    }

    private func loadMarkdown() async {
        let path = skill.skillFilePath
        let text = await Task.detached(priority: .userInitiated) { () -> String in
            guard let data = FileManager.default.contents(atPath: path) else { return "Couldn't read SKILL.md." }
            let string = Self.strippingFrontMatter(String(decoding: data, as: UTF8.self))
            let limit = 40_000
            return string.count > limit ? String(string.prefix(limit)) + "\n\n… (truncated)" : string
        }.value
        markdown = text
    }
}

private struct PathLine: View {
    let path: String
    let reveal: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text((path as NSString).abbreviatingWithTildeInPath)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)

            Button(action: reveal) {
                Image(systemName: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Show in Finder")
        }
    }
}
