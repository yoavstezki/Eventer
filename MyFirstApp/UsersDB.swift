import Foundation
import FirebaseDatabase

class UsersDB {
    static let sharedInstance: UsersDB = { UsersDB() } ()
    let rootNode = "users"
    var databaseRef: FIRDatabaseReference!
    var userCache:Dictionary<String, User> = Dictionary<String, User>()

    init() {
        databaseRef = FIRDatabase.database().reference()
    }
    
    deinit {
        databaseRef.removeAllObservers()
    }
    
    func findUserByKey(key: String, whenFinished: @escaping (_: User?) -> Void) {
        if (self.userCache[key] == nil) {
            databaseRef.child(rootNode).child(key).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                    // Make sure the user was found in the database
                    if (!(snapshot.value is NSNull)) {
                        let user = self.extractUser(key: snapshot.key as NSString, values: snapshot.value as! Dictionary<String, Any>)
                        self.userCache[key] = user
                        
                        whenFinished(user)
                    } else {
                        whenFinished(nil)
                    }
            })
        }
        else {
            whenFinished(self.userCache[key]!)
        }
    }

    func findUserByFacebookId(facebookId: String, whenFinished: @escaping (_: User) -> Void) {
        databaseRef.child(rootNode).queryOrdered(byChild: "facebookId").queryEqual(toValue: facebookId).observeSingleEvent(
                        of: FIRDataEventType.value, with: {(snapshot) in
                    if !(snapshot.value is NSNull) {
                        let userSnapshot = (snapshot.value as! Dictionary<String, Any>).first!
                        let user = self.extractUser(key: userSnapshot.key as NSString, values: userSnapshot.value as! Dictionary<String, Any>)
                        whenFinished(user)
                    }
                })
    }
    
    private func extractUser(key: NSString, values: Dictionary<String, Any>) -> User {
        return User(key: key, name: values["name"] as? NSString, facebookId: values["facebookId"] as? NSString)
    }
    
    func addUser(user:User, whenFinished: @escaping (Error?, FIRDatabaseReference) -> Void) {
        let values = loadValues(from: user)
        self.databaseRef.child(rootNode).child(user.key as String).setValue(values, withCompletionBlock: whenFinished)
        self.userCache[user.key as String] = user
    }
    
    private func loadValues(from: User) -> Dictionary<String, String> {
        var values = Dictionary<String, String>()
        values["name"] = from.name as? String
        values["facebookId"] = from.facebookId as? String
        
        return values
    }
}