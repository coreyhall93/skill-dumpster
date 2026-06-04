import SkillDumpsterCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isSettingsOpen = false
    @State private var isSnapshotsOpen = true

    var body: some View {
        ZStack {
            DumpsterBackdrop()

            VStack(spacing: 0) {
                CommandBar(
                    isSettingsOpen: $isSettingsOpen,
                    isSnapshotsOpen: $isSnapshotsOpen
                )

                HStack(alignment: .top, spacing: 18) {
                    SourceRail()
                        .frame(width: 86)

                    HeapWorkspace(isSnapshotsOpen: $isSnapshotsOpen)

                    ZStack {
                        if isSettingsOpen {
                            SettingsFloatingPanel(close: { isSettingsOpen = false })
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            InspectorPanel()
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .frame(width: 372)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
        }
        .environment(\.font, DumpsterFont.body())
        .animation(DumpsterMotion.settle, value: isSettingsOpen)
        .animation(DumpsterMotion.soft, value: isSnapshotsOpen)
    }
}

private struct CommandBar: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isSettingsOpen: Bool
    @Binding var isSnapshotsOpen: Bool

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Skill Dumpster")
                    .font(DumpsterFont.fixed(25, .heavy))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Text(commandSubtitle)
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
            }
            .frame(width: 264, alignment: .leading)

            SearchField(text: $model.searchText)
                .frame(maxWidth: 520)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                ToolbarChip(
                    symbolName: "arrow.clockwise",
                    title: "Refresh",
                    help: "Refresh skills"
                ) {
                    Task { await model.refresh() }
                }
                .disabled(model.isRefreshing)

                BackupToolbarChip()

                ToolbarChip(
                    symbolName: isSnapshotsOpen ? "clock.badge.checkmark" : "clock",
                    title: "Snapshots",
                    help: isSnapshotsOpen ? "Hide snapshots" : "Show snapshots"
                ) {
                    isSnapshotsOpen.toggle()
                }

                ToolbarChip(
                    symbolName: "slider.horizontal.3",
                    title: "Settings",
                    help: "Settings"
                ) {
                    isSettingsOpen.toggle()
                }
            }
        }
        .padding(.leading, 92)
        .padding(.trailing, 22)
        .frame(height: 82)
        .background(DumpsterTheme.commandSurface)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(DumpsterTheme.divider)
        }
    }

    private var commandSubtitle: String {
        if model.isBackingUp {
            return "Tossing a fresh snapshot"
        }

        if model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(model.skills.count) skills, \(model.snapshots.count) snapshots"
        }

        return "\(model.visibleSkills.count) matches in the heap"
    }
}

private struct ToolbarChip: View {
    let symbolName: String
    let title: String
    let help: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(DumpsterFont.caption(.semibold))
                .labelStyle(.iconOnly)
                .frame(width: 40, height: 38)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(DumpsterTheme.primaryText)
        .background(isHovering ? DumpsterTheme.hoverFill : DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.035 : 1)
        .help(help)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
    }
}

private struct BackupToolbarChip: View {
    @EnvironmentObject private var model: AppModel
    @State private var isHovering = false
    @State private var isShowingSuccess = false

    var body: some View {
        Button {
            Task { await model.backUpAllSkills() }
        } label: {
            Image(systemName: iconName)
                .font(DumpsterFont.fixed(16, .semibold))
                .foregroundStyle(isShowingSuccess ? DumpsterTheme.success : DumpsterTheme.primaryText)
                .frame(width: 40, height: 38)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(model.isBackingUp || model.skills.isEmpty)
        .opacity(model.skills.isEmpty ? 0.48 : 1)
        .background(isHovering || model.isBackingUp ? DumpsterTheme.hoverFill : DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isShowingSuccess ? DumpsterTheme.success.opacity(0.42) : DumpsterTheme.controlStroke, lineWidth: 1)
        )
        .rotationEffect(.degrees(model.isBackingUp ? -7 : 0))
        .scaleEffect(isShowingSuccess ? 1.10 : isHovering ? 1.035 : 1)
        .help(model.isBackingUp ? "Making a fresh snapshot" : "Back up all skills")
        .onHover { isHovering = $0 }
        .onChange(of: model.backupSuccessTick) { _, _ in
            guard model.backupSuccessTick > 0 else { return }
            isShowingSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                isShowingSuccess = false
            }
        }
        .animation(DumpsterMotion.quick, value: isHovering)
        .animation(DumpsterMotion.emphatic, value: isShowingSuccess)
        .animation(DumpsterMotion.soft, value: model.isBackingUp)
    }

    private var iconName: String {
        if isShowingSuccess {
            return "checkmark"
        }
        if model.isBackingUp {
            return "archivebox"
        }
        return "externaldrive"
    }
}

