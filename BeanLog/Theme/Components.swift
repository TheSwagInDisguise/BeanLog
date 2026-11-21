import SwiftUI
import UIKit

/// Wrapping horizontal layout for chips and tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        let width = maxWidth == .greatestFiniteMagnitude ? widest : maxWidth
        return CGSize(width: width, height: subviews.isEmpty ? 0 : y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

struct ChipButton: View {
    let title: String
    let isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BLFont.ui(13, .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(isOn ? BL.onAccent : BL.espresso)
                .background(isOn ? BL.terracotta : BL.chip, in: Capsule())
                .overlay(Capsule().stroke(isOn ? BL.terracotta : BL.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Five little coffee beans showing a 1–5 value.
struct BeanDots: View {
    let value: Int
    var size: CGFloat = 13
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                ZStack {
                    BeanShape().fill(i <= value ? Color(hex: 0x6B3A1F) : Color.clear)
                    BeanShape().stroke(Color(hex: 0x6B3A1F), lineWidth: 1.3)
                    BeanCrease().stroke(i <= value ? BL.cardPaper : Color(hex: 0x6B3A1F), lineWidth: 1)
                }
                .frame(width: size * 0.78, height: size)
            }
        }
    }
}

/// Watercolour scalloped score badge.
struct ScoreBadge: View {
    let score: Double
    var size: CGFloat = 60
    var showCaption: Bool = false

    private var badgeName: String {
        score >= 8 ? "badge_terracotta" : (score >= 7 ? "badge_ochre" : "badge_sage")
    }

    var body: some View {
        ZStack {
            Image(badgeName).resizable().scaledToFit()
            VStack(spacing: -2) {
                Text(Fmt.score(score))
                    .font(BLFont.serif(size * 0.32))
                    .monospacedDigit()
                if showCaption {
                    Text("out of 10").font(BLFont.hand(size * 0.17))
                }
            }
            .foregroundStyle(BL.onAccent)
        }
        .frame(width: size, height: size)
    }
}

/// A hand-circled tasting tag.
struct SketchTag: View {
    let text: String
    var fontSize: CGFloat = 19
    var tint: Color = .clear

    var body: some View {
        Text(text.lowercased())
            .font(BLFont.hand(fontSize))
            .foregroundStyle(BL.espresso)
            .padding(.horizontal, 11)
            .padding(.vertical, 1)
            .background(tint, in: Capsule())
            .overlay(Capsule().stroke(BL.espresso, lineWidth: 1.5))
            .overlay(Capsule().stroke(BL.espresso.opacity(0.55), lineWidth: 0.8).rotationEffect(.degrees(1.2)).offset(x: 0.8, y: -0.6))
    }
}

/// Shows the entry's photo, or a generated cup illustration when none was taken.
struct CupPhotoView: View {
    let entry: CoffeeEntry
    var maxPixel: CGFloat = 1400

    var body: some View {
        if let data = entry.photoData, let image = ImageCache.shared.image(id: entry.id, data: data, maxPixel: maxPixel) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            CupPlaceholder(seed: entry.seed, iced: entry.isIced, kind: entry.placeholderKind)
        }
    }
}

/// Generated top-down cup "photo" used when an entry has no picture.
struct CupPlaceholder: View {
    enum Kind { case milk, black, matcha }
    let seed: Int
    let iced: Bool
    let kind: Kind

    private static let tables: [(Color, Color)] = [
        (Color(hex: 0x9A6A48), Color(hex: 0x5E3B26)),
        (Color(hex: 0xEFE9DF), Color(hex: 0xD2C7B6)),
        (Color(hex: 0xDCCBB0), Color(hex: 0xB39875)),
        (Color(hex: 0x3C3936), Color(hex: 0x1F1C1A)),
        (Color(hex: 0xC9B398), Color(hex: 0xA08667))
    ]
    private static let cups: [Color] = [
        Color(hex: 0xFBF8F2), Color(hex: 0xD9875F), Color(hex: 0xA9B89A), Color(hex: 0x2E2A27), Color(hex: 0xEFE2CF)
    ]

    private var liquid: (Color, Color) {
        switch kind {
        case .milk: return (Color(hex: 0xDDB084), Color(hex: 0x9A5C30))
        case .black: return (Color(hex: 0x8A4B25), Color(hex: 0x2B150A))
        case .matcha: return (Color(hex: 0xC3D28E), Color(hex: 0x84A04F))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let table = Self.tables[abs(seed) % Self.tables.count]
            ZStack {
                LinearGradient(colors: [table.0, table.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                if iced { glass(d) } else { cup(d) }
                RadialGradient(colors: [.clear, .black.opacity(0.35)], center: .center, startRadius: d * 0.32, endRadius: d * 0.8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func liquidFill(_ d: CGFloat) -> RadialGradient {
        RadialGradient(stops: [.init(color: liquid.0, location: 0), .init(color: liquid.0, location: 0.7), .init(color: liquid.1, location: 1)],
                       center: UnitPoint(x: 0.45, y: 0.42), startRadius: 0, endRadius: d * 0.3)
    }

    @ViewBuilder private func art(_ d: CGFloat) -> some View {
        if kind == .black {
            ZStack {
                Circle().stroke(Color(hex: 0xB9743F).opacity(0.35), lineWidth: d * 0.025).frame(width: d * 0.44)
                ForEach(0..<6, id: \.self) { i in
                    Circle().fill(Color(hex: 0xC47C45).opacity(0.25))
                        .frame(width: d * 0.05)
                        .offset(x: d * 0.12 * cos(Double(i + seed)), y: d * 0.12 * sin(Double(i * 2 + seed)))
                }
            }
        } else {
            HeartShape()
                .fill(kind == .matcha ? Color(hex: 0xF4F2DC) : Color(hex: 0xFCF3E4))
                .frame(width: d * 0.27, height: d * 0.24)
                .rotationEffect(.degrees(Double(seed % 36) - 18))
        }
    }

    @ViewBuilder private func cup(_ d: CGFloat) -> some View {
        let cupColor = Self.cups[abs(seed / 3) % Self.cups.count]
        ZStack {
            Circle().fill(cupColor).frame(width: d * 0.84)
                .shadow(color: .black.opacity(0.28), radius: d * 0.04, x: d * 0.03, y: d * 0.05)
            Circle().fill(Color.black.opacity(0.06)).frame(width: d * 0.64)
            Capsule().fill(cupColor).frame(width: d * 0.15, height: d * 0.08)
                .offset(x: d * 0.34)
                .rotationEffect(.degrees(Double(seed % 40) - 20))
            Circle().fill(cupColor).frame(width: d * 0.6)
                .shadow(color: .black.opacity(0.2), radius: d * 0.025, x: d * 0.01, y: d * 0.02)
            Circle().fill(liquidFill(d)).frame(width: d * 0.51)
            art(d)
        }
    }

    @ViewBuilder private func glass(_ d: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.22)).frame(width: d * 0.68)
                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                .shadow(color: .black.opacity(0.28), radius: d * 0.04, x: d * 0.03, y: d * 0.05)
            Circle().fill(liquidFill(d)).frame(width: d * 0.61).opacity(0.94)
            if kind != .black {
                Circle().fill(Color(hex: 0xFCF3E4).opacity(0.35)).frame(width: d * 0.34).offset(x: -d * 0.05, y: -d * 0.04)
            }
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: d * 0.025)
                    .fill(Color.white.opacity(0.38))
                    .overlay(RoundedRectangle(cornerRadius: d * 0.025).stroke(Color.white.opacity(0.75), lineWidth: 1))
                    .frame(width: d * 0.12, height: d * 0.12)
                    .rotationEffect(.degrees(Double((seed * (i + 3)) % 90)))
                    .offset(x: d * 0.14 * cos(Double(i) * 1.7 + Double(seed)), y: d * 0.14 * sin(Double(i) * 1.7 + Double(seed)))
            }
            Circle().fill(Color(hex: 0x2F2A26)).frame(width: d * 0.08)
                .overlay(Circle().fill(Color(hex: 0x100D0B)).frame(width: d * 0.045))
                .offset(x: d * 0.12, y: -d * 0.11)
        }
    }
}

/// White instant-photo frame with tape and an optional handwritten caption.
struct Polaroid<Content: View>: View {
    var width: CGFloat
    var caption: String = ""
    var rotation: Double = -2.2
    var showTape: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        let pad = max(6, width * 0.035)
        VStack(alignment: .leading, spacing: 0) {
            content
                .frame(width: width - pad * 2, height: width - pad * 2)
                .clipped()
            Text(caption)
                .font(BLFont.hand(max(14, width * 0.08)))
                .foregroundStyle(BL.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: max(16, width * 0.12), alignment: .center)
                .padding(.leading, 4)
        }
        .padding([.top, .horizontal], pad)
        .padding(.bottom, pad * 0.6)
        .frame(width: width, alignment: .leading)
        .background(BL.polaroid)
        .shadow(color: Color(hex: 0x46280F).opacity(0.2), radius: 9, x: 0, y: 6)
        .overlay(alignment: .top) {
            if showTape {
                Rectangle().fill(BL.tape)
                    .frame(width: width * 0.3, height: width * 0.08)
                    .rotationEffect(.degrees(4))
                    .offset(y: -width * 0.04)
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

/// Decodes and downsamples photo data once per size.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func image(id: UUID, data: Data, maxPixel: CGFloat) -> UIImage? {
        let key = "\(id.uuidString)-\(Int(maxPixel))-\(data.count)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let img = ImageUtils.downsample(data: data, maxPixel: maxPixel) else { return nil }
        cache.setObject(img, forKey: key)
        return img
    }
}
