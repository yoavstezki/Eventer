import Foundation
import UIKit

class ChooseGroupDialogViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var selectedGroup: Group?
    var db: UserGroupsDB?
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self

        initializeModel()
    }

    private func initializeModel() {
        db = UserGroupsDB(userKey: AuthenticationUtilities.sharedInstance.getId()! as NSString)
        db!.observeUserGroupsAddition(whenGroupAdded: groupAdded)
    }

    private func groupAdded(groupIndex: Int) {
        pickerView.reloadAllComponents()
        selectedGroup = db!.getGroup(row: 0)
    }

    deinit {
        db!.removeObservers()
    }

    // MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return db!.getGroupsCount()
    }

    @available(iOS 2.0, *)
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // MARK: Delegates
    // This function determines what title will be presented for each group
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return db!.getGroup(row: row)!.title as String?
    }

    // This function is called when user selects row
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedGroup = db!.getGroup(row: row)!
    }

    // Attributes for title
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = db!.getGroup(row: row)!.title
        let myTitle = NSAttributedString(string: titleData as! String, attributes: [NSFontAttributeName:UIFont(name: "Georgia", size: 15.0)!,NSForegroundColorAttributeName:UIColor.black])
        return myTitle
    }
    
    @IBAction func closeDialog() {
        // Unwind back to CameraViewController
        self.performSegue(withIdentifier: "UnwindChooseGroupDialog", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "UnwindChooseGroupDialog") {
            if (selectedGroup != nil) {
                // Get a reference to the destination view controller
                let destinationVC: NewEventListViewController = segue.destination as! NewEventListViewController
                
                destinationVC.refreshGroup(group: selectedGroup!)
            }
        }
    }
}