private struct SourceRail: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                ForEach(RummageSection.sourceCases) { section in
                    RailButton(
                        section: section,
                        count: model.count(for: section),
                        isSelected: model.selectedSection == section
                    ) {
                        model.selectedSection = section
                    }
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.11))
                .padding(.vertical, 3)

            VStack(spacing: 8) {
                ForEach(RummageSection.statusCases) { section in
                    RailButton(
                        section: section,
                        count: model.count(for: section),
                        isSelected: model.selectedSection == section
                    ) {
                        model.selectedSection = section
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
        .background(DumpsterTheme.railSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct RailButton: View {
    let section: RummageSection
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: section.symbolName)
                    .font(DumpsterFont.fixed(17, .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 38, height: 32)

                Text("\(count)")
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.92) : DumpsterTheme.railForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 60, height: 58)
            .background(backgroundFill, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.07), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("\(section.rawValue), \(count). \(section.helpText)")
        .scaleEffect(isHovering && !isSelected ? 1.04 : 1)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
        .animation(DumpsterMotion.soft, value: isSelected)
    }

    private var backgroundFill: Color {
        if isSelected {
            return DumpsterTheme.railSelected
        }
        if isHovering {
            return DumpsterTheme.railHover
        }
        return Color.clear
    }

    private var iconColor: Color {
        if isSelected {
            return DumpsterTheme.railIconHighlight
        }

        if isHovering {
            return DumpsterTheme.railIconHighlight.opacity(0.92)
        }

        return DumpsterTheme.railIconDefault
    }
}

private struct HeapWorkspace: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isSnapshotsOpen: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeapHeader()
                .padding(.horizontal, 26)
                .padding(.top, 24)
                .padding(.bottom, 16)

            if isSnapshotsOpen {
                SnapshotShelf()
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
                .overlay(DumpsterTheme.divider)

            ScrollView {
                if model.visibleSkills.isEmpty {
                    HeapEmptyState()
                        .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(model.visibleSkills) { skill in
                            SkillTile(
                                skill: skill,
                                isSelected: model.selectedSkill?.id == skill.id
                            ) {
                                model.select(skill)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }

            Divider()
                .overlay(DumpsterTheme.divider)

            Text(model.statusMessage)
                .font(DumpsterFont.footnote(.regular))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .lineLimit(1)
                .padding(.horizontal, 26)
                .frame(height: 40, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DumpsterTheme.panelSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
    }

}

private struct HeapHeader: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 7) {
                    Text(model.selectedSection.rawValue)
                        .font(DumpsterFont.fixed(28, .heavy))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(1)

                    InfoGlyph(helpText: model.selectedSection.helpText)
                }

                Text(model.selectedSection.helpText)
                    .font(DumpsterFont.callout(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 18)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(model.visibleSkills.count)")
                    .font(DumpsterFont.fixed(28, .heavy))
                    .foregroundStyle(DumpsterTheme.sectionAccent(for: model.selectedSection))

                Text(model.visibleSkills.count == 1 ? "skill" : "skills")
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DumpsterTheme.quietStroke, lineWidth: 1)
            )
        }
    }
}

private struct SnapshotShelf: View {
    @EnvironmentObject private var model: AppModel
    @State private var snapshotPendingDeletion: SnapshotInfo?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Snapshots", systemImage: "clock.badge.checkmark")
                    .font(DumpsterFont.caption(.semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .textCase(.uppercase)

                Spacer()

                Text(model.snapshots.isEmpty ? "Nothing tossed yet" : "\(model.snapshots.count) saved")
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.tertiaryText)
            }

