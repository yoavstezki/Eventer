import Foundation
import UIKit

class RoundedDialog: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 2
        self.layer.cornerRadius = self.frame.size.width / 20
        self.layer.borderColor = UIColor.black.cgColor
        self.clipsToBounds = true
    }
}
