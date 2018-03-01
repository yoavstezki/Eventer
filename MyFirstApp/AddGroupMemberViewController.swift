import Foundation
import UIKit

class AddGroupMemberViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    var db:GroupMembersDB?
    @IBOutlet var table: UITableView!
    var friendsToAdd: Array<User> = Array<User>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self

        FacebookFriendsFinder().find(currentMembers: (db?.members)!, forEachFriend: { (user) in
            self.friendsToAdd.append(user)
            
            self.table.reloadData()
        },
        whenFinished: checkDataNotEmpty)
        
        // No need to observe, because the db is already observing (registered in the previous controller)
    }
    
    private func checkDataNotEmpty(noFriendsToAdd: Bool) {
        if (noFriendsToAdd) {
            let alert = UIAlertController(title: "Sorry!", message: "There are no friends left to be added.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK:  UITextFieldDelegate Methods
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsToAdd.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewGroupMemberCell", for: indexPath) as! NewGroupMemberCell
        cell.setTag(tag: indexPath.row)
        
        cell.showSpinner()
        
        // Fetch the appropriate item
        let user = friendsToAdd[indexPath.row]
        
        // Update the views
        updateUserDetailsInCell(cell: cell, user: user)
        updateUserImageInCell(cell: cell, userId: user.key as String)
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! NewGroupMemberCell
        cell.toggleDone()
    }
    
    private func addMember(userKey: NSString) {
        db?.addMember(userKey: userKey)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "UnwindAddGroupMember") {
            // Get a reference to the destination view controller
            let destinationVC:GroupMembersTableViewController = segue.destination as! GroupMembersTableViewController
            let group = destinationVC.group
            
            let selectedRow = (sender as! UIView).tag
            let user = friendsToAdd[selectedRow]
            
            // Add the member to the group
            self.addMember(userKey: user.key)
            
            // Add the group to the member as well
            UserGroupsDB(userKey: user.key).addGroupToUser(groupKey: (group?.key)!)
        }
    }
}
