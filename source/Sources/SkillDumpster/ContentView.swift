import SkillDumpsterCore
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } content: {
            SkillListView()
                .navigationSplitViewColumnWidth(min: 320, ideal: 400)
        } detail: {
            SkillDetailView()
        }
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "Search the heap")
        .navigationTitle(model.selection.title)
        .navigationSubtitle(subtitle)
        .toolbar { MainToolbar() }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var subtitle: String {
        if model.isBackingUp { return "Tossing a fresh snapshot…" }
        if model.isRefreshing && !model.hasLoaded { return "Rummaging through the heap…" }
        let shown = model.visibleSkills.count
        return shown == 1 ? "1 skill" : "\(shown.formatted()) skills"
    }
}

private struct MainToolbar: ToolbarContent {
    @Environment(AppModel.self) private var model
    @State private var showCheck = false

    var body: some ToolbarContent {
        @Bindable var model = model

        ToolbarItem(placement: .navigation) {
            Button {
                Task { await model.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Rescan every skill folder (⌘R)")
            .disabled(model.isRefreshing)
        }

        ToolbarItem {
            Menu {
                Picker("Sort By", selection: $model.sort) {
                    ForEach(SkillSort.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .help("Sort by \(model.sort.rawValue.lowercased())")
        }

        ToolbarItem {
            Button {
                Task { await model.backUpAllSkills() }
            } label: {
                Label("Back Up", systemImage: showCheck ? "checkmark.circle.fill" : "archivebox")
                    .contentTransition(.symbolEffect(.replace))
            }
            .help("Save every skill into a zip snapshot (⇧⌘B)")
            .disabled(model.skills.isEmpty || model.isBackingUp)
            .onChange(of: model.backupTick) {
                showCheck = true
                Task {
                    try? await Task.sleep(for: .seconds(1.4))
                    showCheck = false
                }
            }
        }
    }
}
