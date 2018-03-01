import Foundation

class User {
    var name: NSString?
    var key: NSString
    var facebookId: NSString?

    init(key: NSString, name: NSString?, facebookId: NSString?) {
        self.key = key
        self.name = name
        self.facebookId = facebookId
    }
}