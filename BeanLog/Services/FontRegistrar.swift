import Foundation
import CoreText

/// Registers the bundled OFL fonts (Fraunces, Caveat) at launch so no Info.plist entry is needed.
enum FontRegistrar {
    static func registerAll() {
        var urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        urls += Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in Set(urls) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
