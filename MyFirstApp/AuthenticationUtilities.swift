import Foundation
import Firebase

class AuthenticationUtilities {
    static let sharedInstance: AuthenticationUtilities = { AuthenticationUtilities() } ()

    private init() {}

    func getId() -> String? {
        return getCurrentUser()?.uid
    }

    func getFacebookUser() -> FIRUserInfo? {
        let currentUser = getCurrentUser()
        guard let index = currentUser?.providerData.index(where: { $0.providerID.contains("facebook.com") }) else {
            return nil
        }

        return currentUser!.providerData[index]
    }

    private func getCurrentUser() -> FIRUser? {
        return FIRAuth.auth()?.currentUser
    }

    public func signIn(facebookAuthenticationToken: String, whenFinished: @escaping () -> Void) {
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: facebookAuthenticationToken)

        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if let error = error {
                print("Error logging in : \(error)")
                return
            }

            whenFinished()
        }
    }
    
    public func signOut() {
        do {
            try FIRAuth.auth()?.signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out from Firebase: \(signOutError)")
        }
    }
}
