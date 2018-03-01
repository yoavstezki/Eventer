import Foundation
import FirebaseDatabase

class UserGroupsDB {
    let usersNode = "users"
    let groupsNode = "groups"

    var userRef: FIRDatabaseReference!
    var userGroupsRef: FIRDatabaseReference!

    var groups: Array<Group> = []
    var userKey: NSString

    init(userKey: NSString) {
        self.userKey = userKey
        userRef = FIRDatabase.database().reference(withPath: "\(usersNode)/\(userKey)")
        userGroupsRef = FIRDatabase.database().reference(withPath: "\(usersNode)/\(userKey)/\(groupsNode)")
    }

    func observeUserGroupsAddition(whenGroupAdded: @escaping (Int) -> Void) {
        // Get the last-update time in the local db
        let localUpdateTime = LastUpdateTable.getLastUpdateDate(database: LocalDb.sharedInstance?.database,
                                                                table: UserGroupsTable.TABLE,
                                                                key: self.userKey as String)

        // -----------------------------
        // Handler for query observation
        // -----------------------------
        let queryHandler = { (snapshot:FIRDataSnapshot) in
            // Reset the array of groups. We've got a new array.
            self.groups.removeAll()

            // If we need to refresh and we got the groups
            if (!(snapshot.value is NSNull)) {
                let groupsNodeValue = (snapshot.value as! Dictionary<String, Any>).values
                var groupKeys: Array<String> = []

                groupKeys = Array((groupsNodeValue.first as! Dictionary<String, Any>).keys)

                if let lastUpdatedStringIndex = groupKeys.index(of: "lastUpdated") {
                    // Remove the "lastUpdated" key
                    groupKeys.remove(at: lastUpdatedStringIndex)
                }

                self.handleUserGroups(groupKeys: groupKeys,
                                      whenGroupAdded: whenGroupAdded)
            }
                // Local DB is up to date - get groups from local.
            else {
                self.getGroupsFromLocal(whenGroupAdded: whenGroupAdded)
            }
        }

        // -------------------------------
        // Handler for regular observation
        // -------------------------------
        let handler = { (snapshot:FIRDataSnapshot) in
            // Reset the array of groups. We've got a new array.
            self.groups.removeAll()

            // If we need to refresh and we got the groups
            if (!(snapshot.value is NSNull)) {
                let dictionary = snapshot.value as! Dictionary<String, NSNumber>


                var groupKeys = Array(dictionary.keys)

                if let lastUpdatedStringIndex = groupKeys.index(of: "lastUpdated") {
                    // Remove the "lastUpdated" key
                    groupKeys.remove(at: lastUpdatedStringIndex)
                }

                self.handleUserGroups(groupKeys: groupKeys,
                                      whenGroupAdded: whenGroupAdded)
            }
        }

        if (localUpdateTime != nil) {
            let nsUpdateTime = localUpdateTime as NSDate?

            // Observe only if the remote update-time is after the the local
            let fbQuery = userRef.queryOrdered(byChild:"lastUpdated").queryStarting(atValue: nsUpdateTime!.toFirebase())
            fbQuery.observe(FIRDataEventType.value, with: queryHandler)
        }
        else {
            // Observe all group records from remote group node
            userGroupsRef.observe(FIRDataEventType.value, with: handler)
        }
    }

    private func getGroupsFromLocal(whenGroupAdded: @escaping (Int) -> Void) {
        let groupKeysFromLocal = UserGroupsTable.getUserGroupKeys(database: LocalDb.sharedInstance?.database)

        for groupKey in groupKeysFromLocal {
            self.handleUserGroupAddition(groupKey: groupKey, whenGroupAdded: whenGroupAdded)
        }
    }

    private func handleUserGroups(groupKeys: Array<String>, whenGroupAdded: @escaping (Int) -> Void) {
        for groupKey in groupKeys {
            self.handleUserGroupAddition(groupKey: groupKey, whenGroupAdded: whenGroupAdded)
        }

        UserGroupsTable.truncateTable(database: LocalDb.sharedInstance?.database)
        UserGroupsTable.addGroupKeys(database: LocalDb.sharedInstance?.database, groupKeys: groupKeys)
        LastUpdateTable.setLastUpdate(database: LocalDb.sharedInstance?.database,
                                      table: UserGroupsTable.TABLE,
                                      key: self.userKey as String,
                                      lastUpdate: Date())
    }

    private func handleUserGroupAddition(groupKey: String, whenGroupAdded: @escaping (Int) -> Void) {
        // Retrieve the group object
        GroupsDB.sharedInstance.findGroupByKey(key: groupKey, whenFinished: {(group) in
            guard let foundGroup = group else { return }

            self.groups.append(foundGroup)

            // Checking index explicitly - For multithreading safety
            let newGroupIndex = self.groups.index(where: { $0.key == foundGroup.key })
            whenGroupAdded(newGroupIndex!)
        })
    }

    func observeUserGroupsDeletion(whenGroupDeleted: @escaping (_: Int, _: Group) -> Void) {
        userGroupsRef.observe(FIRDataEventType.childRemoved, with: {(snapshot) in
            guard let groupIndex = self.findGroupIndexByKey(groupKey: snapshot.key as NSString) else { return }

            let removedGroup = self.groups.remove(at: groupIndex)
            whenGroupDeleted(groupIndex, removedGroup)
        })
    }

    private func findGroupIndexByKey(groupKey: NSString) -> Int? {
        return groups.index(where: {$0.key == groupKey})
    }

    func addGroupToUser(groupKey: NSString) {
        userGroupsRef.updateChildValues([groupKey : true, "lastUpdated" : NSDate().toFirebase()])
    }

    func removeGroupFromUser(groupKey: String) {
        userGroupsRef.child(groupKey).removeValue()
        userGroupsRef.updateChildValues(["lastUpdated" : NSDate().toFirebase()])
    }

    func removeObservers() {
        userRef.removeAllObservers()
        userGroupsRef.removeAllObservers()
    }

    func getGroupsCount() -> Int {
        return groups.count
    }

    func getGroup(row: Int) -> Group? {
        if (row < getGroupsCount()) {
            return groups[row]
        }

        return nil
    }

    func findFirstGroup(whenFound: @escaping (_: Group?) -> Void) {
        userGroupsRef.queryLimited(toFirst: 1).observeSingleEvent(of: FIRDataEventType.childAdded, with: {(snapshot) in
                    if !(snapshot.value is NSNull) {
                        GroupsDB.sharedInstance.findGroupByKey(key: snapshot.key, whenFinished: { (group) in
                            whenFound(group)
                        })
                    }
                })
    }
}
