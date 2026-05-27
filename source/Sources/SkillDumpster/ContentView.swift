import SkillDumpsterCore
import SwiftUI

struct ContentView: View {
    @State private var isSidebarCollapsed = false
    @State private var sidebarMode: SidebarMode = .library

    var body: some View {
        HStack(spacing: 0) {
            DumpsterSidebar(
                isCollapsed: isSidebarCollapsed,
                mode: $sidebarMode,
                toggleCollapse: {
                    isSidebarCollapsed.toggle()
                },
                openSettings: {
                    isSidebarCollapsed = false
                    sidebarMode = .settings
                }
            )
            .frame(width: isSidebarCollapsed ? 76 : 272)

            Divider()
                .overlay(DumpsterTheme.divider)

            VStack(spacing: 0) {
                ChromeHeader()

                Divider()
                    .overlay(DumpsterTheme.divider)

                HStack(spacing: 0) {
                    SkillListPane()
                        .frame(width: 470)

                    Divider()
                        .overlay(DumpsterTheme.divider)

                    SkillDetailPane()
                }
            }
        }
        .background(DumpsterTheme.appBackground)
        .environment(\.font, DumpsterFont.body())
        .animation(.easeInOut(duration: 0.18), value: isSidebarCollapsed)
        .animation(.easeInOut(duration: 0.16), value: sidebarMode)
    }
}

private enum SidebarMode {
    case library
    case settings
}

private struct ChromeHeader: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 20) {
            Text("Skill Dumpster")
                .font(DumpsterFont.title3(.heavy))
                .foregroundStyle(DumpsterTheme.primaryText)
                .lineLimit(1)

            Spacer(minLength: 24)

            HStack(spacing: 2) {
                HeaderIconButton(symbolName: "arrow.clockwise", help: "Refresh skills") {
                    Task { await model.refresh() }
                }
                .disabled(model.isRefreshing)

                HeaderIconButton(symbolName: "externaldrive.badge.icloud", help: "Back up all skills") {
                    Task { await model.backUpAllSkills() }
                }
                .disabled(model.isBackingUp || model.skills.isEmpty)
            }
            .padding(4)
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
            )

            SearchField(text: $model.searchText)
        }
        .padding(.leading, 28)
        .padding(.trailing, 24)
        .frame(height: 58)
        .background(.ultraThinMaterial)
    }
}

