import Foundation
import SQLite3

/// Service for analyzing GPKG database schema and structure
@MainActor
class GpkgSchemaService {
    
    // MARK: - Properties
    
    private var database: OpaquePointer?
    
    // MARK: - Database Management
    
    /// Open a GPKG database file for schema analysis
    func openDatabase(at path: String) throws {
        closeDatabase()
        
        if sqlite3_open_v2(path, &database, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            closeDatabase()
            throw GpkgError.databaseOpenFailed(errorMessage)
        }
    }
    
    /// Close the current database
    func closeDatabase() {
        if let database {
            sqlite3_close(database)
            self.database = nil
        }
    }
    
    /// Check if database is open
    var isOpen: Bool {
        return database != nil
    }
    
    // MARK: - Schema Analysis
    
    /// Analyze complete database schema
    func analyzeSchema() async throws -> GpkgDatabaseInfo {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let databaseInfo = try getDatabaseInfo()
        let tables = try getAllTables()
        var tableSchemas: [String: GpkgTableSchema] = [:]
        var spatialTables: [String: GpkgSpatialInfo] = [:]
        var categorizedTables: [GpkgTableCategory: [String]] = [:]
        
        // Initialize categorized tables
        for category in GpkgTableCategory.allCases {
            categorizedTables[category] = []
        }
        
        // Analyze each table
        for tableName in tables {
            let tableSchema = try getTableSchema(tableName: tableName)
            tableSchemas[tableName] = tableSchema
            
            // Categorize table
            categorizedTables[tableSchema.category, default: []].append(tableName)
            
            // Store spatial info if applicable
            if let spatialInfo = tableSchema.spatialInfo {
                spatialTables[tableName] = spatialInfo
            }
        }
        
        return GpkgDatabaseInfo(
            filePath: databaseInfo["file_path"] as? String ?? "",
            fileSizeBytes: databaseInfo["file_size_bytes"] as? Int ?? 0,
            fileSizeMB: databaseInfo["file_size_mb"] as? Double ?? 0.0,
            gpkgVersion: databaseInfo["gpkg_version"] as? String ?? "Unknown",
            tablesCount: databaseInfo["tables_count"] as? Int ?? 0,
            analysisDate: databaseInfo["analysis_date"] as? String ?? "",
            tables: tableSchemas,
            spatialTables: spatialTables,
            categorizedTables: categorizedTables
        )
    }
    
    /// Get basic database information
    private func getDatabaseInfo() throws -> [String: Any] {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        // Get file path and size
        let filePath = try getDatabaseFilePath()
        let fileSize = try getFileSize(for: filePath)
        
        // Get GPKG version
        let gpkgVersion = try getGpkgVersion()
        
        // Get table count
        let tableCount = try getTableCount()
        
        return [
            "file_path": filePath,
            "file_size_bytes": fileSize,
            "file_size_mb": Double(fileSize) / (1024 * 1024),
            "gpkg_version": gpkgVersion,
            "tables_count": tableCount,
            "analysis_date": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Get all table names from the database
    private func getAllTables() throws -> [String] {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = """
        SELECT name FROM sqlite_master 
        WHERE type = 'table' 
        AND name NOT LIKE 'sqlite_%'
        AND name NOT LIKE 'gpkg_%'
        ORDER BY name
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        var tables: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let tableName = String(cString: sqlite3_column_text(statement, 0))
            tables.append(tableName)
        }
        
        return tables
    }
    
    /// Get detailed schema information for a table
    private func getTableSchema(tableName: String) throws -> GpkgTableSchema {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let columns = try getTableColumns(tableName: tableName)
        let rowCount = try getTableRowCount(tableName: tableName)
        let spatialInfo = try getSpatialInfo(tableName: tableName)
        let category = categorizeTable(tableName: tableName, columns: columns)
        
        return GpkgTableSchema(
            tableName: tableName,
            columns: columns,
            rowCount: rowCount,
            spatialInfo: spatialInfo,
            category: category
        )
    }
    
    /// Get column information for a table
    private func getTableColumns(tableName: String) throws -> [GpkgColumnInfo] {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = "PRAGMA table_info(\(tableName))"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        var columns: [GpkgColumnInfo] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(statement, 1))
            let type = String(cString: sqlite3_column_text(statement, 2))
            let notNull = sqlite3_column_int(statement, 3) != 0
            let primaryKey = sqlite3_column_int(statement, 5) != 0
            
            columns.append(GpkgColumnInfo(
                name: name,
                type: type,
                notNull: notNull,
                primaryKey: primaryKey
            ))
        }
        
        return columns
    }
    
    /// Get row count for a table
    private func getTableRowCount(tableName: String) throws -> Int {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = "SELECT COUNT(*) FROM \(tableName)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw GpkgError.queryExecutionFailed("Failed to get row count")
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    /// Get spatial information for a table
    private func getSpatialInfo(tableName: String) throws -> GpkgSpatialInfo? {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = """
        SELECT column_name, geometry_type_name, srs_id 
        FROM gpkg_geometry_columns 
        WHERE table_name = ?
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, tableName, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil // No spatial data
        }
        
        let columnName = String(cString: sqlite3_column_text(statement, 0))
        let geometryType = String(cString: sqlite3_column_text(statement, 1))
        let srsId = Int(sqlite3_column_int(statement, 2))
        
        return GpkgSpatialInfo(
            columnName: columnName,
            geometryType: geometryType,
            srsId: srsId
        )
    }
    
    /// Categorize a table based on its name and columns
    private func categorizeTable(tableName: String, columns: [GpkgColumnInfo]) -> GpkgTableCategory {
        let tableLower = tableName.lowercased()
        let columnNames = columns.map { $0.name.lowercased() }
        
        // Speed limits patterns
        let speedPatterns = [
            "speed", "limit", "maxspeed", "velocity", "kmh", "km/h"
        ]
        if speedPatterns.contains(where: { tableLower.contains($0) }) ||
           columnNames.contains(where: { columnName in speedPatterns.contains { pattern in columnName.contains(pattern) } }) {
            return .speedLimits
        }
        
        // Street names patterns
        let streetPatterns = [
            "street", "road", "name", "way", "avenue", "boulevard", "route"
        ]
        if streetPatterns.contains(where: { tableLower.contains($0) }) ||
           columnNames.contains(where: { columnName in streetPatterns.contains { pattern in columnName.contains(pattern) } }) {
            return .streetNames
        }
        
        // Hazards patterns
        let hazardPatterns = [
            "hazard", "warning", "alert", "danger", "risk", "caution"
        ]
        if hazardPatterns.contains(where: { tableLower.contains($0) }) ||
           columnNames.contains(where: { columnName in hazardPatterns.contains { pattern in columnName.contains(pattern) } }) {
            return .hazards
        }
        
        // Surveillance patterns
        let surveillancePatterns = [
            "camera", "surveillance", "monitor", "watch", "control"
        ]
        if surveillancePatterns.contains(where: { tableLower.contains($0) }) ||
           columnNames.contains(where: { columnName in surveillancePatterns.contains { pattern in columnName.contains(pattern) } }) {
            return .surveillance
        }
        
        return .other
    }
    
    // MARK: - Helper Methods
    
    /// Get database file path
    private func getDatabaseFilePath() throws -> String {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = "PRAGMA database_list"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw GpkgError.queryExecutionFailed("Failed to get database path")
        }
        
        return String(cString: sqlite3_column_text(statement, 2))
    }
    
