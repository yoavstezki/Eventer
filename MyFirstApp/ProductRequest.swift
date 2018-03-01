import Foundation

class ProductRequest {
    var id: NSString
    var itemName: NSString
    var purchased: Bool
    var suggestUserId: NSString
    var approveUserId: NSString
    var lastUpdated: NSDate

    init(id: NSString, itemName: NSString, purchased: Bool, suggestUserId: NSString, approveUserId: NSString) {
        self.id = id
        self.itemName = itemName
        self.purchased = purchased
        self.suggestUserId = suggestUserId
        self.approveUserId = approveUserId
        lastUpdated = NSDate()
    }

    init(id: NSString, itemName: NSString, purchased: Bool, suggestUserId: NSString, approveUserId: NSString, lastUpdated: NSDate) {
        self.id = id
        self.itemName = itemName
        self.purchased = purchased
        self.suggestUserId = suggestUserId
        self.lastUpdated = lastUpdated
        self.approveUserId = approveUserId
    }

}