private struct HeaderIconButton: View {
    let symbolName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(18, .semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
                .frame(width: 38, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct SettingsSidebarView: View {
    @EnvironmentObject private var model: AppModel
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                SidebarUtilityButton(symbolName: "chevron.left", help: "Back to library", action: close)

                Text("Settings")
                    .font(DumpsterFont.title3(.heavy))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SettingsSection(title: "Backup Location") {
                        BackupLocationSettings()
                    }

                    SettingsSection(title: "Skills") {
                        ForEach(model.skillSources, id: \.url.path) { source in
                            SourceSettingsRow(source: source) {
                                model.revealSource(source)
                            }
                        }
                    }

                    SettingsSection(title: "Dumpster Lingo") {
                        SettingsInfoRow(
                            symbolName: "sparkles",
                            title: "Fresh Trash",
                            detail: "Skills changed in the last 7 days."
                        )

                        SettingsInfoRow(
                            symbolName: "trash",
                            title: "Tossed",
                            detail: "Skills captured in the latest snapshot."
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct BackupLocationSettings: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: "icloud.and.arrow.up")
                    .font(DumpsterFont.fixed(15, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.isUsingCustomBackupFolder ? "Custom folder" : "Default iCloud folder")
                        .font(DumpsterFont.caption(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)

                    Text(model.backupFolderURL?.path ?? "Unavailable")
                        .font(DumpsterFont.caption(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 4)
            }

            HStack(spacing: 4) {
                SidebarUtilityButton(symbolName: "folder", help: "Change backup location") {
                    model.chooseBackupFolder()
                }

                SidebarUtilityButton(symbolName: "arrow.up.forward.app", help: "Open backup folder") {
                    model.open(model.backupFolderURL)
                }

                if model.isUsingCustomBackupFolder {
                    SidebarUtilityButton(symbolName: "arrow.uturn.backward", help: "Use default iCloud backup folder") {
                        model.useDefaultBackupFolder()
                    }
                }
            }
            .padding(.leading, 27)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            SidebarLabel(title)
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
    }
}

private struct SettingsInfoRow: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(15, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Text(detail)
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DumpsterTheme.hoverFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SourceSettingsRow: View {
    let source: SkillRoot
    let open: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: iconName(for: source.kind))
                .font(DumpsterFont.fixed(15, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.kind.rawValue)
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Text(source.url.path)
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 4)

            SidebarUtilityButton(symbolName: "arrow.up.forward.app", help: "Open source folder in Finder", action: open)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconName(for kind: SkillKind) -> String {
        switch kind {
        case .personal:
            "archivebox"
        case .claude:
            "sparkles.rectangle.stack"
        case .grok:
            "brain.head.profile"
        case .developer:
            "hammer"
        case .plugin:
            "shippingbox"
        case .system:
            "lock"
        }
    }
}

private struct DumpsterSidebar: View {
    @EnvironmentObject private var model: AppModel
    let isCollapsed: Bool
    @Binding var mode: SidebarMode
    let toggleCollapse: () -> Void
    let openSettings: () -> Void

    @State private var snapshotPendingDeletion: SnapshotInfo?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if mode == .settings && !isCollapsed {
                SettingsSidebarView {
                    mode = .library
                }
            } else {
                libraryContent
            }
        }
        .padding(.top, 52)
        .padding(.horizontal, isCollapsed ? 10 : 16)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
        .confirmationDialog(
            "Delete snapshot?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Snapshot", role: .destructive) {
                if let snapshotPendingDeletion {
                    Task { await model.deleteSnapshot(snapshotPendingDeletion) }
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(snapshotPendingDeletion?.url.lastPathComponent ?? "This cannot be undone.")
        }
    }

    private var libraryContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    if !isCollapsed {
                        SidebarLabel("Sources")
                        Spacer(minLength: 0)

                        SidebarUtilityButton(symbolName: "gearshape", help: "Settings", action: openSettings)
                    }

                    SidebarCollapseButton(isCollapsed: isCollapsed, action: toggleCollapse)
                }
                .padding(.horizontal, isCollapsed ? 0 : 8)
                .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)

                ForEach(RummageSection.sourceCases) { section in
                    SidebarButton(
                        title: section.rawValue,
                        count: model.count(for: section),
                        symbolName: section.symbolName,
                        helpText: section.helpText,
                        isSelected: model.selectedSection == section,
                        isCollapsed: isCollapsed
                    ) {
                        model.selectedSection = section
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                if !isCollapsed {
                    SidebarLabel("Status")
                }

                ForEach(RummageSection.statusCases) { section in
                    SidebarButton(
                        title: section.rawValue,
                        count: model.count(for: section),
                        symbolName: section.symbolName,
                        helpText: section.helpText,
                        isSelected: model.selectedSection == section,
                        isCollapsed: isCollapsed
                    ) {
                        model.selectedSection = section
                    }
                }
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 10) {
                    SidebarLabel("Snapshots")

                    if model.snapshots.isEmpty {
                        Text("Nothing tossed yet")
                            .font(DumpsterFont.callout(.regular))
                            .foregroundStyle(DumpsterTheme.secondaryText)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    } else {
                        ForEach(model.snapshots.prefix(6)) { snapshot in
                            SnapshotRow(
                                snapshot: snapshot,
                                open: {
                                    model.open(snapshot.url)
                                },
                                delete: {
                                    snapshotPendingDeletion = snapshot
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct SidebarCollapseButton: View {
    let isCollapsed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isCollapsed ? "sidebar.left" : "sidebar.leading")
                .font(DumpsterFont.fixed(18, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(isCollapsed ? "Expand sidebar" : "Collapse sidebar")
    }
}

private struct SidebarUtilityButton: View {
    let symbolName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(14, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct SidebarLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(DumpsterFont.subheadline(.semibold))
            .foregroundStyle(DumpsterTheme.secondaryText)
            .padding(.horizontal, 8)
    }
}

private struct SidebarButton: View {
    let title: String
    let count: Int
    let symbolName: String
    let helpText: String
    let isSelected: Bool
    let isCollapsed: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(DumpsterFont.fixed(17, .semibold))
                    .frame(width: 22)

                if !isCollapsed {
                    Text(title)
                        .font(DumpsterFont.headline(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("\(count)")
                        .font(DumpsterFont.caption(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : DumpsterTheme.secondaryText)
                }
            }
            .foregroundStyle(isSelected ? .white : DumpsterTheme.primaryText)
            .padding(.horizontal, isCollapsed ? 0 : 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: isCollapsed ? .center : .leading)
            .background(sidebarButtonBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("\(title), \(count). \(helpText)")
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .animation(.easeOut(duration: 0.16), value: isSelected)
    }

    private var sidebarButtonBackground: Color {
        if isSelected {
            return DumpsterTheme.selection
        }
        if isHovering {
            return DumpsterTheme.hoverFill
        }
        return .clear
    }
}

private struct SnapshotRow: View {
    let snapshot: SnapshotInfo
    let open: () -> Void
    let delete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.createdAt, formatter: SkillFormatting.displayDateFormatter)
                        .font(DumpsterFont.callout(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(1)

                    Text(SkillFormatting.bytes(snapshot.byteCount))
                        .font(DumpsterFont.caption(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: delete) {
                Image(systemName: "trash")
                    .font(DumpsterFont.fixed(14, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete snapshot")
            .opacity(isHovering ? 1 : 0.55)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovering)
    }
}

private struct SkillListPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 7) {
                    Text(model.selectedSection.rawValue)
                        .font(DumpsterFont.title2(.heavy))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(1)

                    InfoGlyph(helpText: model.selectedSection.helpText)

                    Spacer(minLength: 12)

                    Text("\(model.visibleSkills.count) skills")
                        .font(DumpsterFont.callout(.semibold))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 13)

            Divider()
                .overlay(DumpsterTheme.divider)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.visibleSkills) { skill in
                        SkillRow(
                            skill: skill,
                            isSelected: model.selectedSkill?.id == skill.id
                        ) {
                            model.select(skill)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }

            Divider()
                .overlay(DumpsterTheme.divider)

            Text(model.statusMessage)
                .font(DumpsterFont.footnote(.regular))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .lineLimit(1)
                .padding(.horizontal, 28)
                .frame(height: 42, alignment: .leading)
        }
        .background(DumpsterTheme.columnBackground)
    }
}

private struct InfoGlyph: View {
    let helpText: String

    var body: some View {
        Image(systemName: "info.circle")
            .font(DumpsterFont.fixed(13, .semibold))
            .foregroundStyle(DumpsterTheme.secondaryText)
            .frame(width: 18, height: 18, alignment: .center)
            .help(helpText)
            .accessibilityLabel(helpText)
    }
}

private struct SkillRow: View {
    let skill: SkillRecord
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    Text(skill.slug)
                        .font(DumpsterFont.title3(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(1)

                    Spacer(minLength: 10)

                    KindBadge(kind: skill.kind)
                }

                Text(skill.description)
                    .font(DumpsterFont.callout(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .animation(.easeOut(duration: 0.16), value: isSelected)

        Divider()
            .overlay(DumpsterTheme.divider)
            .padding(.leading, 12)
    }

    private var rowBackground: Color {
        if isSelected {
            return DumpsterTheme.selectedRowFill
        }
        if isHovering {
            return DumpsterTheme.hoverFill
        }
        return .clear
    }
}

private struct SkillDetailPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if let skill = model.selectedSkill {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(skill.slug)
                                    .font(DumpsterFont.fixed(34, .heavy))
                                    .foregroundStyle(DumpsterTheme.primaryText)
                                    .lineLimit(2)

                                if skill.kind.isManaged {
                                    ManagedBadge()
                                }
                            }

                            Text(skill.declaredName ?? skill.slug)
                                .font(DumpsterFont.title3(.regular))
                                .foregroundStyle(DumpsterTheme.secondaryText)
                        }

                        HStack(spacing: 8) {
                            DetailButton(title: "Reveal", symbolName: "finder") {
                                model.reveal(skill.path)
                            }

                            DetailButton(title: "Edit", symbolName: "doc.text") {
                                model.edit(skill)
                            }

                            DetailButton(title: "Back Up", symbolName: "externaldrive.badge.icloud") {
                                Task { await model.backUpAllSkills() }
                            }
                            .disabled(model.isBackingUp)
                        }

                        DetailSection(title: "Dumpster Stats") {
                            StatsGrid(skill: skill)
                        }

                        DetailSection(title: "Path") {
                            Text(skill.path)
                                .font(DumpsterFont.callout(.regular))
                                .foregroundStyle(DumpsterTheme.primaryText)
                                .textSelection(.enabled)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassPanel()
                        }

                        DetailSection(title: "Skill Description") {
                            Text(skill.description)
                                .font(DumpsterFont.callout(.regular))
                                .foregroundStyle(DumpsterTheme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassPanel()
                        }
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 56)
                    .padding(.bottom, 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "trash.slash")
                        .font(DumpsterFont.fixed(38, .semibold))
                        .foregroundStyle(DumpsterTheme.secondaryText)

                    Text("No skills found")
                        .font(DumpsterFont.title2(.semibold))

                    Text("Add skill folders, then refresh.")
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.regularMaterial)
    }
}

private struct StatsGrid: View {
    let skill: SkillRecord

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 12) {
            StatRow(label: "Slug", value: skill.slug)
            StatRow(label: "Source", value: skill.kind.rawValue)
            StatRow(label: "Files", value: "\(skill.stats.fileCount)")
            StatRow(label: "Size", value: SkillFormatting.bytes(skill.stats.byteCount))
            StatRow(label: "Modified", value: modifiedDate)
            StatRow(label: "Hash", value: SkillFormatting.compactHash(skill.stats.contentHash))
        }
        .padding(14)
        .frame(maxWidth: 430, alignment: .leading)
        .glassPanel()
    }

    private var modifiedDate: String {
        guard let modifiedAt = skill.stats.modifiedAt else { return "Unknown" }
        return SkillFormatting.displayDateFormatter.string(from: modifiedAt)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        GridRow {
            Text(label)
                .font(DumpsterFont.callout(.semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 92, alignment: .leading)

            Text(value)
                .font(DumpsterFont.callout(.regular))
                .foregroundStyle(DumpsterTheme.primaryText)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DumpsterFont.callout(.semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
                .padding(.leading, 12)

            content
        }
    }
}

private struct DetailButton: View {
    let title: String
    let symbolName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(DumpsterFont.callout(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .frame(height: 38)
                .fixedSize(horizontal: true, vertical: false)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
        .foregroundStyle(DumpsterTheme.primaryText)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
    }
}

private struct KindBadge: View {
    let kind: SkillKind

    var body: some View {
        Text(kind.rawValue)
            .font(DumpsterFont.caption(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 10)
            .frame(height: 25)
            .background(DumpsterTheme.badgeBackground(for: kind), in: Capsule())
            .fixedSize()
    }
}

private struct ManagedBadge: View {
    var body: some View {
        Label("Managed", systemImage: "shippingbox")
            .font(DumpsterFont.callout(.semibold))
            .foregroundStyle(DumpsterTheme.secondaryText)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
            )
            .fixedSize()
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(DumpsterFont.fixed(16, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)

            TextField("Search the heap", text: $text)
                .textFieldStyle(.plain)
                .font(DumpsterFont.headline(.semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
        }
        .padding(.horizontal, 15)
        .frame(width: 360, height: 42)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
    }
}

private extension View {
    func glassPanel(cornerRadius: CGFloat = 12) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
            )
    }
}

enum DumpsterTheme {
    static let appBackground = Color(nsColor: .windowBackgroundColor)
    static let columnBackground = Color(nsColor: .textBackgroundColor).opacity(0.36)
    static let selection = Color.accentColor
    static let hoverFill = Color.primary.opacity(0.055)
    static let selectedRowFill = Color.accentColor.opacity(0.14)
    static let divider = Color(nsColor: .separatorColor).opacity(0.72)
    static let controlStroke = Color.primary.opacity(0.11)

    static let primaryText = Color.primary.opacity(0.90)
    static let secondaryText = Color.secondary.opacity(0.88)

    static func badgeBackground(for kind: SkillKind) -> Color {
        switch kind {
        case .personal:
            Color(red: 0.45, green: 0.45, blue: 0.41)
        case .claude:
            Color(red: 0.38, green: 0.38, blue: 0.52)
        case .grok:
            Color(red: 0.22, green: 0.46, blue: 0.48)
        case .developer:
            Color(red: 0.25, green: 0.42, blue: 0.31)
        case .system:
            Color(red: 0.34, green: 0.36, blue: 0.40)
        case .plugin:
            Color(red: 0.50, green: 0.36, blue: 0.20)
        }
    }
}

enum DumpsterFont {
    private static let family = "Geist"

    static func body(_ weight: Font.Weight = .regular) -> Font {
        font(.body, size: 15, weight: weight)
    }

    static func callout(_ weight: Font.Weight = .regular) -> Font {
        font(.callout, size: 15, weight: weight)
    }

    static func caption(_ weight: Font.Weight = .regular) -> Font {
        font(.caption, size: 12, weight: weight)
    }

    static func footnote(_ weight: Font.Weight = .regular) -> Font {
        font(.footnote, size: 13, weight: weight)
    }

    static func headline(_ weight: Font.Weight = .regular) -> Font {
        font(.headline, size: 17, weight: weight)
    }

    static func subheadline(_ weight: Font.Weight = .regular) -> Font {
        font(.subheadline, size: 14, weight: weight)
    }

    static func title2(_ weight: Font.Weight = .regular) -> Font {
        font(.title2, size: 22, weight: weight)
    }

    static func title3(_ weight: Font.Weight = .regular) -> Font {
        font(.title3, size: 20, weight: weight)
    }

    static func fixed(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(family, size: size).weight(weight)
    }

    private static func font(_ style: Font.TextStyle, size: CGFloat, weight: Font.Weight) -> Font {
        .custom(family, size: size, relativeTo: style).weight(weight)
    }
}