            if model.snapshots.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "archivebox")
                        .font(DumpsterFont.fixed(15, .semibold))
                        .foregroundStyle(DumpsterTheme.secondaryText)

                    Text("Your first snapshot will appear here after backup.")
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)

                    Spacer()
                }
                .padding(14)
                .background(DumpsterTheme.insetSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(model.snapshots.prefix(8)) { snapshot in
                            SnapshotToken(
                                snapshot: snapshot,
                                open: { model.open(snapshot.url) },
                                delete: {
                                    snapshotPendingDeletion = snapshot
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(14)
        .background(DumpsterTheme.insetSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DumpsterTheme.quietStroke, lineWidth: 1)
        )
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
}

private struct SnapshotToken: View {
    let snapshot: SnapshotInfo
    let open: () -> Void
    let delete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.createdAt, formatter: SkillFormatting.displayDateFormatter)
                        .font(DumpsterFont.caption(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(1)

                    Text(SkillFormatting.bytes(snapshot.byteCount))
                        .font(DumpsterFont.caption(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                }
                .frame(width: 156, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: delete) {
                Image(systemName: "xmark")
                    .font(DumpsterFont.fixed(11, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0.48)
            .help("Delete snapshot")
        }
        .padding(10)
        .background(isHovering ? DumpsterTheme.hoverFill : Color.white.opacity(0.001), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(DumpsterTheme.quietStroke, lineWidth: 1)
        )
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
    }
}

private struct SkillTile: View {
    let skill: SkillRecord
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                SkillKindGlyph(kind: skill.kind)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(skill.slug)
                            .font(DumpsterFont.headline(.heavy))
                            .foregroundStyle(DumpsterTheme.primaryText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        KindBadge(kind: skill.kind)
                    }

                    Text(skill.description)
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .lineSpacing(3)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)

                    HStack(spacing: 11) {
                        Label("\(skill.stats.fileCount)", systemImage: "doc.on.doc")
                        Label(SkillFormatting.bytes(skill.stats.byteCount), systemImage: "externaldrive")

                        Spacer()

                        if let modifiedAt = skill.stats.modifiedAt {
                            Text(relativeDate(modifiedAt))
                        }
                    }
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.tertiaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
            .background(tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tileStroke, lineWidth: isSelected ? 1 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.006 : isHovering ? 1.003 : 1)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
        .animation(DumpsterMotion.soft, value: isSelected)
    }

    private var tileFill: Color {
        if isSelected {
            return DumpsterTheme.selectedTileSurface
        }

        if isHovering {
            return DumpsterTheme.tileHoverSurface
        }

        return DumpsterTheme.tileSurface
    }

    private var tileStroke: Color {
        isSelected ? DumpsterTheme.sourceAccent(for: skill.kind).opacity(0.24) : .clear
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct HeapEmptyState: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(DumpsterTheme.controlSurface)
                    .frame(width: 76, height: 76)

                Image(systemName: "magnifyingglass")
                    .font(DumpsterFont.fixed(26, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
            }

            Text(model.searchText.isEmpty ? "The heap is quiet" : "No skill surfaced")
                .font(DumpsterFont.title2(.heavy))
                .foregroundStyle(DumpsterTheme.primaryText)

            Text(model.searchText.isEmpty ? "Add skill folders, then refresh." : "Try loosening the search or switching sources.")
                .font(DumpsterFont.callout(.regular))
                .foregroundStyle(DumpsterTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InspectorPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if let skill = model.selectedSkill {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        InspectorHero(skill: skill)

                        HStack(spacing: 8) {
                            DetailButton(title: "Reveal", symbolName: "finder") {
                                model.reveal(skill.path)
                            }

                            DetailButton(title: "Edit", symbolName: "doc.text") {
                                model.edit(skill)
                            }

                            DetailButton(title: "Back Up", symbolName: "externaldrive") {
                                Task { await model.backUpAllSkills() }
                            }
                            .disabled(model.isBackingUp)
                        }

                        InspectorSection(title: "Stats") {
                            StatGrid(skill: skill)
                        }

                        InspectorSection(title: "Path") {
                            Text(skill.path)
                                .font(DumpsterFont.callout(.regular))
                                .foregroundStyle(DumpsterTheme.primaryText)
                                .lineSpacing(3)
                                .textSelection(.enabled)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        InspectorSection(title: "Skill Description") {
                            Text(skill.description)
                                .font(DumpsterFont.callout(.regular))
                                .foregroundStyle(DumpsterTheme.primaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(18)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sidebar.right")
                        .font(DumpsterFont.fixed(26, .semibold))
                        .foregroundStyle(DumpsterTheme.secondaryText)

                    Text("Pick a skill")
                        .font(DumpsterFont.title3(.heavy))
                        .foregroundStyle(DumpsterTheme.primaryText)

                    Text("Details will slide into this little pocket.")
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
        .background(DumpsterTheme.panelSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
    }
}

private struct InspectorHero: View {
    let skill: SkillRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                SkillKindGlyph(kind: skill.kind)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text(skill.slug)
                        .font(DumpsterFont.fixed(30, .heavy))
                        .foregroundStyle(DumpsterTheme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(skill.declaredName ?? skill.slug)
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                KindBadge(kind: skill.kind)

                if skill.kind.isManaged {
                    ManagedBadge()
                }
            }
        }
        .padding(18)
        .background(DumpsterTheme.insetSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DumpsterTheme.quietStroke, lineWidth: 1)
        )
    }
}

private struct SkillKindGlyph: View {
    let kind: SkillKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DumpsterTheme.sourceAccent(for: kind).opacity(0.12))

            Image(systemName: iconName)
                .font(DumpsterFont.fixed(18, .heavy))
                .foregroundStyle(DumpsterTheme.sourceAccent(for: kind))
        }
    }

    private var iconName: String {
        switch kind {
        case .personal:
            "internaldrive"
        case .claude:
            "sparkles.rectangle.stack"
        case .grok:
            "brain.head.profile"
        case .sol:
            "hammer"
        case .plugin:
            "shippingbox"
        case .system:
            "lock"
        }
    }
}

private struct StatGrid: View {
    let skill: SkillRecord

    var body: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            StatTile(label: "Files", value: "\(skill.stats.fileCount)")
            StatTile(label: "Size", value: SkillFormatting.bytes(skill.stats.byteCount))
            StatTile(label: "Modified", value: modifiedDate)
            StatTile(label: "Hash", value: SkillFormatting.compactHash(skill.stats.contentHash))
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(minimum: 130), spacing: 9),
            GridItem(.flexible(minimum: 130), spacing: 9)
        ]
    }

    private var modifiedDate: String {
        guard let modifiedAt = skill.stats.modifiedAt else { return "Unknown" }
        return SkillFormatting.displayDateFormatter.string(from: modifiedAt)
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DumpsterFont.caption(.semibold))
                .foregroundStyle(DumpsterTheme.tertiaryText)
                .textCase(.uppercase)

            Text(value)
                .font(DumpsterFont.callout(.regular))
                .foregroundStyle(DumpsterTheme.primaryText)
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .background(DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(DumpsterFont.caption(.semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .textCase(.uppercase)
                .padding(.leading, 4)

            content
        }
    }
}

private struct DetailButton: View {
    let title: String
    let symbolName: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(DumpsterFont.caption(.semibold))
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(DumpsterTheme.primaryText)
        .background(isHovering ? DumpsterTheme.hoverFill : DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
        .help(title)
        .scaleEffect(isHovering ? 1.018 : 1)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
    }
}

private struct KindBadge: View {
    let kind: SkillKind

    var body: some View {
        Text(kind.rawValue)
            .font(DumpsterFont.caption(.semibold))
            .foregroundStyle(DumpsterTheme.sourceAccent(for: kind))
            .padding(.horizontal, 10)
            .frame(height: 27)
            .background(DumpsterTheme.sourceAccent(for: kind).opacity(0.12), in: Capsule())
            .fixedSize()
    }
}

private struct ManagedBadge: View {
    var body: some View {
        Label("Managed", systemImage: "shippingbox")
            .font(DumpsterFont.caption(.semibold))
            .foregroundStyle(DumpsterTheme.secondaryText)
            .padding(.horizontal, 10)
            .frame(height: 27)
            .background(DumpsterTheme.controlSurface, in: Capsule())
            .fixedSize()
    }
}

private struct SettingsFloatingPanel: View {
    @EnvironmentObject private var model: AppModel
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Text("Settings")
                    .font(DumpsterFont.fixed(24, .heavy))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(DumpsterFont.fixed(13, .semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .help("Close settings")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsSection(title: "Backup Location") {
                        BackupLocationSettings()
                    }

                    SettingsSection(title: "Skill Sources") {
                        ForEach(model.skillSources, id: \.url.path) { source in
                            SourceSettingsRow(source: source) {
                                model.revealSource(source)
                            }
                        }
                    }

                    SettingsSection(title: "Odd Utility Notes") {
                        SettingsInfoRow(
                            symbolName: "sparkles",
                            title: "Fresh Trash",
                            detail: "Skills changed in the last 7 days."
                        )

                        SettingsInfoRow(
                            symbolName: "archivebox",
                            title: "Tossed",
                            detail: "Skills captured in the latest snapshot."
                        )
                    }

                    SettingsSection(title: "Help") {
                        SettingsActionRow(
                            symbolName: "questionmark.circle",
                            title: "Skill Dumpster Help",
                            detail: "Sources, snapshots, lingo, and shortcuts."
                        ) {
                            model.showHelp()
                        }
                    }
                }
                .padding(.bottom, 6)
            }
            .scrollIndicators(.hidden)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DumpsterTheme.panelSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
    }
}

