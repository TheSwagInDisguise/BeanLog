import Foundation
import SwiftData

@Model
final class CoffeeEntry {
    var id: UUID = UUID()
    var cafeName: String = ""
    var suburb: String = ""
    var drinkTypeRaw: String = DrinkType.flatWhite.rawValue
    var customDrinkName: String = ""
    var isIced: Bool = false
    var milkTypeRaw: String = MilkType.fullCream.rawValue
    var price: Double? = nil
    var score: Double = 7.5
    var roastOrigin: String = ""
    var tags: [String] = []
    var sweetness: Int = 3
    var acidity: Int = 3
    var thoughts: String = ""
    var date: Date = Date()
    var latitude: Double? = nil
    var longitude: Double? = nil
    @Attribute(.externalStorage) var photoData: Data? = nil
    var createdAt: Date = Date()

    init() {}

    var drinkType: DrinkType {
        get { DrinkType(rawValue: drinkTypeRaw) ?? .custom }
        set { drinkTypeRaw = newValue.rawValue }
    }

    var milkType: MilkType {
        get { MilkType(rawValue: milkTypeRaw) ?? .fullCream }
        set { milkTypeRaw = newValue.rawValue }
    }

    var drinkName: String {
        if drinkType == .custom {
            let trimmed = customDrinkName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Custom" : trimmed
        }
        return drinkType.rawValue
    }

    var temperatureLabel: String { isIced ? "Iced" : "Hot" }

    /// Stable per-entry seed for generated artwork (placeholder cup, torn edges).
    var seed: Int {
        id.uuidString.utf8.reduce(7) { ($0 &* 31 &+ Int($1)) & 0xFFFF }
    }

    var placeholderKind: CupPlaceholder.Kind {
        if drinkType == .matcha { return .matcha }
        if drinkType == .longBlack || drinkType == .batchBrew || milkType == .none { return .black }
        return .milk
    }
}
