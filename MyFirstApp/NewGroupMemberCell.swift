import UIKit
class NewGroupMemberCell: GroupMemberCell {
    
    // MARK: Properties
    @IBOutlet weak var doneButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        doneButton.isHidden = true
    }
    
    func toggleDone() {
        doneButton.isHidden = !doneButton.isHidden
    }
    
    func setTag(tag: Int) {
        doneButton.tag = tag
    }
}
