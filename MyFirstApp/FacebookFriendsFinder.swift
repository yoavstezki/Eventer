import Foundation
import FacebookCore

class FacebookFriendsFinder {
    func find(currentMembers: Array<User>, forEachFriend: @escaping (_: User) -> Void, whenFinished: @escaping (Bool)->()) {
        let connection = GraphRequestConnection()

        connection.add(GraphRequest(graphPath: "/me/friends", parameters: ["fields": "name, id"])) {
            (httpResponse, result) in
            switch result {
                case .success(let response):
                    let data = response.dictionaryValue!["data"]! as! NSArray
                    var noFriendsToAdd = true
                        
                    data.forEach( {(value) in
                        let friendData = value as! NSDictionary
                        let currentFriendFacebookId = friendData["id"] as! String
                        
                        // Make sure this user isn't already a member in the group
                        if (!currentMembers.contains(where: { $0.facebookId!.isEqual(to: currentFriendFacebookId) })) {
                            UsersDB.sharedInstance.findUserByFacebookId(facebookId: currentFriendFacebookId,
                                                                               whenFinished: forEachFriend)
                            noFriendsToAdd = false
                        }
                    })
                    
                    whenFinished(noFriendsToAdd)
                case .failed(let error):
                    print("Graph Request Failed: \(error)")
            }
        }

        connection.start()
    }
}
