import Foundation
import UIKit

class ChooseImageDialogViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        self.dismiss(animated: true, completion: nil);
        self.closeDialog()
    }
    
    @IBAction func closeDialog() {
        // Unwind back to CameraViewController
        self.performSegue(withIdentifier: "UnwindChooseImageDialog", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "UnwindChooseImageDialog") {
            // Save the image only if one was selected
            if (image != nil) {
                // Get a reference to the destination view controller
                let destinationVC:ProfileViewController = segue.destination as! ProfileViewController
            
                destinationVC.saveImage(image: image)
            }
        }
    }
}
