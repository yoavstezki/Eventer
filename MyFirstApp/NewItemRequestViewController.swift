import UIKit

class NewItemRequestViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var itemNameTextView: UITextField!
    
    // MARK: Actions
    @IBAction func SelectAllText(sender: UITextField) {
        sender.selectAll(sender)
    }
    
    @IBAction func clearAll(sender: AnyObject) {
        let emptyString = ""
        
        itemNameTextView.text = emptyString
    }
    
    // MARK: Other functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "UnwindNewRequest") {
            // Get a reference to the destination view controller
            let destinationVC: EventTableViewController = segue.destination as! EventTableViewController
            
            let itemName = itemNameTextView.text! as NSString
            
            destinationVC.db?.addRequest(itemName: itemName as String, suggestUserId: AuthenticationUtilities.sharedInstance.getId()!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
