import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        Group {
            switch appState.tab {
            case .journal: JournalView()
            case .studio: ShareStudioView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            BLTabBar()
        }
        .sheet(item: $appState.logSheet) { sheet in
            switch sheet {
            case .new: LogCoffeeView(entry: nil)
            case .edit(let entry): LogCoffeeView(entry: entry)
            }
        }
    }
}

/// Floating cream tab bar with the big terracotta "log" button.
struct BLTabBar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            tab(.journal, title: "Journal", symbol: "book.closed")
            Spacer()
            Button {
                appState.logSheet = .new
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(BL.onAccent)
                    .frame(width: 52, height: 52)
                    .background(BL.terracotta, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log a coffee")
            Spacer()
            tab(.studio, title: "Studio", symbol: "photo.on.rectangle.angled")
        }
        .padding(.horizontal, 34)
        .frame(height: 64)
        .background(.ultraThinMaterial, in: Capsule())
        .background(BL.paper.opacity(0.6), in: Capsule())
        .overlay(Capsule().stroke(BL.line))
        .shadow(color: Color(hex: 0x28140A).opacity(0.14), radius: 14, y: 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }

    private func tab(_ t: AppTab, title: String, symbol: String) -> some View {
        Button {
            appState.tab = t
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 20, weight: .medium))
                Text(title).font(BLFont.ui(10, .semibold))
            }
            .foregroundStyle(appState.tab == t ? BL.espresso : BL.muted)
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
}
