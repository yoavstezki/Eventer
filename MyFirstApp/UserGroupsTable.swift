import Foundation

class UserGroupsTable {
    static let TABLE = "USER_GROUPS"
    static let GROUP_KEY = "GROUP_KEY"
    
    static func createTable(database:OpaquePointer?)->Bool{
        var errormsg: UnsafeMutablePointer<Int8>? = nil
        let sql = "CREATE TABLE IF NOT EXISTS \(TABLE) (\(GROUP_KEY) TEXT PRIMARY KEY)"
        
        let res = sqlite3_exec(database, sql, nil, nil, &errormsg);
        if(res != 0) {
            print("error creating table \(TABLE)");
            return false
        }
        
        return true
    }
    
    static func truncateTable(database:OpaquePointer?) {
        var errormsg: UnsafeMutablePointer<Int8>? = nil
        let sql = "DELETE FROM \(TABLE)"
        
        let res = sqlite3_exec(database, sql, nil, nil, &errormsg);
        if(res != 0) {
            print("error truncating table \(TABLE)");
        }
    }
    
    static func addGroupKeys(database:OpaquePointer?, groupKeys:Array<String>) {
        for key in groupKeys {
            addGroupKey(database: database, groupKey: key)
        }
    }

    private static func addGroupKey(database:OpaquePointer?, groupKey:String) {
        var sqlite3_stmt: OpaquePointer? = nil
        let sql = "INSERT OR REPLACE INTO \(TABLE) (\(GROUP_KEY)) VALUES (?);"
        
        if (sqlite3_prepare_v2(database, sql,-1, &sqlite3_stmt,nil) == SQLITE_OK) {
            // Bind the variable to the query
            sqlite3_bind_text(sqlite3_stmt, 1, groupKey.cString(using: .utf8),-1,nil);
            
            // Execute the statement
            sqlite3_step(sqlite3_stmt)
        }
        
        sqlite3_finalize(sqlite3_stmt)
    }

    static func getUserGroupKeys(database:OpaquePointer?) -> Array<String> {
        var groupKeys = Array<String>()
        
        var sqlite3_stmt: OpaquePointer? = nil
        let sql = "SELECT DISTINCT \(GROUP_KEY) FROM \(TABLE);"
        
        if (sqlite3_prepare_v2(database, sql, -1,&sqlite3_stmt,nil) == SQLITE_OK) {
            // Execute the statement
            while (sqlite3_step(sqlite3_stmt) == SQLITE_ROW) {
                // Get the group key from the row that has been selected
                let groupKey = String(validatingUTF8:sqlite3_column_text(sqlite3_stmt,0))
                
                if (groupKey != nil) {
                    groupKeys.append(groupKey!)
                }
            }
        }
        
        sqlite3_finalize(sqlite3_stmt)
        return groupKeys;
    }
}
