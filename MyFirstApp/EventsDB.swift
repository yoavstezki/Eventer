import Foundation
import FirebaseDatabase

class EventsDB {
    static let sharedInstance: EventsDB = { EventsDB() } ()
    let rootNode = "events"

    var databaseRef: FIRDatabaseReference!

    private init() {
        databaseRef = FIRDatabase.database().reference(withPath: rootNode)
    }
    
    func addEvent(event: Event) {
        self.databaseRef.childByAutoId().setValue(loadValues(from: event))
    }

    private func loadValues(from: Event) -> Dictionary<String, String> {
        var values = Dictionary<String, String>()
        values["title"] = from.title as String
        values["date"] = TimeUtilities.getStringFromDate(date: from.date as Date, timeZone: TimeZone(secondsFromGMT: 0)!)
        values["groupKey"] = from.groupKey as String

        return values
    }
    
    func deleteEvent(id: String) {
        self.databaseRef.child(id).removeValue()
    }
}