import Foundation
import FacebookCore

class FacebookAccessTokenCache {
    static let sharedInstance: FacebookAccessTokenCache = { FacebookAccessTokenCache() } ()
    let accessTokenKey = "accessToken"
    let expirationDateKey = "expirationDate"

    private init() {}

    // This function loads the stored facebook access token when the app starts, and logs in automatically
    func load() -> AccessToken? {
        let cachedAccessToken = UserDefaults.standard.object(forKey: accessTokenKey)
        let cachedExpiration = UserDefaults.standard.object(forKey: expirationDateKey)

        if let accessToken = cachedAccessToken as? String,
           let expiration = cachedExpiration as? Date {
            return AccessToken.init(authenticationToken: accessToken, expirationDate: expiration)
        }

        return nil
    }

    // This function stores the facebook access token, so that when we start the app we will be able to login automatically
    func store(_ accessToken: AccessToken) {
        UserDefaults.standard.set(accessToken.authenticationToken, forKey: accessTokenKey)
        UserDefaults.standard.set(accessToken.expirationDate, forKey: expirationDateKey)
    }

    // This function is called on logout - clears the FB access token
    func clear() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: expirationDateKey)
    }
}
