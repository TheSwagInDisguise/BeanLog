import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \CoffeeEntry.date) private var entries: [CoffeeEntry]

    private struct DrinkAvg: Identifiable {
        let drink: String
        let avg: Double
        let count: Int
        var id: String { drink }
    }

    private var byDrink: [DrinkAvg] {
        Dictionary(grouping: entries, by: \.drinkName)
            .map { DrinkAvg(drink: $0.key, avg: $0.value.map(\.score).reduce(0, +) / Double($0.value.count), count: $0.value.count) }
            .sorted { $0.avg > $1.avg }
    }

    private var topCafe: (String, Double)? {
        let groups = Dictionary(grouping: entries, by: \.cafeName)
        return groups.map { ($0.key, $0.value.map(\.score).reduce(0, +) / Double($0.value.count)) }
            .max { $0.1 < $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Insights").font(BLFont.display(32)).foregroundStyle(BL.espresso)
                    .padding(.horizontal, 4)
                if entries.count < 2 {
                    Text("Log a couple of coffees to see your trends.")
                        .font(BLFont.hand(22)).foregroundStyle(BL.muted)
                } else {
                    summary
                    chartCard(title: "Score over time") {
                        Chart(entries) { e in
                            LineMark(x: .value("Date", e.date), y: .value("Score", e.score))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(BL.terracotta)
                            PointMark(x: .value("Date", e.date), y: .value("Score", e.score))
                                .foregroundStyle(BL.terracotta)
                        }
                        .chartYScale(domain: 0...10)
                        .frame(height: 180)
                    }
                    chartCard(title: "Average by drink") {
                        Chart(byDrink) { d in
                            BarMark(x: .value("Score", d.avg), y: .value("Drink", d.drink))
                                .foregroundStyle(BL.sage)
                                .annotation(position: .trailing) {
                                    Text(Fmt.score(d.avg)).font(BLFont.ui(11, .semibold)).foregroundStyle(BL.ink2)
                                }
                        }
                        .chartXScale(domain: 0...10)
                        .frame(height: CGFloat(max(2, byDrink.count)) * 38)
                    }
                }
            }
            .padding(16)
        }
        .background(PaperBackground())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        let spent = entries.compactMap(\.price).reduce(0, +)
        return VStack(alignment: .leading, spacing: 6) {
            if let top = topCafe {
                (Text("Favourite spot: ").font(BLFont.ui(14)) + Text(top.0).font(BLFont.display(18)))
                    .foregroundStyle(BL.espresso)
                Text("averaging \(Fmt.score(top.1)) / 10").font(BLFont.hand(20)).foregroundStyle(BL.terracotta)
            }
            Text("\(entries.count) cups · \(String(format: "$%.2f", spent)) spent in total")
                .font(BLFont.ui(13)).foregroundStyle(BL.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BL.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(BL.line))
    }

    private func chartCard<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(BLFont.serif(16)).foregroundStyle(BL.espresso)
            content()
        }
        .padding(16)
        .background(BL.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(BL.line))
    }
}
