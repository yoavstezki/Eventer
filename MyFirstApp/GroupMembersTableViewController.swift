import Foundation
import UIKit

class GroupMembersTableViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    var group:Group?
    var db:GroupMembersDB?
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = group?.title as String?
        
        table.delegate = self
        table.dataSource = self
        
        initializeModel()
    }

    private func initializeModel() {
        db = GroupMembersDB(group: group!)
        db!.observeGroupMembers(whenModelChanged: modelChanged)
        
        ImageDB.observeImageModification(whenImageModified: imageModified)
    }
    
    private func imageModified() {
        if (table != nil) {
            table.reloadData()
        }
    }

    private func modelChanged() {
        table.reloadData()
    }

    deinit {
        db!.removeObservers()
    }

    // MARK:  UITextFieldDelegate Methods
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return db!.getMembersCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell", for: indexPath) as! GroupMemberCell
        
        cell.showSpinner()

        // Fetches the appropriate item for the data source layout.
        if let user = db!.getMember(row: indexPath.row) {
            // Update the views
            updateUserDetailsInCell(cell: cell, user: user)
            updateUserImageInCell(cell: cell, userId: user.key as String)
        }

        return cell
    }
    
    func updateUserDetailsInCell(cell: GroupMemberCell, user:User) {
        cell.nameLabel.text = "\(user.name!)"
    }
    
    func updateUserImageInCell(cell: GroupMemberCell, userId: String) {
        ImageDB.sharedInstance.downloadImage(userId: userId, whenFinished: { (image) in
            cell.imagez.image = image
            
            cell.hideSpinner()
        })
    }
    
    @IBAction func leaveGroup() {
        let leaveAlert = UIAlertController(title: "Are you sure you want to leave?", message: "You will only be able to enter again if another member will add you back.", preferredStyle: UIAlertControllerStyle.alert)
        
        leaveAlert.addAction(UIAlertAction(title: "Leave!", style: .default, handler: { (action: UIAlertAction!) in
            // Remove the member from the group
            self.db?.removeMember(userKey: AuthenticationUtilities.sharedInstance.getId()!)
            
            // Fire an UnwindSegue to "Your groups" view
            self.performSegue(withIdentifier: "LeftGroup", sender: self)
        }))
        
        leaveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(leaveAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "AddGroupMember") {
            // Get a reference to the destination view controller
            let destinationVC:AddGroupMemberViewController = segue.destination as! AddGroupMemberViewController
            
            // Pass the GroupMembersDB to the next controller
            destinationVC.db = self.db
        }
        else if (segue.identifier == "LeftGroup") {
            // Get a reference to the destination view controller
            let destinationVC:GroupsTableViewController = segue.destination as! GroupsTableViewController
            
            // Remove the group from the user as well
            destinationVC.db?.removeGroupFromUser(groupKey: group?.key as! String)
        }
    }
    
    @IBAction func backFromAddGroupMemberController(seque:UIStoryboardSegue) {
        print("Back from add group member")
    }
}
