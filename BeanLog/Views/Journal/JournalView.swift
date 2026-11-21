import SwiftUI
import SwiftData

enum JournalFilter: Hashable, Identifiable {
    case all
    case drink(DrinkType)
    case iced
    case oat
    case eightPlus

    static let pills: [JournalFilter] = [.all, .drink(.flatWhite), .drink(.longBlack), .drink(.batchBrew), .drink(.cortado), .drink(.matcha), .iced, .oat, .eightPlus]

    var id: String { title }
    var title: String {
        switch self {
        case .all: return "All"
        case .drink(let d): return d.rawValue
        case .iced: return "Iced"
        case .oat: return "Oat"
        case .eightPlus: return "8.0+"
        }
    }

    func matches(_ e: CoffeeEntry) -> Bool {
        switch self {
        case .all: return true
        case .drink(let d): return e.drinkType == d
        case .iced: return e.isIced
        case .oat: return e.milkType == .oat
        case .eightPlus: return e.score >= 8
        }
    }
}

struct JournalView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Query(sort: \CoffeeEntry.date, order: .reverse) private var entries: [CoffeeEntry]

    @State private var search = ""
    @State private var filter: JournalFilter = .all
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var pendingDelete: CoffeeEntry?

    private var filtered: [CoffeeEntry] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return entries.filter { e in
            guard filter.matches(e) else { return false }
            guard !q.isEmpty else { return true }
            let hay = ([e.cafeName, e.suburb, e.drinkName, e.roastOrigin, e.milkType.rawValue, e.thoughts] + e.tags)
                .joined(separator: " ").lowercased()
            return hay.contains(q)
        }
    }

    private var monthSpend: Double {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .compactMap(\.price).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    stats
                    searchField
                    pills
                    list
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PaperBackground())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showInsights) { InsightsView() }
            .confirmationDialog("Delete this coffee?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let e = pendingDelete {
                        context.delete(e)
                        try? context.save()
                    }
                    pendingDelete = nil
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("my little coffee journal")
                    .font(BLFont.hand(22))
                    .foregroundStyle(BL.terracotta)
                Text("BeanLog")
                    .font(BLFont.display(36))
                    .foregroundStyle(BL.espresso)
            }
            Spacer()
            HStack(spacing: 8) {
                circleButton("chart.line.uptrend.xyaxis") { showInsights = true }
                circleButton("gearshape") { showSettings = true }
            }
            .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(BL.espresso)
                .frame(width: 40, height: 40)
                .background(BL.paper, in: Circle())
                .overlay(Circle().stroke(BL.line))
        }
        .buttonStyle(.plain)
    }

    private var stats: some View {
        let avg = entries.isEmpty ? 0 : entries.map(\.score).reduce(0, +) / Double(entries.count)
        return HStack(spacing: 8) {
            statBox(value: "\(entries.count)", label: "cups logged")
            statBox(value: Fmt.score(avg), label: "avg score")
            statBox(value: String(format: "$%.0f", monthSpend), label: "this month")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(BLFont.serif(20)).monospacedDigit().foregroundStyle(BL.espresso)
            Text(label).font(BLFont.ui(11)).foregroundStyle(BL.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BL.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BL.line))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(BL.muted)
            TextField("Search cafes, notes, suburbs…", text: $search)
                .font(BLFont.ui(15))
                .foregroundStyle(BL.espresso)
                .submitLabel(.search)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(BL.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(BL.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BL.line))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var pills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(JournalFilter.pills) { f in
                    Button { withAnimation(.snappy) { filter = f } } label: {
                        Text(f.title)
                            .font(BLFont.ui(13, .medium))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 6)
                            .foregroundStyle(filter == f ? BL.cream : BL.espresso)
                            .background(filter == f ? BL.espresso : BL.chip, in: Capsule())
                            .overlay(Capsule().stroke(filter == f ? BL.espresso : BL.line))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .padding(.top, 12)
    }

    @ViewBuilder private var list: some View {
        if entries.isEmpty {
            VStack(spacing: 14) {
                Image("sticker_cup").resizable().scaledToFit().frame(width: 120)
                Text("Your journal is empty.\nLog your first cup!")
                    .font(BLFont.hand(26))
                    .foregroundStyle(BL.ink2)
                    .multilineTextAlignment(.center)
                Button {
                    appState.logSheet = .new
                } label: {
                    Label("Log a coffee", systemImage: "plus")
                        .font(BLFont.ui(15, .bold))
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .foregroundStyle(BL.onAccent)
                        .background(BL.terracotta, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else if filtered.isEmpty {
            Text("No coffees match that yet.")
                .font(BLFont.hand(22))
                .foregroundStyle(BL.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, entry in
                    JournalRow(entry: entry, tilt: index % 2 == 0 ? -3 : 2.5) {
                        appState.openStudio(for: entry)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { appState.logSheet = .edit(entry) }
                    .contextMenu {
                        Button { appState.logSheet = .edit(entry) } label: { Label("Edit", systemImage: "pencil") }
                        Button { appState.openStudio(for: entry) } label: { Label("Make share card", systemImage: "square.and.arrow.up") }
                        Button(role: .destructive) { pendingDelete = entry } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

struct JournalRow: View {
    let entry: CoffeeEntry
    var tilt: Double = -3
    var onShare: () -> Void

    private var line: String {
        var s = entry.isIced ? "iced " : ""
        s += entry.drinkName.lowercased()
        if entry.milkType != .none { s += " · " + entry.milkType.rawValue.lowercased() }
        return s
    }

    var body: some View {
        HStack(spacing: 14) {
            Polaroid(width: 84, caption: "", rotation: tilt, showTape: false) {
                CupPhotoView(entry: entry, maxPixel: 300)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.cafeName)
                    .font(BLFont.serif(18))
                    .foregroundStyle(BL.espresso)
                    .lineLimit(1)
                if !entry.suburb.isEmpty {
                    Text(entry.suburb).font(BLFont.ui(12)).foregroundStyle(BL.muted).lineLimit(1)
                }
                Text(line)
                    .font(BLFont.hand(19))
                    .foregroundStyle(BL.espresso)
                    .lineLimit(1)
                    .padding(.top, 1)
                HStack(spacing: 10) {
                    Text(Fmt.price(entry.price)).font(BLFont.ui(12, .bold)).foregroundStyle(BL.espresso)
                    Text(Fmt.shortDate(entry.date)).font(BLFont.ui(12)).foregroundStyle(BL.muted)
                }
                .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 4) {
                ScoreBadge(score: entry.score, size: 60)
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BL.muted)
                        .frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Make share card")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .background(BL.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(BL.line))
        .shadow(color: Color(hex: 0x785028).opacity(0.06), radius: 0, x: 0, y: 2)
    }
}