    /// Get file size for a given path
    private func getFileSize(for path: String) throws -> Int {
        let url = URL(fileURLWithPath: path)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int ?? 0
    }
    
    /// Get GPKG version
    private func getGpkgVersion() throws -> String {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = "SELECT value FROM gpkg_metadata WHERE md_scope = 'dataset' AND md_standard_uri = 'http://www.geopackage.org/spec/'"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            return "Unknown"
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return "Unknown"
        }
        
        return String(cString: sqlite3_column_text(statement, 0))
    }
    
    /// Get table count
    private func getTableCount() throws -> Int {
        guard database != nil else {
            throw GpkgError.databaseNotOpen
        }
        
        let query = "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw GpkgError.queryPreparationFailed(String(cString: sqlite3_errmsg(database)))
        }
        
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw GpkgError.queryExecutionFailed("Failed to get table count")
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    // MARK: - Export Functions
    
    /// Export schema information as JSON
    func exportSchemaAsJSON(_ schema: GpkgDatabaseInfo, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(schema)
        try data.write(to: url)
    }
    
    /// Export schema information as Markdown
    func exportSchemaAsMarkdown(_ schema: GpkgDatabaseInfo, to url: URL) throws {
        var markdown = "# GPKG Schema Documentation\n\n"
        
        // Database info
        markdown += "**File:** \(schema.filePath)\n"
        markdown += "**Size:** \(String(format: "%.2f", schema.fileSizeMB)) MB\n"
        markdown += "**Tables:** \(schema.tablesCount)\n"
        markdown += "**Analysis Date:** \(schema.analysisDate)\n\n"
        
        // Categorized tables
        markdown += "## Table Categories\n\n"
        for (category, tables) in schema.categorizedTables {
            if !tables.isEmpty {
                markdown += "### \(category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)\n"
                for table in tables {
                    markdown += "- \(table)\n"
                }
                markdown += "\n"
            }
        }
        
        // Detailed table information
        markdown += "## Detailed Table Information\n\n"
        for (tableName, tableInfo) in schema.tables {
            markdown += "### \(tableName)\n\n"
            markdown += "**Rows:** \(tableInfo.rowCount)\n\n"
            
            if let spatialInfo = tableInfo.spatialInfo {
                markdown += "**Spatial Column:** \(spatialInfo.columnName)\n"
                markdown += "**Geometry Type:** \(spatialInfo.geometryType)\n"
                markdown += "**SRS ID:** \(spatialInfo.srsId)\n\n"
            }
            
            markdown += "**Columns:**\n"
            for col in tableInfo.columns {
                markdown += "- \(col.name) (\(col.type))"
                if col.notNull {
                    markdown += " NOT NULL"
                }
                if col.primaryKey {
                    markdown += " PRIMARY KEY"
                }
                markdown += "\n"
            }
            markdown += "\n"
        }
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }
}
