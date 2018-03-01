import Foundation
import FirebaseDatabase

class UserEventsDB {
    var events = Array<Event>()
    var userGroupsDb: UserGroupsDB?
    var eventsGroupDb = Array<EventsByGroupDB>()

    var whenEventAddedAtIndex: ((_: Int) -> Void)?
    var whenEventDeletedAtIndex: ((_: Int?) -> Void)?

    init(userKey: NSString) {
        userGroupsDb = UserGroupsDB(userKey: userKey)
    }

    func observeLists(whenEventAddedAtIndex: @escaping (_: Int) -> Void, whenEventDeletedAtIndex: @escaping(_: Int?) -> Void) {
        self.whenEventAddedAtIndex = whenEventAddedAtIndex
        self.whenEventDeletedAtIndex = whenEventDeletedAtIndex
        userGroupsDb!.observeUserGroupsAddition(whenGroupAdded: groupAdded)
        userGroupsDb!.observeUserGroupsDeletion(whenGroupDeleted: groupDeleted)
    }

    private func groupAdded(groupIndex: Int) {
        let group = userGroupsDb!.getGroup(row: groupIndex)

        // Make sure we didn't already add this group to event (Could happen when UserGroupsDB resets).
        if (eventsGroupDb.index(where: {$0.groupKey == group!.key}) == nil) {
            // Create a db that manages the added group's lists
            let db = EventsByGroupDB(groupKey: group!.key)
            eventsGroupDb.append(db)

            // When the new db observes a new list, add it to our array of lists.
            db.observeListsAddition(whenAdded: eventAdded)
            db.observeListsDeletion(whenDeleted: eventDeleted)
        }
    }

    private func eventAdded(newEvent: Event) {
        events.append(newEvent)
        whenEventAddedAtIndex!(events.count - 1)
    }

    private func eventDeleted(deletedEvent: Event) {
        let deletedEventIndex = events.index(where: { $0.id == deletedEvent.id })!
        events.remove(at: deletedEventIndex)
        whenEventDeletedAtIndex!(deletedEventIndex)
    }

    private func groupDeleted(_: Int, deletedGroup: Group) {
        removeGroupObserver(groupKey: deletedGroup.key)
        removeGroupLists(groupKey: deletedGroup.key)
        whenEventDeletedAtIndex!(nil)
    }

    private func removeGroupObserver(groupKey: NSString) {
        guard let dbIndex = eventsGroupDb.index(where: { $0.groupKey == groupKey }) else { return }

        // Remove the observers and remove the db of the deleted group.
        eventsGroupDb[dbIndex].removeObservers()
        eventsGroupDb.remove(at: dbIndex)
    }

    private func removeGroupLists(groupKey: NSString) {
        events = events.filter({ $0.groupKey != groupKey })
    }

    func removeObservers() {
        userGroupsDb!.removeObservers()
        eventsGroupDb.forEach({ $0.removeObservers() })
    }

    func getListsCount() -> Int {
        return events.count
    }
    
    func doesUserHaveGroup() -> Bool {
        return userGroupsDb!.getGroupsCount() > 0
    }

    func getEvent(row: Int) -> Event? {
        if (row < getListsCount()) {
            return events[row]
        }

        return nil
    }
}
