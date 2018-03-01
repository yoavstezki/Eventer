import Foundation
import UIKit
import FacebookLogin

class ProfileViewController: UIViewController, LoginButtonDelegate
{
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var loginButtonView: UIButton!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var chooseImageDialog: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideChooseImageDialog()
        
        // Get the User & Image (this will fetch only from cache, because the user was already fetched from DB)
        UsersDB.sharedInstance.findUserByKey(key: AuthenticationUtilities.sharedInstance.getId()!, whenFinished: refreshLabels)
        ImageDB.sharedInstance.downloadImage(userId: AuthenticationUtilities.sharedInstance.getId()!, whenFinished: refreshImage)
        
        initializeFacebookLoginButton()
    }
    
    func refreshLabels(user:User?) -> Void {
        let userName = user!.name!
        var finalString:String
        
        if (userName != "") {
            finalString = "\(userName)"
        }
        else {
            finalString = "Hello!"
        }
        
        self.greetingLabel.text = finalString
    }
    
    private func initializeFacebookLoginButton() {
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends])
        loginButton.delegate = self
        loginButtonView.addSubview(loginButton)
    }

    public func refreshImage(image:UIImage?) {
        imagePicked.image = image
    }
    
    @IBAction func showChooseImageDialog(sender: AnyObject) {
        chooseImageDialog.isHidden = false
    }
    
    private func hideChooseImageDialog() {
        chooseImageDialog.isHidden = true
    }
    
    func saveImage(image:UIImage?) {
        // Save the image to db
        ImageDB.sharedInstance.storeImage(image: image!, userId: AuthenticationUtilities.sharedInstance.getId()!)

        refreshImage(image: image)
    }
    
    public func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {}
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        // Truncate the user-groups table (In case we will login to another user)
        LastUpdateTable.deleteLastUpdate(database: LocalDb.sharedInstance?.database, table: UserGroupsTable.TABLE, key: AuthenticationUtilities.sharedInstance.getId()!)
        UserGroupsTable.truncateTable(database: LocalDb.sharedInstance?.database)
        
        AuthenticationUtilities.sharedInstance.signOut()
        FacebookAccessTokenCache.sharedInstance.clear()

        // Unwind back to MainController
        self.performSegue(withIdentifier: "UnwindLogOut", sender: self)
    }
    
    @IBAction func backFromChooseImageDialog(seque:UIStoryboardSegue) {
        hideChooseImageDialog()
    }
}
