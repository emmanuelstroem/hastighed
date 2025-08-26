import Foundation
import CoreLocation
import os.log
import SQLite3
import Combine

final class GeoPackageSpeedLimitService: ObservableObject {
    private let logger = Logger(subsystem: "com.eopio.hastighed", category: "GeoPackageSpeedLimitService")
    private var db: OpaquePointer?

    @Published var currentSpeedLimit: Int?
    @Published var currentSpeedLimitRawValue: Int?
    @Published var currentSpeedLimitRawUnit: String?
    @Published var errorMessage: String?
    // Search radius configuration (in meters)
    var minSearchRadiusMeters: Double = 1.0
    var maxSearchRadiusMeters: Double = 20.0

    init(geoPackageFileName: String = "denmark.gpkg") {
        openGeoPackage(named: geoPackageFileName)
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    private func openGeoPackage(named fileName: String) {
        // 1) Document directory override
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let docURL = docs.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: docURL.path) {
            openDB(at: docURL)
            return
        }
        // 2) Bundle fallback in gpkg/
        if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "gpkg") {
            // Copy to documents to allow sqlite read-write if needed
            do {
                try FileManager.default.copyItem(at: bundleURL, to: docURL)
            } catch {
                // If already copied, ignore error
            }
            openDB(at: docURL)
            return
        }
        // 3) Root bundle
        if let bundleURL = Bundle.main.url(forResource: (fileName as NSString).deletingPathExtension, withExtension: (fileName as NSString).pathExtension) {
            do { try FileManager.default.copyItem(at: bundleURL, to: docURL) } catch {}
            openDB(at: docURL)
            return
        }
    self.errorMessage = "GeoPackage not found: \(fileName)"
    logger.error("GeoPackage not found: \(fileName)")
    print("[GPKG] GeoPackage not found: \(fileName)")
    }

    private func openDB(at url: URL) {
        if sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            logger.info("Opened GeoPackage at \(url.path)")
            print("[GPKG] Opened GeoPackage at: \(url.path)")
        } else {
            errorMessage = "Failed to open GeoPackage"
            print("[GPKG] Failed to open GeoPackage at: \(url.path)")
        }
    }

    // Public API: compute only (no publish)
    func querySpeedLimit(for location: CLLocation) -> Int? {
        guard let db else { return nil }
    // Determine target feature table and geometry info
    guard let table = detectRoadsTable(db: db) else {
            logger.error("No suitable roads table detected in GeoPackage")
            return nil
        }
    let (geomCol, srsId) = getGeometryInfo(for: table)
    let pkCol = getPrimaryKeyColumn(for: table) ?? "ROWID"
    logger.info("GPKG query started for lat=\(location.coordinate.latitude, privacy: .public), lon=\(location.coordinate.longitude, privacy: .public) on table=\(table, privacy: .public), srs=\(srsId, privacy: .public), geom=\(geomCol, privacy: .public), pk=\(pkCol, privacy: .public)")
    print(String(format: "[GPKG] Query at lat=%.6f lon=%.6f table=%@ srs=%d geom=%@ pk=%@", location.coordinate.latitude, location.coordinate.longitude, table, srsId, geomCol, pkCol))

        // Expand search radius from min -> max (meters) until a candidate is found
        var radiusMeters = max(0.5, minSearchRadiusMeters)
        let maxMeters = max(maxSearchRadiusMeters, radiusMeters)
        while radiusMeters <= maxMeters + 1e-6 {
            print(String(format: "[GPKG] Trying radius: %.0f m", radiusMeters))
            let bbox = computeSearchBBox(forSRS: srsId, around: location.coordinate, meterRadius: radiusMeters)
            print(String(format: "[GPKG] BBOX minX=%.6f minY=%.6f maxX=%.6f maxY=%.6f (srs=%d)", bbox.minX, bbox.minY, bbox.maxX, bbox.maxY, srsId))
            if let candidate = queryNearestFeature(in: table, pkCol: pkCol, geomCol: geomCol, srsId: srsId, bbox: bbox, near: location.coordinate, searchRadiusMeters: radiusMeters) {
                if let parsed = parseRawAndKmh(from: candidate.tags) {
                    logger.info("GPKG match row=\(candidate.rowid, privacy: .public) -> kmh=\(parsed.kmh ?? -1, privacy: .public) raw=\(parsed.rawValue?.description ?? "nil", privacy: .public) unit=\(parsed.rawUnit ?? "nil", privacy: .public)")
                    self.currentSpeedLimitRawValue = parsed.rawValue
                    self.currentSpeedLimitRawUnit = parsed.rawUnit
                    print("[GPKG] Result: row=\(candidate.rowid) kmh=\(parsed.kmh ?? -1) raw=\(parsed.rawValue?.description ?? "nil") unit=\(parsed.rawUnit ?? "nil") at radius=\(Int(radiusMeters)) m")
                    return parsed.kmh
                }
                if let highway = candidate.tags["highway"], let fallback = defaultSpeed(for: highway) {
                    print("[GPKG] Fallback speed=\(fallback) km/h from highway=\(highway) at radius=\(Int(radiusMeters)) m")
                    self.currentSpeedLimitRawValue = nil
                    self.currentSpeedLimitRawUnit = nil
                    return fallback
                }
            }
            radiusMeters += 1.0
        }
        logger.info("GPKG returned no speed limit for this point after expanding to \(maxMeters, privacy: .public) m")
        print("[GPKG] No speed limit found up to \(Int(maxMeters)) m")
        self.currentSpeedLimitRawValue = nil
        self.currentSpeedLimitRawUnit = nil
        return nil
    }

    // Public API: compute, publish, and persist
    func querySpeedLimitAndPublish(for location: CLLocation) {
        let result = querySpeedLimit(for: location)
        DispatchQueue.main.async {
            self.currentSpeedLimit = result
            if let value = result { UserDefaults.standard.set(value, forKey: "currentSpeedLimit") }
            UserDefaults.standard.set(self.currentSpeedLimitRawValue, forKey: "currentSpeedLimitRawValue")
            UserDefaults.standard.set(self.currentSpeedLimitRawUnit, forKey: "currentSpeedLimitRawUnit")
        }
    }

    // Back-compat no-ops for LocationManager wiring
    func updateStreetName(_ streetName: String) { /* not required for gpkg lookup */ }
    func updateCurrentLocation(_ location: CLLocation) { /* not required for gpkg lookup */ }
    func querySpeedLimitImmediately(for location: CLLocation) { querySpeedLimitAndPublish(for: location) }
    func getStoredSpeedLimit() -> Int? { UserDefaults.standard.object(forKey: "currentSpeedLimit") as? Int }
    func getStoredSpeedLimitRaw() -> (Int?, String?) {
        let val = UserDefaults.standard.object(forKey: "currentSpeedLimitRawValue") as? Int
        let unit = UserDefaults.standard.object(forKey: "currentSpeedLimitRawUnit") as? String
        return (val, unit)
    }

    private func detectRoadsTable(db: OpaquePointer) -> String? {
        // Prefer table names containing road keywords and having useful columns
        let sql = "SELECT table_name FROM gpkg_geometry_columns"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        var candidates: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let c = sqlite3_column_text(stmt, 0) {
                candidates.append(String(cString: c))
            }
        }
        func score(_ name: String) -> Int {
            let n = name.lowercased()
            var s = 0
            if n.contains("road") { s += 3 }
            if n.contains("highway") { s += 3 }
            if n.contains("ways") { s += 2 }
            if n.contains("line") { s += 1 }
            let cols = getColumnSet(for: name)
            if cols.contains("highway") { s += 5 }
            if cols.contains("maxspeed") || cols.contains("max_speed") || cols.contains("speed_limit") { s += 4 }
            if ["tags","other_tags","properties","attrs","json"].contains(where: { cols.contains($0) }) { s += 2 }
            return s
        }
        let best = candidates.max(by: { score($0) < score($1) })
        return best ?? candidates.first
    }

    private struct Feature {
        let rowid: Int64
        let wkb: Data
        let tags: [String: String]
    }

    private func queryNearestFeature(in table: String, pkCol: String, geomCol: String, srsId: Int, bbox: (minX: Double, minY: Double, maxX: Double, maxY: Double), near coord: CLLocationCoordinate2D, searchRadiusMeters: Double) -> Feature? {
        guard let db else { return nil }
        // Geometry column already provided
        // Discover available columns to avoid referencing non-existent ones
        let columnSet = getColumnSet(for: table)
        // Pick an optional free-form tags column if present
        let tagsCol: String? = ["tags", "other_tags", "properties", "attrs", "json"].first(where: { columnSet.contains($0) })
        // Pick optional direct attributes if present
        let maxspeedCol: String? = ["maxspeed", "max_speed", "speed_limit"].first(where: { columnSet.contains($0) })
        let highwayCol: String? = columnSet.contains("highway") ? "highway" : nil
    logger.debug("Columns detected for \(table, privacy: .public): geom=\(geomCol, privacy: .public), tagsCol=\(tagsCol ?? "none", privacy: .public), maxspeedCol=\(maxspeedCol ?? "none", privacy: .public), highwayCol=\(highwayCol ?? "none", privacy: .public)")
    print("[GPKG] Columns: geom=\(geomCol) tagsCol=\(tagsCol ?? "none") maxspeedCol=\(maxspeedCol ?? "none") highwayCol=\(highwayCol ?? "none")")

        // Try RTree index per GPKG spec: rtree_{table}_{geomCol}
        let rtree = "rtree_\(table)_\(geomCol)"
        var hasRtree = false
        do { hasRtree = try tableExists(name: rtree) } catch { hasRtree = false }
    logger.debug("RTree present: \(hasRtree, privacy: .public) name=\(rtree, privacy: .public)")
    print("[GPKG] RTree: \(hasRtree ? "yes" : "no") name=\(rtree)")

        // Build SELECT list dynamically: PK, geom, [tags?], [maxspeed?], [highway?]
        var selectCols = ["t.\(pkCol)", "t.\(geomCol)"]
        if let tcol = tagsCol { selectCols.append("t.\(tcol)") }
        if let mcol = maxspeedCol { selectCols.append("t.\(mcol)") }
        if let hcol = highwayCol { selectCols.append("t.\(hcol)") }
        let selectList = selectCols.joined(separator: ", ")

        let sql: String
        if hasRtree {
            sql = """
            SELECT \(selectList)
            FROM \(table) t
            JOIN \(rtree) r ON t.\(pkCol) = r.id
            WHERE r.minx <= ? AND r.maxx >= ? AND r.miny <= ? AND r.maxy >= ?
            LIMIT 200
            """
        } else {
            // Fallback without spatial functions: pull a limited set and filter by distance in code
            sql = """
            SELECT \(selectList)
            FROM \(table) t
            LIMIT 1000
            """
        }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logger.error("Failed to prepare SQL for nearest feature lookup")
            print("[GPKG] Failed to prepare SQL for nearest feature lookup")
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        if hasRtree {
            // Intersection: r.minx <= queryMaxX AND r.maxx >= queryMinX AND r.miny <= queryMaxY AND r.maxy >= queryMinY
            let queryMinX = bbox.minX
            let queryMaxX = bbox.maxX
            let queryMinY = bbox.minY
            let queryMaxY = bbox.maxY
            sqlite3_bind_double(stmt, 1, queryMaxX) // r.minx <= maxX
            sqlite3_bind_double(stmt, 2, queryMinX) // r.maxx >= minX
            sqlite3_bind_double(stmt, 3, queryMaxY) // r.miny <= maxY
            sqlite3_bind_double(stmt, 4, queryMinY) // r.maxy >= minY
        }

        var best: Feature?
        var bestDist = Double.greatestFiniteMagnitude
        var rowCount = 0
        while sqlite3_step(stmt) == SQLITE_ROW {
            rowCount += 1
            let rowid = sqlite3_column_int64(stmt, 0)
            // geometry blob
            guard let blob = sqlite3_column_blob(stmt, 1) else { continue }
            let len = Int(sqlite3_column_bytes(stmt, 1))
            let data = Data(bytes: blob, count: len)
            // Build tags from available columns
            var tags: [String: String] = [:]
            var nextColIndex = 2
            if tagsCol != nil {
                if let cstr = sqlite3_column_text(stmt, Int32(nextColIndex)) {
                    let text = String(cString: cstr)
                    if let json = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] {
                        for (k, v) in json { if let s = v as? String { tags[k] = s } else if let n = v as? NSNumber { tags[k] = n.stringValue } }
                    } else {
                        // parse semicolon separated k=v
                        for part in text.split(separator: ";") {
                            let kv = part.split(separator: "=", maxSplits: 1)
                            if kv.count == 2 { tags[String(kv[0]).trimmingCharacters(in: .whitespaces)] = String(kv[1]).trimmingCharacters(in: .whitespaces) }
                        }
                    }
                }
                nextColIndex += 1
            }
            if maxspeedCol != nil {
                if let cstr = sqlite3_column_text(stmt, Int32(nextColIndex)) {
                    tags["maxspeed"] = String(cString: cstr)
                }
                nextColIndex += 1
            }
            if highwayCol != nil {
                if let cstr = sqlite3_column_text(stmt, Int32(nextColIndex)) {
                    tags["highway"] = String(cString: cstr)
                }
                nextColIndex += 1
            }

            // compute distance
            do {
                let wkb = try GeoPackageGeometry.extractWKB(from: data)
                let parsed = try GeoPackageGeometry.parseWKB(wkb)
                let d: Double
                switch parsed {
                case .lineString(let ls):
                    d = distanceMeters(forSRS: srsId, from: coord, to: ls)
                case .multiLineString(let mls):
                    d = mls.map { distanceMeters(forSRS: srsId, from: coord, to: $0) }.min() ?? .greatestFiniteMagnitude
                }
                // Reject far objects quickly using computed distance when no RTree
                if !hasRtree {
                    let within = d <= (searchRadiusMeters * 2.0) // small buffer to account for bbox/line segments
                    if !within { continue }
                }
                if d < bestDist { bestDist = d; best = Feature(rowid: rowid, wkb: wkb, tags: tags) }
            } catch {
                continue
            }
        }
        logger.debug("Nearest feature scan complete. Rows=\(rowCount, privacy: .public), bestDist=\(bestDist, privacy: .public)")
        print(String(format: "[GPKG] Scan complete rows=%d bestDist=%.2f m", rowCount, bestDist))
        // Only accept a candidate if it's within the current search radius
        if let best, bestDist.isFinite, bestDist <= searchRadiusMeters { return best }
        return nil
    }

    private func getPrimaryKeyColumn(for table: String) -> String? {
        guard let db else { return nil }
        let sql = "PRAGMA table_info(\(table))"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            while sqlite3_step(stmt) == SQLITE_ROW {
                // columns: cid, name, type, notnull, dflt_value, pk
                let pkFlag = sqlite3_column_int(stmt, 5)
                if pkFlag > 0, let c = sqlite3_column_text(stmt, 1) {
                    return String(cString: c)
                }
            }
        }
        return nil
    }

    private func getGeometryInfo(for table: String) -> (String, Int) {
        // Returns (geometry column name, srs_id)
        guard let db else { return (getGeometryColumn(for: table) ?? "geom", 4326) }
        let sql = "SELECT column_name, srs_id FROM gpkg_geometry_columns WHERE table_name=? LIMIT 1"
        var stmt: OpaquePointer?
        var geomCol = "geom"
        var srsId = 4326
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            table.withCString { cstr in
                sqlite3_bind_text(stmt, 1, cstr, -1, SQLITE_TRANSIENT)
            }
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let c = sqlite3_column_text(stmt, 0) { geomCol = String(cString: c) }
                srsId = Int(sqlite3_column_int(stmt, 1))
            }
        }
        return (geomCol, srsId)
    }

    private func computeSearchBBox(forSRS srsId: Int, around coord: CLLocationCoordinate2D, meterRadius r: Double) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        if srsId == 3857 {
            let p = webMercatorXY(from: coord)
            return (p.x - r, p.y - r, p.x + r, p.y + r)
        } else {
            let deg = searchBBoxDegrees(around: coord, meterRadius: r)
            return (deg.0, deg.1, deg.2, deg.3)
        }
    }

    private func webMercatorXY(from c: CLLocationCoordinate2D) -> (x: Double, y: Double) {
        let originShift = 20037508.342789244
        let x = c.longitude * originShift / 180.0
        var y = log(tan((90.0 + c.latitude) * Double.pi / 360.0)) / (Double.pi / 180.0)
        y = y * originShift / 180.0
        // clamp y to WebMercator max
        let maxY = originShift
        let minY = -originShift
        return (x, min(max(y, minY), maxY))
    }

    private func distanceMeters(forSRS srsId: Int, from coord: CLLocationCoordinate2D, to line: LineStringGeometry) -> Double {
        if srsId == 3857 {
            // Interpret line coordinates as WebMercator meters stored in (lon=x, lat=y)
            let p = webMercatorXY(from: coord)
            var best = Double.greatestFiniteMagnitude
            for i in 0..<(line.coordinates.count - 1) {
                let a = (x: line.coordinates[i].longitude, y: line.coordinates[i].latitude)
                let b = (x: line.coordinates[i+1].longitude, y: line.coordinates[i+1].latitude)
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
        } else {
            return GeoPackageGeometry.distanceMeters(from: coord, to: line)
        }
    }

    private func getGeometryColumn(for table: String) -> String? {
        guard let db else { return nil }
        let sql = "SELECT column_name FROM gpkg_geometry_columns WHERE table_name=? LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        table.withCString { cstr in
            sqlite3_bind_text(stmt, 1, cstr, -1, SQLITE_TRANSIENT)
        }
        if sqlite3_step(stmt) == SQLITE_ROW, let c = sqlite3_column_text(stmt, 0) {
            return String(cString: c)
        }
        return nil
    }

    private func getColumnSet(for table: String) -> Set<String> {
        guard let db else { return [] }
        var cols: Set<String> = []
        let sql = "PRAGMA table_info(\(table))"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let c = sqlite3_column_text(stmt, 1) {
                    cols.insert(String(cString: c))
                }
            }
        }
        return cols
    }

    private func tableExists(name: String) throws -> Bool {
        guard let db else { return false }
        let sql = "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        // Bind Swift string as C string with transient lifetime
        name.withCString { cstr in
            sqlite3_bind_text(stmt, 1, cstr, -1, SQLITE_TRANSIENT)
        }
        let rc = sqlite3_step(stmt)
        return rc == SQLITE_ROW
    }

    private func parseRawAndKmh(from tags: [String: String]) -> (rawValue: Int?, rawUnit: String?, kmh: Int?)? {
        // Try explicit columns first
        if let raw = tags["maxspeed_raw"], !raw.trimmingCharacters(in: .whitespaces).isEmpty {
            let tokens = raw.split(separator: " ")
            let rawVal = tokens.first.flatMap { Int($0) }
            let rawUnit = tokens.count > 1 ? String(tokens[1]) : nil
            var kmh: Int?
            if let ru = rawUnit?.lowercased() {
                if ru == "mph" { if let rv = rawVal { kmh = Int((Double(rv) * 1.60934).rounded()) } }
                else if ru == "km/h" || ru == "kmh" { kmh = rawVal }
            }
            if kmh == nil, let s = tags["maxspeed_kmh"], let n = Double(s.filter({ $0.isNumber || $0 == "." })) { kmh = Int(n.rounded()) }
            return (rawVal, rawUnit, kmh)
        }
        // Else infer from common tags
        let keys = ["maxspeed", "max_speed", "speed_limit"]
        for k in keys {
            if let v = tags[k]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                let tokens = v.split(separator: " ")
                let rawVal = tokens.first.flatMap { Int($0.filter({ $0.isNumber })) }
                let rawUnit = tokens.count > 1 ? String(tokens[1]) : nil
                // Compute kmh fallback if needed
                let lower = v.lowercased().replacingOccurrences(of: " ", with: "")
                var kmh: Int?
                if lower.hasSuffix("mph"), let num = Double(lower.dropLast(3).filter({ $0.isNumber || $0 == "." })) { kmh = Int((num * 1.60934).rounded()) }
                else if lower.hasSuffix("km/h") || lower.hasSuffix("kmh"), let num = Double(lower.replacingOccurrences(of: "km/h", with: "").replacingOccurrences(of: "kmh", with: "").filter({ $0.isNumber || $0 == "." })) { kmh = Int(num.rounded()) }
                else if let num = Double(lower.filter({ $0.isNumber || $0 == "." })) { kmh = Int(num.rounded()) }
                return (rawVal, rawUnit, kmh)
            }
        }
        // Finally, try explicit kmh
        if let s = tags["maxspeed_kmh"], let n = Double(s.filter({ $0.isNumber || $0 == "." })) {
            return (nil, nil, Int(n.rounded()))
        }
        return nil
    }

    private func defaultSpeed(for highway: String) -> Int? {
        switch highway.lowercased() {
        case "motorway", "trunk": return 110
        case "primary", "secondary": return 80
        case "tertiary", "unclassified": return 60
        case "residential", "service": return 30
        case "living_street": return 20
        default: return nil
        }
    }

    private func searchBBoxDegrees(around c: CLLocationCoordinate2D, meterRadius r: Double) -> (Double, Double, Double, Double) {
        let latRad = c.latitude * .pi / 180
        let dLat = r / 111_132.0
        let dLon = r / (111_320.0 * cos(latRad))
        return (c.longitude - dLon, c.latitude - dLat, c.longitude + dLon, c.latitude + dLat)
    }
}
