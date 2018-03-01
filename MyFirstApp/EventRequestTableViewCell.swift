import UIKit
class EventRequestTableViewCell: ImageTableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var itemTextField: UITextField!
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var vButton: UIButton!
    @IBOutlet weak var approveUserLabel: UILabel!
    
    var whenFinishedEditing: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        stopEditing()
    }
    
    public func startEditing(whenFinishedEditing: @escaping ((String) -> Void)) {
        vButton.isHidden = false
        itemLabel.isHidden = true
        itemTextField.isHidden = false
        itemTextField.isEnabled = true
        
        itemTextField.text = itemLabel.text
        
        // Request focus for the text field
        itemTextField.becomeFirstResponder()
        
        // Save the delegate function for later, when editing is done
        self.whenFinishedEditing = whenFinishedEditing
    }
    
    @IBAction private func stopEditing() {
        vButton.isHidden = true
        itemLabel.isHidden = false
        itemTextField.isEnabled = false
        itemTextField.isHidden = true
        
        let newItemName = itemTextField.text
        itemLabel.text = newItemName
        
        if let editingDelegate = whenFinishedEditing {
            // Call the delegate function
            editingDelegate(newItemName!)
        }
    }
}
