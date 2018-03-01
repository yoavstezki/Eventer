import Foundation
import FirebaseDatabase

class EventsByGroupDB {
    let listsNode = "events"

    var query: FIRDatabaseQuery!
    var groupKey: NSString

    init(groupKey: NSString) {
        self.groupKey = groupKey
        query = FIRDatabase.database().reference(withPath: listsNode)
                .queryOrdered(byChild: "groupKey").queryEqual(toValue: groupKey)
    }

    func observeListsAddition(whenAdded: @escaping (_: Event) -> Void) {
        query.observe(FIRDataEventType.childAdded, with: {(snapshot) in
            let addedList = self.extractGroceryList(key: snapshot.key as String,
                    values: snapshot.value as! Dictionary<String, Any>)
            whenAdded(addedList)
        })
    }

    func observeListsDeletion(whenDeleted: @escaping (_: Event) -> Void) {
        query.observe(FIRDataEventType.childRemoved, with: {(snapshot) in
            let deletedList = self.extractGroceryList(key: snapshot.key as String,
                    values: snapshot.value as! Dictionary<String, Any>)
            whenDeleted(deletedList)
        })
    }

    func removeObservers() {
        query.removeAllObservers()
    }

    private func extractGroceryList(key: String, values: Dictionary<String, Any>) -> Event {
        return Event(
                id: key as NSString,
                title: values["title"]! as! NSString,
                date: TimeUtilities.getDateFromString(
                        date: values["date"]! as! String,
                        timeZone: TimeZone(secondsFromGMT: 0 - TimeUtilities.getCurrentTimeZoneSecondsFromGMT())!) as NSDate,
                groupKey: values["groupKey"] as! NSString)
    }
}