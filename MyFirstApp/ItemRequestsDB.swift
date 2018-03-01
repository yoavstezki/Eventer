import Foundation
import FirebaseDatabase

class ItemRequestsDB {
    let rootNode = "events"
    let requestsNode = "requests"

    var databaseRef: FIRDatabaseReference!
    var fbQueryRef: FIRDatabaseQuery!

    var productRequests: Array<ProductRequest> = []
    var event: NSString

    init(event: NSString) {
        self.event = event
        databaseRef = FIRDatabase.database().reference(withPath: "\(rootNode)/\(event)/\(requestsNode)")
    }

    func observeRequestAddition(whenRequestAdded: @escaping (Int) -> Void) {
        // Get the last-update time in the local db
        let localUpdateTime = LastUpdateTable.getLastUpdateDate(database: LocalDb.sharedInstance?.database,
                table: ListRequestsTable.TABLE,
                key: self.event as String)

        if (localUpdateTime != nil) {
            let nsUpdateTime = localUpdateTime as NSDate?

            // Get the relevant records from the remote
            fbQueryRef = databaseRef.queryOrdered(byChild: "lastUpdated").queryStarting(atValue: nsUpdateTime!.toFirebase())
            fbQueryRef.observe(FIRDataEventType.childAdded, with: { (snapshot) in
                let newRequest = self.getGroceryRequestFromSnapshot(snapshot)

                self.handleRequestAddition(request: newRequest!, whenRequestAdded: whenRequestAdded)
                self.addRequestToLocal(request: newRequest!)
            })

            // Get the up-to-date records from the local
            let localRequests = ListRequestsTable.getRequestsByListKey(database: LocalDb.sharedInstance?.database,
                    listKey: self.event as String)

            // Handle each local record
            for request in localRequests {
                self.handleRequestAddition(request: request, whenRequestAdded: whenRequestAdded)
            }
        } else {
            // Observe all records from remote
            databaseRef.observe(FIRDataEventType.childAdded, with: { (snapshot) in
                let newRequest = self.getGroceryRequestFromSnapshot(snapshot)

                self.handleRequestAddition(request: newRequest!, whenRequestAdded: whenRequestAdded)
                self.addRequestToLocal(request: newRequest!)
            })
        }
    }

    private func addRequestToLocal(request: ProductRequest) {
        // Add the updated record to the local database
        ListRequestsTable.addRequest(database: LocalDb.sharedInstance?.database, request: request, listKey: self.event as String)

        // Update the local update time
        LastUpdateTable.setLastUpdate(database: LocalDb.sharedInstance?.database,
                table: ListRequestsTable.TABLE,
                key: self.event as String,
                lastUpdate: Date())
    }

    private func handleRequestAddition(request: ProductRequest, whenRequestAdded: @escaping (Int) -> Void) {
        // Don't append the same request twice
        if (findRequestIndex(id: request.id) == nil) {
            self.productRequests.append(request)

            // Checking index explicitly - For multithreading safety
            let newRequestIndex = findRequestIndex(id: request.id)
            whenRequestAdded(newRequestIndex!)
        }
    }

    func observeRequestModification(whenRequestModified: @escaping (_: Int) -> Void) {
        databaseRef.observe(FIRDataEventType.childChanged, with: { (snapshot) in
            let updatedRequest = self.getGroceryRequestFromSnapshot(snapshot as FIRDataSnapshot)!
            let updatedIndex = self.findRequestIndex(id: updatedRequest.id)!

            self.productRequests[updatedIndex] = updatedRequest

            // Save to local
            self.addRequestToLocal(request: updatedRequest)

            whenRequestModified(updatedIndex)
        })
    }

    func removeObservers() {
        databaseRef.removeAllObservers()

        if (fbQueryRef != nil) {
            fbQueryRef.removeAllObservers()
        }
    }

    private func findRequestIndex(id: NSString) -> Int? {
        return productRequests.index(where: { $0.id == id })
    }

    private func getGroceryRequestFromSnapshot(_ snapshot: FIRDataSnapshot) -> ProductRequest? {
        let requestKey = snapshot.key as NSString
        let requestValues = snapshot.value as! Dictionary<String, Any>

        return extractGroceryRequest(key: requestKey, values: requestValues)
    }

    private func extractGroceryRequest(key: NSString, values: Dictionary<String, Any>) -> ProductRequest? {
        return ProductRequest(
                id: key,
                itemName: values["itemName"]! as! NSString,
                purchased: Bool(values["purchased"]! as! String)!,
                suggestUserId: values["suggestUserId"]! as! NSString,
                approveUserId: values["approveUserId"]! as! NSString,
                lastUpdated: NSDate.fromFirebase(String(values["lastUpdated"] as! Double)))
    }

    func getGroceryRequest(row: Int) -> ProductRequest? {
        if (row < getListCount()) {
            return productRequests[row]
        }

        return nil
    }

    func getListCount() -> Int {
        return productRequests.count
    }

    func addRequest(itemName: String, suggestUserId: String) {
        let request = ["itemName": itemName,
                       "purchased": "false",
                       "suggestUserId": suggestUserId,
                       "approveUserId":"unAssign",
                       "lastUpdated": NSDate().toFirebase()] as [String: Any]

        databaseRef.childByAutoId().setValue(request)
    }

    func toggleRequestPurchased(request: ProductRequest) {

        if (request.approveUserId == "unAssign") {
            databaseRef.child(request.id as String).updateChildValues(["purchased": "true", "approveUserId": AuthenticationUtilities.sharedInstance.getId()!, "lastUpdated": NSDate().toFirebase()])
        } else {
            databaseRef.child(request.id as String).updateChildValues(["purchased": "false","approveUserId":"unAssign", "lastUpdated": NSDate().toFirebase()])
        }

    }

    func updateRequestItemName(request: ProductRequest) {
        databaseRef.child(request.id as String).updateChildValues(["itemName": request.itemName, "lastUpdated": NSDate().toFirebase()])
    }
}
