import SwiftUI
import SwiftData

@main
struct BeanLogApp: App {
    @State private var appState = AppState()

    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
                .tint(BL.terracotta)
        }
        .modelContainer(for: CoffeeEntry.self)
    }
}
