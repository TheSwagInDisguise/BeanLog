import Foundation

/// Minimal ZIP writer (stored entries) and reader (stored + deflate) — no third-party code.
enum ZipArchive {
    enum ZipError: LocalizedError {
        case notAZip
        case corrupt
        case unsupportedCompression(UInt16)
        var errorDescription: String? {
            switch self {
            case .notAZip: return "That file isn't a ZIP archive."
            case .corrupt: return "The backup archive looks damaged."
            case .unsupportedCompression(let m): return "Unsupported ZIP compression method (\(m))."
            }
        }
    }

    // MARK: Writing

    static func write(_ files: [(path: String, data: Data)], date: Date = Date()) -> Data {
        var out = Data()
        var central = Data()
        let (dosTime, dosDate) = dosDateTime(date)

        for file in files {
            let name = Data(file.path.utf8)
            let crc = crc32(file.data)
            let size = UInt32(file.data.count)
            let offset = UInt32(out.count)

            out.appendLE(UInt32(0x04034b50))
            out.appendLE(UInt16(20))          // version needed
            out.appendLE(UInt16(0x0800))      // UTF-8 names
            out.appendLE(UInt16(0))           // stored
            out.appendLE(dosTime)
            out.appendLE(dosDate)
            out.appendLE(crc)
            out.appendLE(size)
            out.appendLE(size)
            out.appendLE(UInt16(name.count))
            out.appendLE(UInt16(0))
            out.append(name)
            out.append(file.data)

            central.appendLE(UInt32(0x02014b50))
            central.appendLE(UInt16(20))      // made by
            central.appendLE(UInt16(20))      // needed
            central.appendLE(UInt16(0x0800))
            central.appendLE(UInt16(0))
            central.appendLE(dosTime)
            central.appendLE(dosDate)
            central.appendLE(crc)
            central.appendLE(size)
            central.appendLE(size)
            central.appendLE(UInt16(name.count))
            central.appendLE(UInt16(0))       // extra
            central.appendLE(UInt16(0))       // comment
            central.appendLE(UInt16(0))       // disk
            central.appendLE(UInt16(0))       // internal attrs
            central.appendLE(UInt32(0))       // external attrs
            central.appendLE(offset)
            central.append(name)
        }

        let cdOffset = UInt32(out.count)
        out.append(central)
        out.appendLE(UInt32(0x06054b50))
        out.appendLE(UInt16(0))
        out.appendLE(UInt16(0))
        out.appendLE(UInt16(files.count))
        out.appendLE(UInt16(files.count))
        out.appendLE(UInt32(central.count))
        out.appendLE(cdOffset)
        out.appendLE(UInt16(0))
        return out
    }

    // MARK: Reading

    static func read(_ input: Data) throws -> [String: Data] {
        let data = Data(input) // zero-based indices
        guard data.count >= 22 else { throw ZipError.notAZip }

        var eocd = -1
        var i = data.count - 22
        let lowest = max(0, data.count - 22 - 65_535)
        while i >= lowest {
            if data.u32(i) == 0x06054b50 { eocd = i; break }
            i -= 1
        }
        guard eocd >= 0 else { throw ZipError.notAZip }

        let count = Int(data.u16(eocd + 10))
        var p = Int(data.u32(eocd + 16))
        var files: [String: Data] = [:]

        for _ in 0..<count {
            guard p + 46 <= data.count, data.u32(p) == 0x02014b50 else { throw ZipError.corrupt }
            let method = data.u16(p + 10)
            let compSize = Int(data.u32(p + 20))
            let rawSize = Int(data.u32(p + 24))
            let nameLen = Int(data.u16(p + 28))
            let extraLen = Int(data.u16(p + 30))
            let commentLen = Int(data.u16(p + 32))
            let localOffset = Int(data.u32(p + 42))
            guard p + 46 + nameLen <= data.count else { throw ZipError.corrupt }
            let name = String(decoding: data[(p + 46)..<(p + 46 + nameLen)], as: UTF8.self)
            p += 46 + nameLen + extraLen + commentLen

            if name.hasSuffix("/") || name.hasPrefix("__MACOSX") { continue }
            guard localOffset + 30 <= data.count, data.u32(localOffset) == 0x04034b50 else { throw ZipError.corrupt }
            let lNameLen = Int(data.u16(localOffset + 26))
            let lExtraLen = Int(data.u16(localOffset + 28))
            let start = localOffset + 30 + lNameLen + lExtraLen
            guard start + compSize <= data.count else { throw ZipError.corrupt }
            let payload = data[start..<(start + compSize)]

            switch method {
            case 0:
                files[name] = Data(payload)
            case 8:
                // Apple's .zlib algorithm is raw DEFLATE (RFC 1951) — exactly what ZIP stores.
                let inflated = try (Data(payload) as NSData).decompressed(using: .zlib) as Data
                guard inflated.count == rawSize else { throw ZipError.corrupt }
                files[name] = inflated
            default:
                throw ZipError.unsupportedCompression(method)
            }
        }
        return files
    }

    // MARK: Helpers

    private static let crcTable: [UInt32] = (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        data.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            for byte in buf {
                crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
            }
        }
        return crc ^ 0xFFFFFFFF
    }

    private static func dosDateTime(_ date: Date) -> (UInt16, UInt16) {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = max(1980, c.year ?? 1980)
        let time = UInt16(((c.hour ?? 0) << 11) | ((c.minute ?? 0) << 5) | ((c.second ?? 0) / 2))
        let day = UInt16(((year - 1980) << 9) | ((c.month ?? 1) << 5) | (c.day ?? 1))
        return (time, day)
    }
}

private extension Data {
    mutating func appendLE(_ v: UInt16) {
        append(UInt8(v & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
    }

    mutating func appendLE(_ v: UInt32) {
        append(UInt8(v & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
        append(UInt8((v >> 16) & 0xFF))
        append(UInt8((v >> 24) & 0xFF))
    }

    func u16(_ i: Int) -> UInt16 {
        UInt16(self[i]) | (UInt16(self[i + 1]) << 8)
    }

    func u32(_ i: Int) -> UInt32 {
        UInt32(self[i]) | (UInt32(self[i + 1]) << 8) | (UInt32(self[i + 2]) << 16) | (UInt32(self[i + 3]) << 24)
    }
}
