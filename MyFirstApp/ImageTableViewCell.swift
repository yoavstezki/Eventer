import UIKit

class ImageTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var imagez: UIImageView!
    @IBOutlet weak var pleaseWait: UIActivityIndicatorView!
    
    public func showSpinner() {
        imagez.isHidden = true
        pleaseWait.isHidden = false
        pleaseWait.startAnimating()
    }
    
    public func hideSpinner() {
        pleaseWait.stopAnimating()
        pleaseWait.isHidden = true
        imagez.isHidden = false
    }
}
