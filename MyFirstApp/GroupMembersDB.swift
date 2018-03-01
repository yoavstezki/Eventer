import Foundation
import FirebaseDatabase

class GroupMembersDB {
    let groupsNode = "groups"
    let membersNode = "members"
    let lastUpdateDateNode = "lastUpdateDate"

    var databaseRef: FIRDatabaseReference!
    var lastUpdateDateRef: FIRDatabaseReference!
    var members: Array<User> = []
    var group: Group

    init(group: Group) {
        self.group = group

        // This database reference will be used to fetch the members
        databaseRef = FIRDatabase.database().reference(withPath: "\(groupsNode)/\(group.key)/\(membersNode)")

        // This database reference will be used to fetch and observe the last update date
        lastUpdateDateRef = FIRDatabase.database().reference(withPath: "\(groupsNode)/\(group.key)/\(lastUpdateDateNode)")
    }

    func observeGroupMembers(whenModelChanged: @escaping () -> Void) {
        // Observe the remote last update time and act upon that value :
        // If our local last update time isn't before the remote one we can safely fetch the members locally.
        // Otherwise, we will have to fetch them from the remote db (and updating the local db of course).
        observeRemoteLastUpdateTime(whenUpdateTimeFound: { (remoteLastUpdateTime) in
            // First we will clear the members array as we are about to append data to it
            self.members.removeAll()

            if (self.isLocalDatabaseUpToDate(remoteLastUpdateDate: remoteLastUpdateTime)) {
                self.fetchGroupMembersFromLocalDB(whenModelChanged: whenModelChanged)
            }
            else {
                self.fetchGroupMembersFromRemoteDBAndUpdateLocalDB(whenModelChanged: whenModelChanged,
                        remoteLastUpdateTime: remoteLastUpdateTime)
            }
        })
    }

    private func fetchGroupMembersFromLocalDB(whenModelChanged: @escaping () -> Void) {
        // Get the up-to-date records from the local
        let localUsersKeys = GroupMembersTable.getUserKeysByGroupKey(database: LocalDb.sharedInstance?.database,
                groupKey: self.group.key as String)

        // Handle each local record
        for userKey in localUsersKeys {
            self.handleGroupMemberAddition(userKey: userKey, whenModelChanged: whenModelChanged)
        }
    }

    private func fetchGroupMembersFromRemoteDBAndUpdateLocalDB(whenModelChanged: @escaping () -> Void, remoteLastUpdateTime: NSDate) {
        // Fetch the group members
        self.databaseRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            if (snapshot.exists()) {
                var userKeys = Array<String>()

                // Extract group member user keys and append them to our user keys array
                for child in snapshot.children.allObjects {
                    if let childData = child as? FIRDataSnapshot {
                        userKeys.append(childData.key)
                    }
                }

                // Handle each member fetched independently
                userKeys.forEach({ self.handleGroupMemberAddition(userKey: $0, whenModelChanged: whenModelChanged) })

                // Update local db with the fetched user keys
                self.updateLocalDB(userKeys: userKeys, remoteLastUpdateTime: remoteLastUpdateTime)
            }
        })
    }

    private func observeRemoteLastUpdateTime(whenUpdateTimeFound: @escaping (NSDate) -> Void) {
        // Use the last update date database reference to fetch the last update date
        lastUpdateDateRef.observe(FIRDataEventType.value, with: {(snapshot) in
            if (snapshot.exists()) {
                whenUpdateTimeFound(NSDate.fromFirebasee(snapshot.value as! Double))
            }
        })
    }

    private func isLocalDatabaseUpToDate(remoteLastUpdateDate: NSDate) -> Bool {
        // If there is no local last update time, the local db is obviously not up to date.
        guard let localUpdateTime = getLocalUpdateTime() else { return false }

        // Check if the local last update time is before the remote last update time
        return localUpdateTime.compare(remoteLastUpdateDate as Date) != ComparisonResult.orderedAscending
    }

    private func getLocalUpdateTime() -> Date? {
        // Get the last-update time in the local db
        return LastUpdateTable.getLastUpdateDate(
                database: LocalDb.sharedInstance?.database,
                table: GroupMembersTable.TABLE,
                key: group.key as String)
    }

    private func updateLocalDB(userKeys: Array<String>, remoteLastUpdateTime: NSDate) {
        GroupMembersTable.updateUserKeys(
                database: LocalDb.sharedInstance?.database, userKeys: userKeys, groupKey: group.key as String)

        // Update the local update time
        LastUpdateTable.setLastUpdate(database: LocalDb.sharedInstance?.database,
                table: GroupMembersTable.TABLE,
                key: self.group.key as String,
                lastUpdate: remoteLastUpdateTime as Date)
    }
    
    private func handleGroupMemberAddition(userKey: String, whenModelChanged: @escaping () -> Void) {
        // Retrieve the user object
        UsersDB.sharedInstance.findUserByKey(key: userKey, whenFinished: {(user) in
            guard let foundUser = user else { return }
            
            self.members.append(foundUser)

            whenModelChanged()
        })
    }

    func findGroupMembersCount(whenFound: @escaping (_: Int) -> Void) {
        databaseRef.observeSingleEvent(of: FIRDataEventType.value, with: {(snapshot) in
            if (!snapshot.exists()) {
                whenFound(0)
            }
            else {
                whenFound(Int(snapshot.childrenCount))
            }
        })
    }

    func addMember(userKey: NSString) {
        databaseRef.updateChildValues([userKey : true], withCompletionBlock: { (_,_) in
            self.updateLastUpdateTime()
        })
    }
    
    func removeMember(userKey: String) {
        databaseRef.child(userKey).removeValue(completionBlock: { (_,_) in
            self.updateLastUpdateTime()
            self.deleteGroupIfEmpty()
        })
    }

    private func updateLastUpdateTime() {
        self.lastUpdateDateRef.setValue(FIRServerValue.timestamp())
    }

    private func deleteGroupIfEmpty() {
        self.findGroupMembersCount(whenFound: { (count) in
            if (count == 0) {
                GroupsDB.sharedInstance.deleteGroup(key: self.group.key)
            }
        })
    }

    func removeObservers() {
        databaseRef.removeAllObservers()
        lastUpdateDateRef.removeAllObservers()
    }

    func getMembersCount() -> Int {
        return members.count
    }

    func getMember(row: Int) -> User? {
        if (row < getMembersCount()) {
            return members[row]
        }

        return nil
    }
}
