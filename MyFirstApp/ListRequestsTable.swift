import Foundation

class ListRequestsTable {
    static let TABLE = "LIST_REQUESTS"
    static let LIST_KEY = "LIST_KEY"
    static let REQUEST_KEY = "REQUEST_KEY"
    static let ITEM_NAME = "ITEM_NAME"
    static let PURCHASED = "PURCHASED"
    static let USER_KEY = "USER_KEY"
    static let APPROVE_USER_KEY = "APPROVE_USER_KEY"


    static func createTable(database: OpaquePointer?) -> Bool {
        var errormsg: UnsafeMutablePointer<Int8>? = nil
        let sql = "CREATE TABLE IF NOT EXISTS \(TABLE) (\(REQUEST_KEY) TEXT, \(LIST_KEY) TEXT, \(ITEM_NAME) TEXT, \(PURCHASED) TEXT, \(USER_KEY) TEXT,\(APPROVE_USER_KEY) TEXT, PRIMARY KEY (\(REQUEST_KEY), \(LIST_KEY)))"

        let res = sqlite3_exec(database, sql, nil, nil, &errormsg);
        if (res != 0) {
            print("error creating table \(TABLE)");
            return false
        }

        return true
    }

    static func addRequest(database: OpaquePointer?, request: ProductRequest, listKey: String) {
        var sqlite3_stmt: OpaquePointer? = nil

        let sql = "INSERT OR REPLACE INTO \(TABLE) (\(REQUEST_KEY), \(LIST_KEY), \(ITEM_NAME), \(PURCHASED), \(USER_KEY), \(APPROVE_USER_KEY)) VALUES ('\(request.id as String)', '\(listKey)', '\((request.itemName as String))', '\(request.purchased.description.lowercased())', '\((request.suggestUserId as String))', '\((request.approveUserId as String))');"

        if (sqlite3_prepare_v2(database, sql, -1, &sqlite3_stmt, nil) == SQLITE_OK) {
            // Execute the statement
            sqlite3_step(sqlite3_stmt)
        }

        sqlite3_finalize(sqlite3_stmt)
    }

    static func getRequestsByListKey(database: OpaquePointer?, listKey: String) -> Array<ProductRequest> {
        var requests = Array<ProductRequest>()

        var sqlite3_stmt: OpaquePointer? = nil
        let sql = "SELECT \(REQUEST_KEY), \(ITEM_NAME), \(PURCHASED), \(USER_KEY) , \(APPROVE_USER_KEY) FROM \(TABLE) WHERE \(LIST_KEY) = '\(listKey)';"

        if (sqlite3_prepare_v2(database, sql, -1, &sqlite3_stmt, nil) == SQLITE_OK) {
            // Execute the statement
            while (sqlite3_step(sqlite3_stmt) == SQLITE_ROW) {
                let requestKey = String(validatingUTF8: sqlite3_column_text(sqlite3_stmt, 0))
                let itemName = String(validatingUTF8: sqlite3_column_text(sqlite3_stmt, 1))
                let purchased = String(validatingUTF8: sqlite3_column_text(sqlite3_stmt, 2))?.lowercased() == "true"
                let userKey = String(validatingUTF8: sqlite3_column_text(sqlite3_stmt, 3))
                let approveUserKey = String(validatingUTF8: sqlite3_column_text(sqlite3_stmt, 4))

                let request = ProductRequest(
                        id: requestKey! as NSString,
                        itemName: itemName! as NSString,
                        purchased: purchased,
                        suggestUserId: userKey! as NSString,
                        approveUserId: approveUserKey! as NSString
                )

                requests.append(request)
            }
        }

        sqlite3_finalize(sqlite3_stmt)

        return requests;
    }
}
