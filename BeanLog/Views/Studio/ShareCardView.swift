import SwiftUI

/// The card plus its sticker layers. Used live in the studio and by ImageRenderer for export.
struct ShareCardCanvas: View {
    let entry: CoffeeEntry
    let fields: Set<CardField>
    let ratio: CardRatio
    @Binding var stickers: [StickerItem]
    var interactive: Bool
    var onRemove: (StickerItem) -> Void = { _ in }

    var body: some View {
        let size = ratio.size
        ZStack {
            JournalCardView(entry: entry, fields: fields, ratio: ratio)
            ForEach($stickers) { $item in
                if interactive {
                    StickerLayerView(item: $item, canvasSize: size, score: entry.score) {
                        onRemove(item)
                    }
                } else {
                    StickerContentView(kind: item.kind, score: entry.score)
                        .scaleEffect(item.scale)
                        .rotationEffect(.degrees(item.rotation))
                        .position(x: item.x * size.width, y: item.y * size.height)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .coordinateSpace(NamedCoordinateSpace.named("card"))
        .clipped()
    }
}

/// Option A "Warm Cafe Journal" share card: torn paper, watercolour washes, taped polaroid,
/// scalloped score stamp, hand-circled tags and bean-dot sweetness/acidity.
struct JournalCardView: View {
    let entry: CoffeeEntry
    let fields: Set<CardField>
    let ratio: CardRatio

    private func has(_ f: CardField) -> Bool { fields.contains(f) }

    var body: some View {
        let size = ratio.size
        ZStack {
            BL.stage
            ZStack(alignment: .topLeading) {
                BL.cardPaper
                Image("paper_grain").resizable(resizingMode: .tile).opacity(0.9)
                washes(size)
                ViewThatFits(in: .vertical) {
                    layout(1.0)
                    layout(0.88)
                    layout(0.76)
                    layout(0.66)
                    layout(0.58)
                }
                .frame(width: size.width, height: size.height, alignment: .top)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(TornPaperShape(seed: entry.seed))
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Pieces

    private func washes(_ size: CGSize) -> some View {
        ZStack {
            Image("wash_terracotta").resizable().frame(width: 210, height: 90).opacity(0.22)
                .position(x: size.width * 0.86, y: size.height * 0.08)
            Image("wash_sage").resizable().frame(width: 150, height: 110).opacity(0.22)
                .position(x: size.width * 0.06, y: size.height * 0.58)
            Image("wash_ochre").resizable().frame(width: 260, height: 80).opacity(0.26)
                .position(x: size.width * 0.7, y: size.height * 0.95)
        }
        .frame(width: size.width, height: size.height)
    }

    private var caption: String {
        var parts: [String] = []
        if has(.temperature) { parts.append(entry.temperatureLabel.lowercased()) }
        if has(.milk) && entry.milkType != .none { parts.append(entry.milkType.rawValue.lowercased()) }
        if has(.drink) { parts.append(entry.drinkName.lowercased()) }
        return parts.joined(separator: " ")
    }

    private func topLine(_ s: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline) {
            if has(.date) {
                Text("\(Fmt.shortDate(entry.date)) · \(Fmt.time(entry.date))")
                    .font(BLFont.hand(19 * s))
                    .foregroundStyle(BL.muted)
            }
            Spacer(minLength: 8)
            Text("BeanLog ☕︎")
                .font(BLFont.display(14 * s))
                .foregroundStyle(BL.terracotta)
        }
    }

    private func polaroid(width: CGFloat) -> some View {
        Polaroid(width: width, caption: caption) {
            CupPhotoView(entry: entry, maxPixel: 1400)
        }
    }

    private func names(_ s: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4 * s) {
            if has(.cafe) {
                Text(entry.cafeName)
                    .font(BLFont.display(30 * s))
                    .foregroundStyle(BL.espresso)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if has(.suburb) && !entry.suburb.isEmpty {
                Label(entry.suburb, systemImage: "mappin")
                    .font(BLFont.ui(12.5 * s))
                    .foregroundStyle(BL.muted)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private func factsText(_ s: CGFloat) -> Text? {
        var items: [String] = []
        if !has(.photo) {
            if has(.drink) { items.append(entry.drinkName) }
            if has(.temperature) { items.append(entry.temperatureLabel) }
            if has(.milk) { items.append(entry.milkType.shortName) }
        }
        if has(.price), entry.price != nil { items.append(Fmt.price(entry.price)) }
        guard !items.isEmpty else { return nil }
        var text = Text(items[0])
        for item in items.dropFirst() {
            text = text + Text("  ✦  ").font(BLFont.ui(12 * s)).foregroundColor(BL.terracotta) + Text(item)
        }
        return text
    }

    @ViewBuilder private func facts(_ s: CGFloat) -> some View {
        if let t = factsText(s) {
            t.font(BLFont.hand(22 * s)).foregroundStyle(BL.espresso)
        }
    }

    @ViewBuilder private func roast(_ s: CGFloat) -> some View {
        if has(.roast) && !entry.roastOrigin.isEmpty {
            (Text("roast  ").font(BLFont.display(13 * s)).foregroundColor(BL.terracotta)
             + Text(entry.roastOrigin).font(BLFont.ui(12.5 * s)).foregroundColor(BL.ink2))
        }
    }

    @ViewBuilder private func tags(_ s: CGFloat) -> some View {
        if has(.tags) && !entry.tags.isEmpty {
            FlowLayout(spacing: 6 * s, lineSpacing: 6 * s) {
                ForEach(Array(entry.tags.enumerated()), id: \.offset) { i, tag in
                    SketchTag(text: tag, fontSize: 19 * s,
                              tint: i % 3 == 0 ? BL.terracotta.opacity(0.14) : (i % 3 == 1 ? BL.sage.opacity(0.18) : .clear))
                }
            }
        }
    }

    @ViewBuilder private func sweetAcid(_ s: CGFloat, stacked: Bool) -> some View {
        if has(.sweetAcid) {
            let sweet = HStack(spacing: 6) {
                Text("sweet").font(BLFont.hand(19 * s))
                BeanDots(value: entry.sweetness, size: 15 * s)
            }
            let acid = HStack(spacing: 6) {
                Text("acidity").font(BLFont.hand(19 * s))
                BeanDots(value: entry.acidity, size: 15 * s)
            }
            if stacked {
                VStack(alignment: .leading, spacing: 4) { sweet; acid }.foregroundStyle(BL.espresso)
            } else {
                HStack(spacing: 18 * s) { sweet; acid }.foregroundStyle(BL.espresso)
            }
        }
    }

    @ViewBuilder private func thoughts(_ s: CGFloat) -> some View {
        if has(.thoughts) && !entry.thoughts.isEmpty {
            Text("“\(entry.thoughts)”")
                .font(BLFont.hand(21 * s))
                .foregroundStyle(BL.espresso)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8 * s)
                .padding(.horizontal, 12 * s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xFFFDF6, opacity: 0.65))
                .overlay(alignment: .leading) { Rectangle().fill(BL.terracotta).frame(width: 3) }
        }
    }

    @ViewBuilder private func header(_ s: CGFloat, badge: CGFloat) -> some View {
        if has(.cafe) || has(.suburb) || has(.score) {
            HStack(alignment: .center, spacing: 10) {
                names(s)
                Spacer(minLength: 0)
                if has(.score) {
                    ScoreBadge(score: entry.score, size: badge, showCaption: true)
                        .rotationEffect(.degrees(8))
                }
            }
        }
    }

    // MARK: Layouts

    @ViewBuilder private func layout(_ s: CGFloat) -> some View {
        if ratio == .feed && has(.photo) {
            feedLayout(s)
        } else {
            storyLayout(s)
        }
    }

    private func storyLayout(_ s: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10 * s) {
            topLine(s)
            if has(.photo) {
                polaroid(width: (ratio == .story ? 288 : 230) * s)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6 * s)
            }
            header(s, badge: 80 * s)
            facts(s)
            roast(s)
            tags(s)
            sweetAcid(s, stacked: false)
            Spacer(minLength: 0)
            thoughts(s)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28 * s)
        .padding(.bottom, 26 * s)
        .frame(width: ratio.size.width, alignment: .leading)
    }

    private func feedLayout(_ s: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 9 * s) {
            topLine(s)
            HStack(alignment: .top, spacing: 14) {
                polaroid(width: 150 * s)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 8 * s) {
                    if has(.score) {
                        ScoreBadge(score: entry.score, size: 62 * s, showCaption: true)
                            .rotationEffect(.degrees(8))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    names(s * 0.8)
                    facts(s * 0.9)
                    roast(s)
                    sweetAcid(s * 0.9, stacked: true)
                }
            }
            tags(s * 0.9)
            Spacer(minLength: 0)
            thoughts(s * 0.88)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24 * s)
        .padding(.bottom, 22 * s)
        .frame(width: ratio.size.width, alignment: .leading)
    }
}