private struct BackupLocationSettings: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                Image(systemName: "externaldrive")
                    .font(DumpsterFont.fixed(15, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.isUsingCustomBackupFolder ? "Custom folder" : "Default Sol folder")
                        .font(DumpsterFont.callout(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)

                    Text(model.backupFolderURL?.path ?? "Unavailable")
                        .font(DumpsterFont.caption(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                SmallIconButton(symbolName: "folder", help: "Change backup location") {
                    model.chooseBackupFolder()
                }

                SmallIconButton(symbolName: "arrow.up.forward.app", help: "Open backup folder") {
                    model.open(model.backupFolderURL)
                }

                if model.isUsingCustomBackupFolder {
                    SmallIconButton(symbolName: "arrow.uturn.backward", help: "Use default Sol backup folder") {
                        model.useDefaultBackupFolder()
                    }
                }
            }
            .padding(.leading, 34)
        }
        .settingsCard()
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(DumpsterFont.caption(.semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
    }
}

private struct SourceSettingsRow: View {
    let source: SkillRoot
    let open: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName(for: source.kind))
                .font(DumpsterFont.fixed(15, .semibold))
                .foregroundStyle(DumpsterTheme.sourceAccent(for: source.kind))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.kind.rawValue)
                    .font(DumpsterFont.callout(.semibold))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Text(source.url.path)
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 6)

            SmallIconButton(symbolName: "arrow.up.forward.app", help: "Open source folder in Finder", action: open)
        }
        .settingsCard()
    }

    private func iconName(for kind: SkillKind) -> String {
        switch kind {
        case .personal:
            "internaldrive"
        case .claude:
            "sparkles.rectangle.stack"
        case .grok:
            "brain.head.profile"
        case .sol:
            "hammer"
        case .plugin:
            "shippingbox"
        case .system:
            "lock"
        }
    }
}

