import Foundation
import CoreLocation

// Lightweight helpers to work with GeoPackage geometry blobs and WKB LineString/MultiLineString
enum GeoPackageGeometryError: Error {
    case invalidHeader
    case unsupportedGeometryType(UInt32)
    case malformed
}

struct LineStringGeometry {
    let coordinates: [CLLocationCoordinate2D]
}

enum ParsedGeometry {
    case lineString(LineStringGeometry)
    case multiLineString([LineStringGeometry])
}

enum GeoPackageGeometry {
    // Extract WKB payload from a GeoPackage geometry BLOB
    static func extractWKB(from gpkgBlob: Data) throws -> Data {
        guard gpkgBlob.count >= 8 else { throw GeoPackageGeometryError.invalidHeader }
        // Magic "GP"
        if gpkgBlob[0] != 0x47 || gpkgBlob[1] != 0x50 { // 'G','P'
            throw GeoPackageGeometryError.invalidHeader
        }
        // let version = gpkgBlob[2] // currently unused
        let flags = gpkgBlob[3]
        // Envelope indicator bits 1-3 (shift right 1)
        let envelopeIndicator = (flags >> 1) & 0x07
        let envelopeSize: Int
        switch envelopeIndicator {
        case 0: envelopeSize = 0       // no envelope
        case 1: envelopeSize = 32      // minX, maxX, minY, maxY (4 doubles)
        case 2: envelopeSize = 48      // + Z
        case 3: envelopeSize = 48      // + M
        case 4: envelopeSize = 64      // + Z + M
        default: envelopeSize = 0      // defensive fallback
        }
        let headerSize = 8 + envelopeSize // 2 magic + 1 ver + 1 flags + 4 srsId + envelope
        guard gpkgBlob.count > headerSize else { throw GeoPackageGeometryError.malformed }
        return gpkgBlob.subdata(in: headerSize..<gpkgBlob.count)
    }

    // Parse a WKB payload for LineString / MultiLineString, tolerating Z/M by discarding extra ordinates
    static func parseWKB(_ wkb: Data) throws -> ParsedGeometry {
        var offset = 0
        func read<T>(_ type: T.Type) throws -> T {
            let size = MemoryLayout<T>.size
            guard offset + size <= wkb.count else { throw GeoPackageGeometryError.malformed }
            let sub = wkb.subdata(in: offset..<offset+size)
            offset += size
            return sub.withUnsafeBytes { $0.load(as: T.self) }
        }
        guard wkb.count >= 5 else { throw GeoPackageGeometryError.malformed }
        let byteOrder = wkb[offset]; offset += 1 // 0=big, 1=little
        let littleEndian = (byteOrder == 1)

        func readUInt32() throws -> UInt32 {
            let v: UInt32 = try read(UInt32.self)
            return littleEndian ? UInt32(littleEndian: v) : UInt32(bigEndian: v)
        }
        func readDouble() throws -> Double {
            let v: UInt64 = try read(UInt64.self)
            let val = littleEndian ? UInt64(littleEndian: v) : UInt64(bigEndian: v)
            return Double(bitPattern: val)
        }

        let geomType = try readUInt32()
        let baseType = Int(geomType % 1000)
        let dimCode = Int(geomType / 1000) // 0=XY, 1=XYZ, 2=XYM, 3=XYZM
        let hasZ = (dimCode == 1 || dimCode == 3)
        let hasM = (dimCode == 2 || dimCode == 3)
        let extraPerPoint = (hasZ ? 1 : 0) + (hasM ? 1 : 0)
        switch baseType {
        case 2: // LineString (XY or with Z/M)
            let n = try readUInt32()
            var coords: [CLLocationCoordinate2D] = []
            coords.reserveCapacity(Int(n))
            for _ in 0..<n {
                let x = try readDouble() // X = lon
                let y = try readDouble() // Y = lat
                coords.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                // discard Z/M values if present
                for _ in 0..<extraPerPoint { _ = try readDouble() }
            }
            return .lineString(LineStringGeometry(coordinates: coords))
        case 5: // MultiLineString (components are WKB LineStrings with own byte order and dims)
            let n = try readUInt32()
            var lines: [LineStringGeometry] = []
            lines.reserveCapacity(Int(n))
            for _ in 0..<n {
                // Sub-geometry WKB begins here
                guard offset + 5 <= wkb.count else { throw GeoPackageGeometryError.malformed }
                let subByteOrder = wkb[offset]; offset += 1
                let subLE = (subByteOrder == 1)
                // read type
                let tRaw: UInt32 = try read(UInt32.self)
                let t = subLE ? UInt32(littleEndian: tRaw) : UInt32(bigEndian: tRaw)
                let subBase = Int(t % 1000)
                let subDim = Int(t / 1000)
                let subHasZ = (subDim == 1 || subDim == 3)
                let subHasM = (subDim == 2 || subDim == 3)
                let subExtra = (subHasZ ? 1 : 0) + (subHasM ? 1 : 0)
                guard subBase == 2 else { throw GeoPackageGeometryError.unsupportedGeometryType(t) }
                // read point count
                let nRaw: UInt32 = try read(UInt32.self)
                let m = subLE ? UInt32(littleEndian: nRaw) : UInt32(bigEndian: nRaw)
                var coords: [CLLocationCoordinate2D] = []
                coords.reserveCapacity(Int(m))
                for _ in 0..<m {
                    // read X,Y
                    let xBits: UInt64 = try read(UInt64.self)
                    let yBits: UInt64 = try read(UInt64.self)
                    let x = Double(bitPattern: subLE ? UInt64(littleEndian: xBits) : UInt64(bigEndian: xBits))
                    let y = Double(bitPattern: subLE ? UInt64(littleEndian: yBits) : UInt64(bigEndian: yBits))
                    coords.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                    // discard Z/M if present
                    for _ in 0..<subExtra { _ = try read(UInt64.self) }
                }
                lines.append(LineStringGeometry(coordinates: coords))
            }
            return .multiLineString(lines)
        default:
            throw GeoPackageGeometryError.unsupportedGeometryType(geomType)
        }
    }

    // Compute the shortest distance (in meters) from a coordinate to a line
    static func distanceMeters(from coordinate: CLLocationCoordinate2D, to line: LineStringGeometry) -> Double {
        guard line.coordinates.count >= 2 else { return Double.greatestFiniteMagnitude }
        let lat0 = coordinate.latitude * .pi / 180
        let metersPerDegLat = 111_132.0
        let metersPerDegLon = 111_320.0 * cos(lat0)

        func toXY(_ c: CLLocationCoordinate2D) -> (x: Double, y: Double) {
            let x = (c.longitude - coordinate.longitude) * metersPerDegLon
            let y = (c.latitude - coordinate.latitude) * metersPerDegLat
            return (x, y)
        }
        let p = (x: 0.0, y: 0.0) // reference at coordinate
        var best = Double.greatestFiniteMagnitude
        for i in 0..<(line.coordinates.count - 1) {
            let a = toXY(line.coordinates[i])
            let b = toXY(line.coordinates[i+1])
            let ab = (x: b.x - a.x, y: b.y - a.y)
            let ap = (x: p.x - a.x, y: p.y - a.y)
            let ab2 = ab.x*ab.x + ab.y*ab.y
            let t = ab2 > 0 ? max(0, min(1, (ap.x*ab.x + ap.y*ab.y)/ab2)) : 0
            let proj = (x: a.x + t*ab.x, y: a.y + t*ab.y)
            let dx = proj.x - p.x
            let dy = proj.y - p.y
            let d = sqrt(dx*dx + dy*dy)
            if d < best { best = d }
        }
        return best
    }
}
