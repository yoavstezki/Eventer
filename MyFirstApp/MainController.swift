import UIKit
import Darwin
import FacebookLogin
import FacebookCore

class MainController: UIViewController, LoginButtonDelegate {
    let defaultGreeting = "Hello"
    var user: User? = nil;
    var greetingPrefix: String = ""
    var newUser: Bool = true

    // MARK: Properties
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var loginButtonView: UIView!
    @IBOutlet weak var pleaseWait: UIActivityIndicatorView!

    // MARK: Other functions
    override func viewDidLoad() {
        super.viewDidLoad()

        pleaseWait.isHidden = true

        greetingPrefix = defaultGreeting
        initializeFacebookLoginButton()
        initializeCurrentUserData()
    }

    func initializeFacebookLoginButton() {
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email, .userFriends])
        loginButton.delegate = self
        loginButtonView.addSubview(loginButton)
    }

    func initializeCurrentUserData() {
        let accessToken = FacebookAccessTokenCache.sharedInstance.load()

        if (accessToken != nil && accessToken!.expirationDate > Date()) {
            self.greetingPrefix = "Welcome back"
            self.newUser = false

            AccessToken.current = accessToken
            loadUserData()
        }
    }

    private func loadUserData() {
        let userId = AuthenticationUtilities.sharedInstance.getId()!

        UsersDB.sharedInstance.findUserByKey(key: userId,
                whenFinished: refreshUserNotificationReceived)
        ImageDB.sharedInstance.downloadImage(userId: userId, whenFinished: { (_) in })
    }

    private func showSpinner() {
        pleaseWait.isHidden = false
        pleaseWait.startAnimating()
    }

    private func hideSpinner() {
        pleaseWait.stopAnimating()
        pleaseWait.isHidden = true
    }

    func refreshUserNotificationReceived(userFromDB: User?) {
        if (userFromDB != nil) {
            user = userFromDB
            refreshLabels()
            hideSpinner()

            // Continue
            self.performSegue(withIdentifier: "ContinueSegue", sender: self)
        }
    }

    @IBAction func refreshLabels() {
        let userName = user!.name!

        var finalString: String

        if (userName != "") {
            finalString = "\(greetingPrefix), \(userName)!"
        } else {
            finalString = "\(greetingPrefix)!"
        }

        greetingLabel.text = finalString
    }

    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .failed(let error):
            print(error)
        case .cancelled:
            print("User cancelled login.")
        case .success(_, let declinedPermissions, let accessToken):
            if declinedPermissions.count > 0 {
                showCantDeclinePermissionsAlert()
                AccessToken.current = nil
            } else {
                // Hide the logOut button
                loginButtonView.isHidden = true
                showSpinner()

                AuthenticationUtilities.sharedInstance.signIn(
                        facebookAuthenticationToken: accessToken.authenticationToken,
                        whenFinished: tryFindingUserInDB)
                FacebookAccessTokenCache.sharedInstance.store(accessToken)
            }
        }
    }

    private func showCantDeclinePermissionsAlert() {
        let alert = UIAlertController(
                title: "Sorry!",
                message: "All permissions must be approved in order to use this app",
                preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func tryFindingUserInDB() {
        UsersDB.sharedInstance.findUserByKey(key: AuthenticationUtilities.sharedInstance.getId()!, whenFinished: { (existingUser) in
            if (existingUser != nil) {
                self.greetingPrefix = "Welcome back"
                self.newUser = false
                self.loadUserData()
            } else {
                self.greetingPrefix = "Welcome"
                self.createUser()
            }
        })
    }

    private func downloadAndSaveFacebookProfilePic(facebookId: NSString) {
        FacebookImageManager().getFacebookProfilePic(facebookId: facebookId, whenFinished: gotFacebookProfilePic)
    }

    private func gotFacebookProfilePic(image: UIImage?) {
        if let profilePic = image {
            ImageDB.sharedInstance.storeImage(image: profilePic, userId: AuthenticationUtilities.sharedInstance.getId()!, whenFinished: loadUserData)
        }
    }

    private func createUser() {
        let facebookId = AuthenticationUtilities.sharedInstance.getFacebookUser()!.uid as NSString

        let newUser = User(key: AuthenticationUtilities.sharedInstance.getId()! as NSString,
                name: AuthenticationUtilities.sharedInstance.getFacebookUser()!.displayName! as NSString,
                facebookId: facebookId)

        // When finished: downloadAndSaveFacebookProfilePic
        UsersDB.sharedInstance.addUser(user: newUser, whenFinished: { (_, _) in self.downloadAndSaveFacebookProfilePic(facebookId: facebookId) })
    }

    func loginButtonDidLogOut(_ loginButton: LoginButton) {
    }

    private func elapseScreenData() {
        greetingLabel.text = "\(defaultGreeting)!"
    }

    // MARK: Actions
    @IBAction func Exit(sender: AnyObject) {
        // Exit the application
        exit(0)
    }

    @IBAction func backFromLogOut(seque: UIStoryboardSegue) {
        elapseScreenAfterLogout()
    }

    func elapseScreenAfterLogout() {
        loginButtonView.isHidden = false
        elapseScreenData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ContinueSegue") {
            // Get a reference to the destination view controller
            let destinationVC: UITabBarController = segue.destination as! UITabBarController

            if (!self.newUser) {
                // Select the grocery tab
                destinationVC.selectedIndex = 1
            }
        }
    }
}
