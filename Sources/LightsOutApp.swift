import SwiftUI

@main
struct LightsOutApp: App {
    @State private var store: ProcessStore

    init() {
        LoginItem.enableOnFirstLaunch()
        let store = ProcessStore()
        store.start()
        _store = State(initialValue: store)
    }

    var body: some Scene {
        // The icon only exists while something is running; an empty menu bar means everything is off.
        MenuBarExtra(isInserted: .constant(!store.processes.isEmpty)) {
            ProcessListView(store: store)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                Text("\(store.processes.count)")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
