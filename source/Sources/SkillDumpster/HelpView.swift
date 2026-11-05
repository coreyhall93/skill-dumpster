import AppKit
import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Skill Dumpster").font(.title2.weight(.semibold))
                    Text("A field guide for the odd little skill vault.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topic("What it does", "tray.full") {
                        Text("Skill Dumpster finds every SKILL.md on your Mac, shows where each one came from, and saves zip snapshots so a bad update or a stray rm never costs you a skill.")
                    }

                    topic("Where it looks", "folder") {
                        Text("Shared agent skills (~/.agents/skills), Claude Code skills and installed plugins, Codex skills and plugins, and Grok skills. Add any other folder in Settings and it will be searched deeply.")
                        Text("A skill linked into several agents shows up once. Byte-identical copies collapse into one entry that lists the other copies.")
                    }

                    topic("Collections", "square.stack") {
                        Text("Group skills you use together. Press ⌘N to make one, then drag skills onto it in the sidebar or use Add to Collection from a skill's right-click menu. Right-click a collection to rename, delete, or export it as a zip.")
                        Text("Collections are saved in collections.json inside your backup folder, so they travel with it.")
                    }

                    topic("Dumpster lingo", "sparkles") {
                        term("Fresh Trash", "Skills changed in the last 7 days.")
                        term("Tossed", "Skills unchanged since your latest snapshot.")
                        term("Managed", "Plugin or built-in skills. You can edit them, but an update may overwrite your changes.")
                    }

                    topic("Shortcuts", "keyboard") {
                        term("⌘N", "New collection")
                        term("⌘R", "Rescan skill folders")
                        term("⇧⌘B", "Back up all skills")
                        term("⌘F", "Search")
                        term("⌘,", "Settings")
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 560, height: 600)
    }

    private func topic<Content: View>(_ title: String, _ symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func term(_ name: String, _ meaning: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(name)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
                .frame(width: 92, alignment: .leading)
            Text(meaning)
        }
    }
}
