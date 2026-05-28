import AppKit
import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Skill Dumpster Help")
                        .font(DumpsterFont.fixed(26, .heavy))
                        .foregroundStyle(DumpsterTheme.primaryText)

                    Text("A field guide for the odd little skill vault.")
                        .font(DumpsterFont.callout(.regular))
                        .foregroundStyle(DumpsterTheme.secondaryText)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .background(DumpsterTheme.commandSurface)

            Divider()
                .overlay(DumpsterTheme.divider)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HelpSection(title: "What Skill Dumpster Does", symbolName: "archivebox") {
                        HelpText("Skill Dumpster scans known local skill folders, shows each skill's source and computed stats, opens skills for editing, and creates zip snapshots for safekeeping.")
                    }

                    HelpSection(title: "Sources", symbolName: "folder.badge.gearshape") {
                        HelpText("The source filters are origins, not editable tags. Codex Local, Claude, Grok, Developer, Codex Plugins, and Codex System are inferred from the folder where each SKILL.md was found.")
                        HelpText("Open Settings from the sidebar to review every scanned source folder and jump to it in Finder.")
                    }

                    HelpSection(title: "Backups And Snapshots", symbolName: "externaldrive.badge.icloud") {
                        HelpText("Back Up creates a timestamped zip snapshot of all currently scanned skills. The default location is iCloud Drive, with a Documents fallback if iCloud is unavailable.")
                        HelpText("The backup location can be changed or reset in Settings. Snapshot rows in the sidebar can be opened or deleted with confirmation.")
                    }

                    HelpSection(title: "Dumpster Lingo", symbolName: "sparkles") {
                        HelpTerm(term: "Fresh Trash", meaning: "Skills changed in the last 7 days.")
                        HelpTerm(term: "Tossed", meaning: "Skills captured in the latest snapshot.")
                        HelpTerm(term: "Managed", meaning: "Plugin or system skills that live on disk but may be owned by a Codex/plugin install workflow.")
                    }

                    HelpSection(title: "Keyboard Shortcuts", symbolName: "keyboard") {
                        ShortcutRow(keys: "Command R", action: "Refresh skills")
                        ShortcutRow(keys: "Shift Command B", action: "Back up all skills")
                        ShortcutRow(keys: "Command ?", action: "Open this help window")
                    }

                    Button {
                        dismiss()
                    } label: {
                        Label("Close Help", systemImage: "checkmark.circle")
                            .font(DumpsterFont.callout(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 4)
                }
                .padding(24)
            }
            .background(DumpsterBackdrop())
        }
        .frame(width: 620, height: 640)
        .environment(\.font, DumpsterFont.body())
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    let symbolName: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(DumpsterFont.fixed(17, .semibold))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DumpsterFont.title3(.heavy))
                    .foregroundStyle(DumpsterTheme.primaryText)

                VStack(alignment: .leading, spacing: 7) {
                    content
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 14, prominent: false)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(DumpsterTheme.moss.opacity(0.72))
                .frame(width: 4)
                .padding(.vertical, 14)
        }
    }
}

private struct HelpText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(DumpsterFont.callout(.regular))
            .foregroundStyle(DumpsterTheme.secondaryText)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HelpTerm: View {
    let term: String
    let meaning: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(term)
                .font(DumpsterFont.callout(.semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
                .frame(width: 92, alignment: .leading)

            Text(meaning)
                .font(DumpsterFont.callout(.regular))
                .foregroundStyle(DumpsterTheme.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(keys)
                .font(DumpsterFont.caption(.semibold))
                .foregroundStyle(DumpsterTheme.primaryText)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(DumpsterTheme.hoverFill, in: Capsule())

            Text(action)
                .font(DumpsterFont.callout(.regular))
                .foregroundStyle(DumpsterTheme.secondaryText)
        }
    }
}
