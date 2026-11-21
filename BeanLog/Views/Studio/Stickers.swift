import SwiftUI

enum StickerKind: Hashable {
    case asset(String)
    case emoji(String)
    case scoreStamp
}

struct StickerItem: Identifiable, Equatable {
    var id = UUID()
    var kind: StickerKind
    /// Centre position, normalised 0…1 across the card so it survives ratio changes.
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1
    /// Degrees.
    var rotation: Double = 0
}

enum StickerCatalog {
    /// Bundled watercolour & ink-sketch stickers (Assets.xcassets).
    static let tray: [StickerKind] = [
        .asset("sticker_cup"), .asset("sticker_heart"), .asset("sticker_croissant"), .asset("sticker_beans"),
        .asset("sticker_sparkles"), .asset("sticker_arrow"), .scoreStamp, .asset("sticker_banner"), .asset("sticker_scribble")
    ]
    static let quickEmoji = ["☕️", "🥐", "🤎", "✨", "🍪", "🌿", "🔥", "💯", "🫶", "🥛", "🧋", "🍵", "☀️", "🌧️", "📍", "⭐️"]
}

/// Draws a sticker's artwork at its base size (≈96pt).
struct StickerContentView: View {
    let kind: StickerKind
    let score: Double

    var body: some View {
        switch kind {
        case .asset(let name):
            Image(name).resizable().scaledToFit().frame(width: 96, height: 96)
        case .emoji(let text):
            Text(text)
                .font(.system(size: 64))
                .lineLimit(1)
                .fixedSize()
        case .scoreStamp:
            ZStack {
                Image("sticker_stamp").resizable().scaledToFit()
                Text(Fmt.score(score))
                    .font(.system(size: 26, weight: .heavy, design: .monospaced))
                    .foregroundStyle(BL.stampRed.opacity(0.9))
                    .offset(y: 2)
            }
            .frame(width: 96, height: 96)
        }
    }
}

/// An interactive sticker/emoji layer: drag to move, pinch to scale, two-finger rotate, tap to remove.
struct StickerLayerView: View {
    @Binding var item: StickerItem
    let canvasSize: CGSize
    let score: Double
    var onRemove: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var twist: Angle = .zero

    var body: some View {
        StickerContentView(kind: item.kind, score: score)
            .scaleEffect(item.scale * pinch)
            .rotationEffect(.degrees(item.rotation) + twist)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(pinchRotateGesture)
            .onTapGesture(perform: onRemove)
            .position(x: item.x * canvasSize.width + dragOffset.width,
                      y: item.y * canvasSize.height + dragOffset.height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: NamedCoordinateSpace.named("card"))
            .updating($dragOffset) { value, state, _ in state = value.translation }
            .onEnded { value in
                item.x = min(1.05, max(-0.05, item.x + value.translation.width / canvasSize.width))
                item.y = min(1.05, max(-0.05, item.y + value.translation.height / canvasSize.height))
            }
    }

    private var pinchRotateGesture: some Gesture {
        let magnify = MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in item.scale = min(4, max(0.3, item.scale * value.magnification)) }
        let rotate = RotateGesture()
            .updating($twist) { value, state, _ in state = value.rotation }
            .onEnded { value in item.rotation += value.rotation.degrees }
        return magnify.simultaneously(with: rotate)
    }
}
