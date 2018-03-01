import Foundation
import UIKit

class LocalImageStorage {
    static let sharedInstance: LocalImageStorage = { LocalImageStorage() } ()
    
    public func saveImageToFile(image:UIImage, name:String) {
        // Create the data for the image
        if let data = UIImageJPEGRepresentation(image, 1) {
            
            // Get the filename
            let filename = getDocumentsDirectory().appendingPathComponent(name)
            
            // Write the data to the file
            try? data.write(to: filename)
        }
    }
    
    public func getImageFromFile(name:String)->UIImage? {
        // Get the filename
        let filename = getDocumentsDirectory().appendingPathComponent(name)
        
        // Get the UIImage from the file
        return UIImage(contentsOfFile:filename.path)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func getUpdateTime(path: String) -> NSDate? {
        // Get the file url
        let fileUrl = getDocumentsDirectory().appendingPathComponent(path) as NSURL
        var modified: AnyObject?
        
        do {
            // Return the date modified
            try fileUrl.getResourceValue(&modified, forKey: URLResourceKey.contentModificationDateKey)
            return modified as? NSDate
        }
        catch let error as NSError {
            print("\(#function) Error: \(error)")
            return nil
        }
    }
}
