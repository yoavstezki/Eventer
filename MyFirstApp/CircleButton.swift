import Foundation
import UIKit

class CircleButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = (self.frame.size.width / 100)
        self.layer.cornerRadius = (self.frame.size.width / 2)
        self.layer.borderColor = UIColor.black.cgColor
        self.clipsToBounds = true
    }
}
