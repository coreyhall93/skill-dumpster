import SkillDumpsterCore
import SwiftUI

/// "Add to Collection" submenu for context menus.
struct CollectionMenu: View {
    let skill: SkillRecord

    var body: some View {
        Menu("Add to Collection") {
            CollectionMenuItems(skill: skill)
        }
    }
}

/// One checkable item per collection, then "New Collection…".
struct CollectionMenuItems: View {
    @Environment(AppModel.self) private var model
    let skill: SkillRecord

    var body: some View {
        ForEach(model.collections) { collection in
            Toggle(collection.name, isOn: Binding(
                get: { collection.contains(skill) },
                set: { _ in model.toggle(skill, in: collection.id) }
            ))
        }
        if !model.collections.isEmpty {
            Divider()
        }
        Button("New Collection…") { model.beginNewCollection(adding: skill) }
    }
}
