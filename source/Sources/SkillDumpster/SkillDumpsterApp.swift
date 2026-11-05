import SwiftUI

@main
struct SkillDumpsterApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Skill Dumpster", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 940, minHeight: 600)
                .task { await model.refresh() }
                .sheet(isPresented: $model.isHelpPresented) {
                    HelpView()
                }
        }
        .defaultSize(width: 1240, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Collection…") { model.beginNewCollection() }
                    .keyboardShortcut("n")
            }

            CommandGroup(after: .newItem) {
                Button("Refresh Skills") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r")

                Button("Back Up All Skills") {
                    Task { await model.backUpAllSkills() }
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(model.skills.isEmpty || model.isBackingUp)
            }

            CommandGroup(replacing: .help) {
                Button("Skill Dumpster Help") {
                    model.isHelpPresented = true
                }
                .keyboardShortcut("?")
            }
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
