import Foundation
import Firebase

class ImageDB {
    private static let defaultImage = UIImage(named: "user")
    
    static let sharedInstance: ImageDB = { ImageDB() } ()
    var storageRef: FIRStorageReference?
    
    // Array of callback functions. Observers insert their functions here, and are notified when the user changes his image.
    static var callbacks: Array<()->()> = []
    
    private init() {
        configureStorage()
    }
    
    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    static func observeImageModification(whenImageModified: @escaping () -> ()) {
        callbacks.append(whenImageModified)
    }
    
    private static func executeCallbacks() {
        for callback in callbacks {
            callback()
        }
    }

    // store user image in firebase storage
    func storeImage(image: UIImage, userId: String) {
        storeImage(image: image, userId: userId, whenFinished: {
            // Notify the observers
            ImageDB.executeCallbacks()
        })
    }
    
    func storeImage(image: UIImage, userId: String, whenFinished: @escaping ()->()) {
        // Don't store the default picture
        if (!(ImageDB.defaultImage!.isEqual(image))) {
            let imageData = UIImageJPEGRepresentation(image, 0.5)
            let imagePath = "\(userId).jpg"

            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"

            self.storageRef?.child(imagePath).put(imageData!, metadata: metadata) {(metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
                
                // Save the image to local storage
                LocalImageStorage.sharedInstance.saveImageToFile(image: image, name: imagePath);
 
                whenFinished()
            }
        }
    }
    
    func downloadImage(userId: String, whenFinished: @escaping (UIImage?) -> Void) {
        let imagePath = "\(userId).jpg"
        
        // Make sure the image is up to date
        manageRefreshImage(imagePath: imagePath, whenFinished: whenFinished)
        
        // If there was no need to refresh
        // If image exists in local storage
        if let image = LocalImageStorage.sharedInstance.getImageFromFile(name: imagePath) {
            whenFinished(image)
        }
        else {
            getImageFromRemote(imagePath: imagePath, whenFinished: whenFinished)
        }
    }
    
    private func getImageFromRemote(imagePath: String, whenFinished: @escaping (UIImage?)  -> Void) {
        var image:UIImage?

        self.storageRef?.child(imagePath).data(withMaxSize: INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                        
                // Return the default image
                whenFinished(ImageDB.defaultImage)
                return
            }
                
            image = UIImage.init(data: data!)!
                
            // Save the image to local storage
            LocalImageStorage.sharedInstance.saveImageToFile(image: image!, name: imagePath);
            
            whenFinished(image)
        }
    }
    
    private func manageRefreshImage(imagePath: String, whenFinished: @escaping (UIImage?) -> Void) {
        // Create reference to the file whose metadata we want to retrieve
        let imageRef = self.storageRef?.child(imagePath)
        
        // Get metadata properties
        imageRef?.metadata { metadata, error in
            if let error = error {
                // An error occurred!
                print ("Error getting update time: \(error)")
                return
            }
            else {
                // Metadata now contains the metadata for the image
                self.compareUpdateTimes(imagePath: imagePath, remoteUpdateTime: metadata?.updated, whenFinished: whenFinished)
            }
        }
    }
    
    private func compareUpdateTimes(imagePath: String, remoteUpdateTime: Date?, whenFinished: @escaping (UIImage?) -> Void) {
        let localUpdateTime = LocalImageStorage.sharedInstance.getUpdateTime(path: imagePath)
        
        // Check if the remote image was updated
        if (remoteUpdateTime != nil &&
            (localUpdateTime == nil || localUpdateTime?.compare(remoteUpdateTime!) == .orderedAscending)) {
            // Download the new remote image
            getImageFromRemote(imagePath: imagePath, whenFinished: whenFinished)
        }
        else {
            return
        }
    }
}
