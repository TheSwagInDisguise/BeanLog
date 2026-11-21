import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CoffeeEntryDTO: Codable {
    var id: UUID
    var cafeName: String
    var suburb: String
    var drinkType: String
    var customDrinkName: String
    var isIced: Bool
    var milkType: String
    var price: Double?
    var score: Double
    var roastOrigin: String
    var tags: [String]
    var sweetness: Int
    var acidity: Int
    var thoughts: String
    var date: Date
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    var photoFile: String?
}

struct BackupManifest: Codable {
    var app: String = "BeanLog"
    var formatVersion: Int = 1
    var exportedAt: Date
    var entries: [CoffeeEntryDTO]
}

enum BackupService {
    enum BackupError: LocalizedError {
        case missingManifest
        var errorDescription: String? { "This archive doesn't contain a BeanLog backup (backup.json is missing)." }
    }

    enum ImportMode { case merge, replace }

    /// Builds a .zip containing `backup.json` plus `photos/<uuid>.jpg` for every entry that has a photo.
    static func makeArchive(entries: [CoffeeEntry]) throws -> Data {
        var files: [(path: String, data: Data)] = []
        var dtos: [CoffeeEntryDTO] = []
        for e in entries {
            var photoFile: String? = nil
            if let photo = e.photoData {
                let path = "photos/\(e.id.uuidString).jpg"
                photoFile = path
                files.append((path: path, data: photo))
            }
            dtos.append(CoffeeEntryDTO(id: e.id, cafeName: e.cafeName, suburb: e.suburb, drinkType: e.drinkTypeRaw,
                                       customDrinkName: e.customDrinkName, isIced: e.isIced, milkType: e.milkTypeRaw,
                                       price: e.price, score: e.score, roastOrigin: e.roastOrigin, tags: e.tags,
                                       sweetness: e.sweetness, acidity: e.acidity, thoughts: e.thoughts, date: e.date,
                                       latitude: e.latitude, longitude: e.longitude, createdAt: e.createdAt, photoFile: photoFile))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let manifest = try encoder.encode(BackupManifest(exportedAt: Date(), entries: dtos))
        files.insert((path: "backup.json", data: manifest), at: 0)
        return ZipArchive.write(files)
    }

    /// Restores entries from an archive. Returns the number of entries imported.
    @discardableResult
    static func restore(from data: Data, into context: ModelContext, mode: ImportMode) throws -> Int {
        let files = try ZipArchive.read(data)
        guard let json = files["backup.json"] ?? files.first(where: { $0.key.hasSuffix("/backup.json") })?.value else {
            throw BackupError.missingManifest
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(BackupManifest.self, from: json)

        var existing = Set<UUID>()
        if mode == .replace {
            try context.delete(model: CoffeeEntry.self)
        } else {
            existing = Set(try context.fetch(FetchDescriptor<CoffeeEntry>()).map(\.id))
        }

        var imported = 0
        for dto in manifest.entries where !existing.contains(dto.id) {
            let e = CoffeeEntry()
            e.id = dto.id
            e.cafeName = dto.cafeName
            e.suburb = dto.suburb
            e.drinkTypeRaw = dto.drinkType
            e.customDrinkName = dto.customDrinkName
            e.isIced = dto.isIced
            e.milkTypeRaw = dto.milkType
            e.price = dto.price
            e.score = dto.score
            e.roastOrigin = dto.roastOrigin
            e.tags = dto.tags
            e.sweetness = dto.sweetness
            e.acidity = dto.acidity
            e.thoughts = dto.thoughts
            e.date = dto.date
            e.latitude = dto.latitude
            e.longitude = dto.longitude
            e.createdAt = dto.createdAt
            if let path = dto.photoFile {
                e.photoData = files[path]
            }
            context.insert(e)
            imported += 1
        }
        try context.save()
        return imported
    }
}

/// Wraps archive bytes for `.fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
