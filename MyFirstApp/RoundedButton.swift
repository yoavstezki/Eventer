import Foundation
import UIKit

class RoundedButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 1 // Set border width
        self.layer.cornerRadius = 5 // Set border radius (Make it curved, increase this for a more rounded button
        self.layer.borderColor = UIColor(red: 81/255, green: 159/255, blue: 243/255, alpha: 1).cgColor
        self.layer.backgroundColor = UIColor.white.cgColor
    }
}
