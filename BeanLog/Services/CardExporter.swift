import SwiftUI
import Photos

@MainActor
enum CardExporter {
    /// Renders the share card (with stickers) to a crisp 3x image: 1080×1920 or 1080×1350 px.
    static func render(entry: CoffeeEntry, fields: Set<CardField>, ratio: CardRatio, stickers: [StickerItem]) -> UIImage? {
        let card = ShareCardCanvas(entry: entry, fields: fields, ratio: ratio, stickers: .constant(stickers), interactive: false)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }

    static func pngFile(_ image: UIImage, name: String) throws -> URL {
        guard let png = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let safe = name.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BeanLog-\(safe.isEmpty ? "card" : safe).png")
        try? FileManager.default.removeItem(at: url)
        try png.write(to: url, options: .atomic)
        return url
    }

    enum SaveError: LocalizedError {
        case denied
        var errorDescription: String? { "BeanLog doesn't have permission to add to your photo library. You can allow it in Settings." }
    }

    /// Saves the PNG bytes losslessly to Photos (add-only permission).
    static func saveToPhotos(_ image: UIImage) async throws {
        guard let png = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: png, options: nil)
        }
    }
}

/// UIKit share sheet.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Identifiable wrapper so a file URL can drive `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
