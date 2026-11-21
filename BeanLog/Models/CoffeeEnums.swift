import SwiftUI

enum DrinkType: String, CaseIterable, Codable, Identifiable {
    case flatWhite = "Flat White"
    case longBlack = "Long Black"
    case batchBrew = "Batch Brew"
    case cortado = "Cortado"
    case matcha = "Matcha"
    case custom = "Custom"

    var id: String { rawValue }
}

enum MilkType: String, CaseIterable, Codable, Identifiable {
    case fullCream = "Full Cream"
    case oat = "Oat"
    case soy = "Soy"
    case almond = "Almond"
    case lactoseFree = "Lactose-Free"
    case none = "Black / None"

    var id: String { rawValue }
    var shortName: String { self == .none ? "No milk" : rawValue }
}

enum TastingTags {
    static let defaults = ["Nutty", "Chocolatey", "Fruity", "Floral", "Silky", "Bitter", "Balanced"]
}

enum CardRatio: String, CaseIterable, Identifiable {
    case story
    case feed

    var id: String { rawValue }
    var title: String { self == .story ? "9:16 Story" : "4:5 Feed Post" }
    /// Logical card size in points. Rendered at 3x → 1080×1920 / 1080×1350 px.
    var size: CGSize { self == .story ? CGSize(width: 360, height: 640) : CGSize(width: 360, height: 450) }
    var pixelLabel: String { self == .story ? "1080×1920" : "1080×1350" }
}

enum CardField: String, CaseIterable, Identifiable {
    case photo, cafe, suburb, drink, temperature, milk, price, score, roast, tags, sweetAcid, date, thoughts

    var id: String { rawValue }
    var title: String {
        switch self {
        case .photo: return "Photo"
        case .cafe: return "Cafe Name"
        case .suburb: return "Suburb"
        case .drink: return "Drink"
        case .temperature: return "Hot/Iced"
        case .milk: return "Milk"
        case .price: return "Price"
        case .score: return "0–10 Score"
        case .roast: return "Roast/Origin"
        case .tags: return "Tasting Tags"
        case .sweetAcid: return "Sweetness/Acidity"
        case .date: return "Date/Time"
        case .thoughts: return "General Thoughts"
        }
    }
}
