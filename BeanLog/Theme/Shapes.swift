import SwiftUI

/// Deterministic pseudo-random generator so generated art is stable per entry.
struct SeededRandom {
    private var state: UInt64
    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed) &* 0x9E3779B97F4A7C15 &+ 0x1234567 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
    }
}

/// Paper with softly torn edges.
struct TornPaperShape: Shape {
    var seed: Int
    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        var p = Path()
        let cols = 26, rows = 22
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rng.next() * 6))
        for i in 1...cols {
            p.addLine(to: CGPoint(x: rect.minX + rect.width * CGFloat(i) / CGFloat(cols), y: rect.minY + rng.next() * 7))
        }
        for j in 1...rows {
            p.addLine(to: CGPoint(x: rect.maxX - rng.next() * 6, y: rect.minY + rect.height * CGFloat(j) / CGFloat(rows)))
        }
        for i in stride(from: cols - 1, through: 0, by: -1) {
            p.addLine(to: CGPoint(x: rect.minX + rect.width * CGFloat(i) / CGFloat(cols), y: rect.maxY - rng.next() * 8))
        }
        for j in stride(from: rows - 1, through: 1, by: -1) {
            p.addLine(to: CGPoint(x: rect.minX + rng.next() * 6, y: rect.minY + rect.height * CGFloat(j) / CGFloat(rows)))
        }
        p.closeSubpath()
        return p
    }
}

/// Classic latte-art heart.
struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY + h))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.1, y: r.minY + h * 0.18),
                   control1: CGPoint(x: r.minX + w * 0.15, y: r.minY + h * 0.68),
                   control2: CGPoint(x: r.minX - w * 0.1, y: r.minY + h * 0.32))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.minX + w * 0.28, y: r.minY - h * 0.02),
                   control2: CGPoint(x: r.midX, y: r.minY + h * 0.12))
        p.addCurve(to: CGPoint(x: r.maxX - w * 0.1, y: r.minY + h * 0.18),
                   control1: CGPoint(x: r.midX, y: r.minY + h * 0.12),
                   control2: CGPoint(x: r.maxX - w * 0.28, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h),
                   control1: CGPoint(x: r.maxX + w * 0.1, y: r.minY + h * 0.32),
                   control2: CGPoint(x: r.maxX - w * 0.15, y: r.minY + h * 0.68))
        p.closeSubpath()
        return p
    }
}

/// A coffee bean outline with centre crease.
struct BeanShape: Shape {
    func path(in r: CGRect) -> Path {
        Path(ellipseIn: r)
    }
}

struct BeanCrease: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.12))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.12),
                   control1: CGPoint(x: r.midX - r.width * 0.35, y: r.minY + r.height * 0.45),
                   control2: CGPoint(x: r.midX + r.width * 0.35, y: r.minY + r.height * 0.6))
        return p
    }
}