private struct SettingsInfoRow: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(15, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DumpsterFont.callout(.semibold))
                    .foregroundStyle(DumpsterTheme.primaryText)

                Text(detail)
                    .font(DumpsterFont.caption(.regular))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .settingsCard()
    }
}

private struct SettingsActionRow: View {
    let symbolName: String
    let title: String
    let detail: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbolName)
                    .font(DumpsterFont.fixed(15, .semibold))
                    .foregroundStyle(DumpsterTheme.secondaryText)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(DumpsterFont.callout(.semibold))
                        .foregroundStyle(DumpsterTheme.primaryText)

                    Text(detail)
                        .font(DumpsterFont.caption(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .settingsCard(fill: isHovering ? DumpsterTheme.hoverFill : DumpsterTheme.controlSurface)
        }
        .buttonStyle(.plain)
        .help(title)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
    }
}

private struct SmallIconButton: View {
    let symbolName: String
    let help: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(13, .semibold))
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(DumpsterTheme.secondaryText)
        .background(isHovering ? DumpsterTheme.hoverFill : Color.clear, in: Circle())
        .help(help)
        .onHover { isHovering = $0 }
        .animation(DumpsterMotion.quick, value: isHovering)
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(DumpsterFont.fixed(16, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)

            TextField("Search the heap", text: $text)
                .textFieldStyle(.plain)
                .font(DumpsterFont.headline(.semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
        }
        .padding(.horizontal, 15)
        .frame(height: 44)
        .background(DumpsterTheme.controlSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DumpsterTheme.controlStroke, lineWidth: 1)
        )
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

private extension View {
    func settingsCard(fill: Color = DumpsterTheme.controlSurface) -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DumpsterTheme.quietStroke, lineWidth: 1)
            )
    }
}
