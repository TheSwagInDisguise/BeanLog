import SwiftUI
import Observation

enum AppTab: Hashable {
    case journal
    case studio
}

/// Which log/edit sheet is showing.
enum LogSheet: Identifiable {
    case new
    case edit(CoffeeEntry)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let entry): return entry.id.uuidString
        }
    }
}

@Observable
final class AppState {
    var tab: AppTab = .journal
    var logSheet: LogSheet? = nil
    var studioEntryID: UUID? = nil
    var studio = StudioModel()

    func openStudio(for entry: CoffeeEntry) {
        studioEntryID = entry.id
        tab = .studio
    }
}

/// Share Studio state lives here so stickers survive tab switches.
@Observable
final class StudioModel {
    var ratio: CardRatio
    var fields: Set<CardField> = Set(CardField.allCases)
    var stickers: [StickerItem] = [
        StickerItem(kind: .asset("sticker_heart"), x: 0.82, y: 0.42, scale: 0.85, rotation: 14),
        StickerItem(kind: .asset("sticker_sparkles"), x: 0.14, y: 0.10, scale: 0.7, rotation: -8)
    ]

    init() {
        let raw = UserDefaults.standard.string(forKey: "defaultRatio") ?? CardRatio.story.rawValue
        ratio = CardRatio(rawValue: raw) ?? .story
    }

    func toggle(_ field: CardField) {
        if fields.contains(field) { fields.remove(field) } else { fields.insert(field) }
    }
}
