import UIKit
import ImageIO

enum ImageUtils {
    /// Downsamples encoded image data without decoding the full-size bitmap.
    static func downsample(data: Data, maxPixel: CGFloat) -> UIImage? {
        let srcOpts: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOpts as CFDictionary) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Normalises a picked/captured photo to a reasonably sized JPEG for storage.
    static func storageJPEG(from data: Data) -> Data? {
        downsample(data: data, maxPixel: 2400)?.jpegData(compressionQuality: 0.85)
    }

    static func storageJPEG(from image: UIImage) -> Data? {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }
        return storageJPEG(from: data)
    }
}
