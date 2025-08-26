import XCTest
import CoreLocation
@testable import hastighed

final class GeoPackageSpeedLimitServiceTests: XCTestCase {
    var tempDBURL: URL!

    override func setUpWithError() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        tempDBURL = tmp.appendingPathComponent("test.gpkg")
        try? FileManager.default.removeItem(at: tempDBURL)
        try createMinimalGeoPackage(at: tempDBURL)
    }

    override func tearDownWithError() throws {
        if let url = tempDBURL { try? FileManager.default.removeItem(at: url) }
    }

    func testQuerySpeedLimitNearLineString() throws {
        // Copy temp gpkg into Documents so service finds it
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let target = docs.appendingPathComponent("test.gpkg")
        if FileManager.default.fileExists(atPath: target.path) { try? FileManager.default.removeItem(at: target) }
        try FileManager.default.copyItem(at: tempDBURL, to: target)

        let svc = GeoPackageSpeedLimitService(geoPackageFileName: "test.gpkg")

        // Point close to our line (approx Copenhagen area)
        let coord = CLLocationCoordinate2D(latitude: 55.6762, longitude: 12.5685)
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let speed = svc.querySpeedLimit(for: loc)
        XCTAssertEqual(speed, 50, "Expected to read maxspeed=50 from tags")
    }
}

// MARK: - Test helpers
import SQLite3

private func createMinimalGeoPackage(at url: URL) throws {
    var db: OpaquePointer?
    guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else {
        XCTFail("Failed to open test sqlite")
        return
    }
    defer { sqlite3_close(db) }

    func exec(_ sql: String) {
        var err: UnsafeMutablePointer<Int8>? = nil
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let e = err { XCTFail("SQL error: \(String(cString: e)) for: \n\(sql)") }
        }
    }

    // Minimal GeoPackage core metadata
    exec("PRAGMA application_id=1196437808;")
    exec("CREATE TABLE IF NOT EXISTS gpkg_spatial_ref_sys (srs_name TEXT, srs_id INTEGER PRIMARY KEY, organization TEXT, organization_coordsys_id INTEGER, definition TEXT, description TEXT);")
    exec("""
    INSERT INTO gpkg_spatial_ref_sys (srs_name,srs_id,organization,organization_coordsys_id,definition,description)
    VALUES (
      'WGS 84',
      4326,
      'EPSG',
      4326,
      'GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433]]',
      'WGS 84'
    );
    """)

    exec("CREATE TABLE IF NOT EXISTS gpkg_contents (table_name TEXT PRIMARY KEY, data_type TEXT, identifier TEXT, description TEXT, last_change DATETIME DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')), min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y DOUBLE, srs_id INTEGER)")

    exec("CREATE TABLE ways (id INTEGER PRIMARY KEY, geom BLOB NOT NULL, tags TEXT)")
    exec("INSERT INTO gpkg_contents (table_name, data_type, identifier, description, min_x, min_y, max_x, max_y, srs_id) VALUES ('ways','features','ways','Roads',12.56,55.67,12.58,55.69,4326)")

    exec("CREATE TABLE gpkg_geometry_columns (table_name TEXT PRIMARY KEY, column_name TEXT, geometry_type_name TEXT, srs_id INTEGER, z TINYINT, m TINYINT)")
    exec("INSERT INTO gpkg_geometry_columns (table_name,column_name,geometry_type_name,srs_id,z,m) VALUES ('ways','geom','LINESTRING',4326,0,0)")

    // Insert one LineString with maxspeed tag
    let tags = "{\"highway\":\"residential\",\"maxspeed\":\"50\"}"
    var stmt: OpaquePointer?
    let insert = "INSERT INTO ways (geom, tags) VALUES (?, ?)"
    guard sqlite3_prepare_v2(db, insert, -1, &stmt, nil) == SQLITE_OK else { XCTFail("prepare failed"); return }
    defer { sqlite3_finalize(stmt) }

    // Build GeoPackage geometry blob for a simple LineString
    let wkb = makeWKBLineString(points: [(12.5680,55.6760),(12.5690,55.6765)])
    let gpkg = makeGeoPackageGeometryBlob(wkb: wkb, srsId: 4326)

    gpkg.withUnsafeBytes { ptr in
        _ = sqlite3_bind_blob(stmt, 1, ptr.baseAddress, Int32(gpkg.count), SQLITE_TRANSIENT)
    }
    sqlite3_bind_text(stmt, 2, tags, -1, SQLITE_TRANSIENT)

    XCTAssertEqual(sqlite3_step(stmt), SQLITE_DONE)
}

private func makeWKBLineString(points: [(Double, Double)]) -> Data {
    var data = Data()
    data.append(0x01) // little endian
    // type 2 = LineString
    var type: UInt32 = 2
    data.append(Data(bytes: &type, count: 4))
    var n: UInt32 = UInt32(points.count)
    data.append(Data(bytes: &n, count: 4))
    for (x,y) in points {
        var xd = x.bitPattern.littleEndian
        var yd = y.bitPattern.littleEndian
        data.append(Data(bytes: &xd, count: 8))
        data.append(Data(bytes: &yd, count: 8))
    }
    return data
}

private func makeGeoPackageGeometryBlob(wkb: Data, srsId: Int32) -> Data {
    var data = Data()
    // magic GP
    data.append(0x47); data.append(0x50)
    data.append(0x00) // version
    let flags: UInt8 = 0b0000_0000 // little endian, no envelope
    data.append(flags)
    var srs = UInt32(bitPattern: srsId).littleEndian
    data.append(Data(bytes: &srs, count: 4))
    // no envelope bytes
    data.append(wkb)
    return data
}
