import Foundation
import FirebaseDatabase

class GroupsDB {
    static let sharedInstance: GroupsDB = { GroupsDB() } ()

    let rootNode = "groups"

    var databaseRef: FIRDatabaseReference!
    var groupCache: Dictionary<NSString, Group> = Dictionary<NSString, Group>()
    
    private init() {
        databaseRef = FIRDatabase.database().reference().child(rootNode)
    }
    
    deinit {
        self.databaseRef.removeAllObservers()
    }

    func addGroup(groupTitle: NSString, forUserKey: NSString) {
        let values = ["title": groupTitle, "members": [forUserKey: true], "lastUpdateDate": FIRServerValue.timestamp()] as [String : Any]
        
        // Add the group to the remote
        let generatedKey = self.databaseRef.childByAutoId().key
        self.databaseRef.child(generatedKey).setValue(values)

        UserGroupsDB(userKey: forUserKey).addGroupToUser(groupKey: generatedKey as NSString)
    }

    func deleteGroup(key: NSString) {
        databaseRef.child(key as String).removeValue()
    }
    
    func findGroupByKey(key: String, whenFinished: @escaping (_: Group?) -> Void) {
        if (self.groupCache[key as NSString] == nil) {
            databaseRef.child(key).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                // Make sure the group was found in the database
                if (!(snapshot.value is NSNull)) {
                    let group = self.extractGroup(key: snapshot.key, values: snapshot.value as! Dictionary<String, Any>)
                    self.groupCache[key as NSString] = group
                    
                    whenFinished(group)
                } else {
                    whenFinished(nil)
                }
            })
        }
        else {
            whenFinished(self.groupCache[key as NSString]!)
        }
    }

    private func extractGroup(key: String, values: Dictionary<String, Any>) -> Group {
        return Group(key: key as NSString, title: values["title"]! as! NSString)
    }
}
