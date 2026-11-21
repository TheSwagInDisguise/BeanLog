import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Option A — "Warm Cafe Journal" palette.
enum BL {
    static let cream = Color(hex: 0xF5ECDD)
    static let paper = Color(hex: 0xFFFAF1)
    static let cardPaper = Color(hex: 0xF7EEDF)
    static let polaroid = Color(hex: 0xFFFDF8)
    static let espresso = Color(hex: 0x3A2417)
    static let ink2 = Color(hex: 0x5A3B28)
    static let muted = Color(hex: 0x8B6F5B)
    static let terracotta = Color(hex: 0xC4623F)
    static let sage = Color(hex: 0x7E9A73)
    static let ochre = Color(hex: 0xD9A55B)
    static let line = Color(hex: 0xE4D3BA)
    static let chip = Color(hex: 0xFBF3E6)
    static let stage = Color(hex: 0xE8DCC6)
    static let sheet = Color(hex: 0xF8F0E3)
    static let onAccent = Color(hex: 0xFFF8EE)
    static let tape = Color(hex: 0xD6BE96, opacity: 0.62)
    static let stampRed = Color(hex: 0xC8372A)
}

enum BLFont {
    /// Fraunces SemiBold Italic — headings, cafe names.
    static func display(_ size: CGFloat) -> Font { .custom("Fraunces-SemiBoldItalic", fixedSize: size) }
    /// Fraunces SemiBold — numbers / scores.
    static func serif(_ size: CGFloat) -> Font { .custom("Fraunces-SemiBold", fixedSize: size) }
    /// Caveat Bold — handwriting.
    static func hand(_ size: CGFloat) -> Font { .custom("Caveat-Bold", fixedSize: size) }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }
}

/// Cream paper background with a subtle grain, used behind every screen.
struct PaperBackground: View {
    var color: Color = BL.cream
    var body: some View {
        color
            .overlay(Image("paper_grain").resizable(resizingMode: .tile).opacity(0.7))
            .ignoresSafeArea()
    }
}

/// A rounded cream "card" container used to group form rows.
struct BLGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(BL.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(BL.line, lineWidth: 1))
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(BLFont.ui(11, .bold))
            .tracking(0.9)
            .foregroundStyle(BL.muted)
            .padding(.horizontal, 6)
    }
}

enum Fmt {
    static func score(_ v: Double) -> String { String(format: "%.1f", v) }
    static func price(_ v: Double?) -> String {
        guard let v else { return "—" }
        return String(format: "$%.2f", v)
    }
    static func shortDate(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
    static func time(_ d: Date) -> String {
        d.formatted(date: .omitted, time: .shortened)
    }
}
