import Foundation
import UIKit

class GroupsTableViewController : UITableViewController {
    var db:UserGroupsDB? = nil
    @IBOutlet var table: UITableView!

    deinit {
        db?.removeObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self

        initializeModel()
    }

    private func initializeModel() {
        db = UserGroupsDB(userKey: AuthenticationUtilities.sharedInstance.getId()! as NSString)
        db!.observeUserGroupsAddition(whenGroupAdded: groupAdded)
        db!.observeUserGroupsDeletion(whenGroupDeleted: groupDeleted)
    }

    private func groupAdded(groupIndex: Int) {
        // Reload groups and refresh the row-tags
        table.reloadData()
    }

    private func groupDeleted(groupIndex: Int, _: Group) {
        // Reload groups and refresh the row-tags
        table.reloadData()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return db!.getGroupsCount()
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTableViewCell", for: indexPath) as! GroupTableViewCell

        let group = db!.getGroup(row: indexPath.row)!
        cell.nameLabel.text = group.title! as String
        cell.tag = indexPath.row

        return cell
    }

    @IBAction func backFromNewGroupController(seque:UIStoryboardSegue) {
        print("Back from group creation")
    }
    
    @IBAction func leftGroup(seque:UIStoryboardSegue) {
        print("Left group")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "GroupMembers") {
            let selectedRow = (sender as! GroupTableViewCell).tag

            // Get a reference to the destination view controller
            let destinationVC:GroupMembersTableViewController = segue.destination as! GroupMembersTableViewController

            let group:Group = db!.getGroup(row: selectedRow)!

            // Pass the selected list to the next controller
            destinationVC.group = group
        }
    }
}
