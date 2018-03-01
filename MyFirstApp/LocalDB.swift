import Foundation

extension String {
    public init?(validatingUTF8 cString: UnsafePointer<UInt8>) {
        if let (result, _) = String.decodeCString(cString, as: UTF8.self,
                repairingInvalidCodeUnits: false) {
            self = result
        }
        else {
            return nil
        }
    }
}

class LocalDb {
    static let sharedInstance: LocalDb? = { LocalDb() } ()

    var database: OpaquePointer? = nil

    private init?(){
        let dbFileName = "MyFirstAppDatabase.db"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            let path = dir.appendingPathComponent(dbFileName)

            // Opening the database file
            if sqlite3_open(path.absoluteString, &database) != SQLITE_OK {
                print("Failed to open db file: \(path.absoluteString)")
                return nil
            }
        }
 
        // Creating the tables (if they don't already exists)
        if LastUpdateTable.createTable(database: database) == false ||
           UserGroupsTable.createTable(database: database) == false ||
           GroupMembersTable.createTable(database: database) == false ||
           ListRequestsTable.createTable(database: database) == false {
            return nil
        }
    }
}
