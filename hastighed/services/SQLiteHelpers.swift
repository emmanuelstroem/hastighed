import Foundation
import SQLite3

// Provide SQLITE_TRANSIENT for Swift bindings
public let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
