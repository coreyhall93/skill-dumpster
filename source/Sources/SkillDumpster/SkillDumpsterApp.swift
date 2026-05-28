import SwiftUI

@main
struct SkillDumpsterApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1120, minHeight: 720)
                .sheet(isPresented: $model.isHelpPresented) {
                    HelpView()
                        .environmentObject(model)
                }
                .task {
                    await model.refresh()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Skills") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Back Up All Skills") {
                    Task { await model.backUpAllSkills() }
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .help) {
                Button("Skill Dumpster Help") {
                    model.showHelp()
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
    }
}
