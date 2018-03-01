import UIKit

class EventTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var db: ItemRequestsDB? = nil
    var event: Event? = nil
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = event?.title as String?
        
        table.delegate = self
        table.dataSource = self

        initializeModel()
        
        // tapRecognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        self.view.addGestureRecognizer(longPressRecognizer)
    }

    private func initializeModel() {
        db = ItemRequestsDB(event: event!.id)
        db!.observeRequestAddition(whenRequestAdded: requestAdded)
        db!.observeRequestModification(whenRequestModified: requestModified)
        
        ImageDB.observeImageModification(whenImageModified: imageModified)
    }
    
    private func imageModified() {
        if (table != nil) {
            table.reloadData()
        }
    }
    
    private func requestAdded(requestIndex: Int) {
        table.insertRows(at: [IndexPath(row: requestIndex, section: 0)],
                         with: UITableViewRowAnimation.automatic)
    }

    private func requestModified(requestIndex: Int) {
        table.reloadRows(at: [IndexPath(row: requestIndex, section: 0)],
                        with: UITableViewRowAnimation.automatic)
    }

    deinit {
        db!.removeObservers()
    }

    // MARK:  UITextFieldDelegate Methods
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Num of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return db!.getListCount()
    }
    
    // Cell creation
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventRequestTableViewCell", for: indexPath) as! EventRequestTableViewCell
        manageCell(cell: cell, row: indexPath.row)
        
        return cell
    }
    
    private func manageCell(cell: EventRequestTableViewCell, row: Int) {
        cell.showSpinner()

        // Fetches the appropriate item
        let item = db!.getGroceryRequest(row: row)
        let userId = item?.suggestUserId as! String
        let approveUserId = item?.approveUserId as! String

        // Update the views
        updateUserDetailsInCell(cell: cell, userId: userId)
        updateApproveUserDetailsInCell(cell: cell, approveUserId: approveUserId)
        updateUserImageInCell(cell: cell, userId: userId)
        updateItemNameInCell(cell: cell, item: item!)
    }

    func updateUserDetailsInCell(cell: EventRequestTableViewCell, userId: String) {
        // Fetch the user and show his name
            UsersDB.sharedInstance.findUserByKey(key: userId, whenFinished: { (user) in
            if (user != nil) {
                cell.nameLabel.text = "\(user!.name!)"
            }
        })
    }

    func updateApproveUserDetailsInCell(cell: EventRequestTableViewCell, approveUserId: String) {
        // Fetch the user and show his name
        UsersDB.sharedInstance.findUserByKey(key: approveUserId, whenFinished: { (user) in
            if (user != nil) {
                cell.approveUserLabel.text = "\(user!.name!)"
            }
        })
    }

    func updateUserImageInCell(cell: EventRequestTableViewCell, userId: String) {
        // Fetch the image and show it
        ImageDB.sharedInstance.downloadImage(userId: userId, whenFinished: { (image) in
            cell.imagez.image = image
            
            cell.hideSpinner()
        })
    }

    private func updateItemNameInCell(cell: EventRequestTableViewCell, item: ProductRequest) {
        if (item.purchased) {
            updatePurchasedItemNameInCell(cell: cell, name: item.itemName)
        } else {
            updateRequestedItemNameInCell(cell: cell, name: item.itemName)
        }
    }

    // Crossed-out gray item name label
    private func updatePurchasedItemNameInCell(cell: EventRequestTableViewCell, name: NSString) {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: name as String)
        attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))

        cell.itemLabel.attributedText = attributeString
        cell.itemLabel.textColor = UIColor.gray
        cell.itemLabel.alpha = 0.2
    }

    // Regular item name label
    private func updateRequestedItemNameInCell(cell: EventRequestTableViewCell, name: NSString) {
        cell.itemLabel.text = name as String?
        cell.itemLabel.textColor = UIColor.black
        cell.itemLabel.alpha = 1
    }

    // MARK: UITableViewDelegate Methods
    // Row selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let request = db!.getGroceryRequest(row: indexPath.row) {
            db!.toggleRequestPurchased(request: request)
        }
    }
    
    // Called when long press occurred
    func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            
            // Get the path in which the long press occured
            if let indexPath = table.indexPathForRow(at: touchPoint) {
                // Get the request
                if let request = db!.getGroceryRequest(row: indexPath.row) {
                    // Owner check - Make sure the current user created the request
                    if (request.suggestUserId.isEqual(to: AuthenticationUtilities.sharedInstance.getId()!)) {
                        // Get the cell and manage it again (Essentialy create it again)
                        let cell = table.dequeueReusableCell(withIdentifier: "EventRequestTableViewCell", for: indexPath) as! EventRequestTableViewCell
                        manageCell(cell: cell, row: indexPath.row)
                        
                        // Start editing the cell
                        cell.startEditing(whenFinishedEditing: { (newItemName) in
                            request.itemName = newItemName as NSString
                            
                            // Save the new item name
                            self.db!.updateRequestItemName(request: request)
                        })
                    }
                }
            }
        }
    }

    @IBAction func backFromNewRequestController(seque:UIStoryboardSegue) {}
}
