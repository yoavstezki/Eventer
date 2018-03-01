import Foundation

class LastUpdateTable {
    static let TABLE = "LAST_UPDATE_TIMES"
    static let NAME = "NAME"
    static let KEY = "KEY"
    static let DATE = "DATE"

    static func createTable(database:OpaquePointer?)->Bool{
        var errormsg: UnsafeMutablePointer<Int8>? = nil
        let sql = "CREATE TABLE IF NOT EXISTS \(TABLE) (\(NAME) TEXT, \(KEY) TEXT, \(DATE) DOUBLE, PRIMARY KEY (\(NAME), \(KEY)))"

        let res = sqlite3_exec(database, sql, nil, nil, &errormsg);
        if(res != 0) {
            print("error creating table");
            return false
        }

        return true
    }

    static func deleteLastUpdate(database:OpaquePointer?, table:String, key:String){
        var sqlite3_stmt: OpaquePointer? = nil
        let sql = "DELETE FROM \(TABLE) WHERE \(NAME) = ? AND \(KEY) = ?;"
        
        if (sqlite3_prepare_v2(database, sql,-1, &sqlite3_stmt,nil) == SQLITE_OK){
            // Bind the variables to the query
            sqlite3_bind_text(sqlite3_stmt, 1, table.cString(using: .utf8),-1,nil);
            sqlite3_bind_text(sqlite3_stmt, 2, key.cString(using: .utf8),-1,nil);
            
            // Execute the statement
            if (sqlite3_step(sqlite3_stmt) == SQLITE_DONE){
                print("\(TABLE): Row deleted: table = \(table), key = \(key))")
            }
        }
        sqlite3_finalize(sqlite3_stmt)
    }
    
    static func setLastUpdate(database:OpaquePointer?, table:String, key:String, lastUpdate:Date){
        let currentDate = getLastUpdateDate(database:database, table:table, key:key)
        var sqlite3_stmt: OpaquePointer? = nil
        
        if (currentDate == nil) {
            let sql = "INSERT OR REPLACE INTO \(TABLE) (\(NAME),\(KEY),\(DATE)) VALUES (?,?,?);"
        
            if (sqlite3_prepare_v2(database, sql,-1, &sqlite3_stmt,nil) == SQLITE_OK){
                // Bind the variables to the query
                sqlite3_bind_text(sqlite3_stmt, 1, table.cString(using: .utf8),-1,nil);
                sqlite3_bind_text(sqlite3_stmt, 2, key.cString(using: .utf8) ,-1,nil);
                sqlite3_bind_double(sqlite3_stmt, 3, (lastUpdate as NSDate).toFirebase());
            }
        }
        else {
            let sql = "UPDATE \(TABLE) SET \(DATE) = ? WHERE \(NAME) = ? AND \(KEY) = ?;"
        
            if (sqlite3_prepare_v2(database, sql,-1, &sqlite3_stmt,nil) == SQLITE_OK){
                // Bind the variables to the query
                sqlite3_bind_double(sqlite3_stmt, 1, (lastUpdate as NSDate).toFirebase());
                sqlite3_bind_text(sqlite3_stmt, 2, table.cString(using: .utf8),-1,nil);
                sqlite3_bind_text(sqlite3_stmt, 3, key.cString(using: .utf8) ,-1,nil);
            }
        }
    
        // Execute the statement
        sqlite3_step(sqlite3_stmt)
        sqlite3_finalize(sqlite3_stmt)
    }

    static func getLastUpdateDate(database:OpaquePointer?, table:String, key:String)->Date?{
        var uDate:Date?
        var sqlite3_stmt: OpaquePointer? = nil
        let sql = "SELECT \(DATE) from \(TABLE) where \(NAME) = ? AND \(KEY) = ?;"
        
        if (sqlite3_prepare_v2(database, sql, -1,&sqlite3_stmt,nil) == SQLITE_OK){
            // Bind the variables to the query
            sqlite3_bind_text(sqlite3_stmt, 1, table.cString(using: .utf8),-1,nil);
            sqlite3_bind_text(sqlite3_stmt, 2, key.cString(using: .utf8),-1,nil);

            // Execute the statement
            let status = sqlite3_step(sqlite3_stmt)
            
            // Execute the statement
            if(status == SQLITE_ROW){
                // Get the date from the row that was returned
                let date = Double(sqlite3_column_double(sqlite3_stmt, 0))
                uDate = NSDate.fromFirebasee(date) as Date
            }
        }

        sqlite3_finalize(sqlite3_stmt)
        return uDate
    }
}
