//
//  ViewController.swift
//  AKSwiftAuth0Test
//
//  Created by Iuliia Zhelem on 08.07.16.
//  Copyright © 2016 Akvelon. All rights reserved.
//

import UIKit
import Lock
import Auth0

//Please use your Auth0 APIv2 token from https://auth0.com/docs/api/management/v2/tokens
//scopes : update:users
let kAuth0APIv2Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJJdUFiSnZvZXpwZTFFWUM2ZVhRRUoyd0QwSm5MOE5IZSIsInNjb3BlcyI6eyJ1c2VycyI6eyJhY3Rpb25zIjpbInVwZGF0ZSJdfX0sImlhdCI6MTQ2ODA0NjQ1MSwianRpIjoiOTA5MmJiMzBiNTJhNWYxNDQ5NjQ0NjNiZjY3ODM3OWUifQ.YS24m0ywZo2B6Y2Wfu11zzudLHU-25XK3DIiSZPVldA"

class ViewController: UIViewController {
    
    var userId:String?
    var tokenId:String?
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var nameMetadataTextField: UITextField!
    @IBOutlet weak var countryMetadataTextField: UITextField!
    @IBOutlet weak var metadataText: UITextView!

    @IBAction func clickOpenLockUIButton(sender: AnyObject) {
        let controller = A0Lock.sharedLock().newLockViewController()
        controller.closable = true
        controller.onAuthenticationBlock = { (profile: A0UserProfile?, token: A0Token?) in
            self.tokenId = token?.idToken
            self.userId = profile!.userId
            dispatch_async(dispatch_get_main_queue()) {
                self.emailLabel.text = profile!.email
                self.userIdLabel.text = profile!.userId
                self.metadataText.text = "\(profile!.userMetadata)"
                print("metadata: \(profile!.userMetadata)")
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.presentViewController(controller, animated: true, completion: nil)

    }
    
    @IBAction func clickUpdateUserdataButton(sender: AnyObject) {
        self.updateUserMetadataWithAPIRequest()
    }

    func updateUserMetadataWithAPIRequest() {
        if let actualUserId = self.userId {
            // PATCH request
            // We need url "https://<Auth0 Domain>/api/v2/users/<user_id>"
            // and header "Authorization : Bearer <APIv2 token>"
            
            let userDomain = (NSBundle.mainBundle().infoDictionary!["Auth0Domain"]) as! String
            let userId = actualUserId.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let urlString = "https://\(userDomain)/api/v2/users/\(userId)"
            let url = NSURL(string: urlString)
            if let actualUrl = url {
                let request = NSMutableURLRequest(URL: actualUrl)
                request.HTTPMethod = "PATCH";
                request.allHTTPHeaderFields = ["Authorization" : "Bearer \(kAuth0APIv2Token)", "Content-Type" : "application/json"]
                
                //{"user_metadata" : {"name" : "<name>", "country" : "<country>"}}
                let body = "{\"user_metadata\":{\"name\":\"\(self.nameMetadataTextField.text!)\",\"country\":\"\(self.countryMetadataTextField.text!)\"}}"
                let bodyData:NSData = (body as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
                
                request.HTTPBody = bodyData
                
                NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data : NSData?, response : NSURLResponse?, error : NSError?) in
                    
                    // Check if data was received successfully
                    if error == nil && data != nil {
                        do {
                            // Convert NSData to Dictionary where keys are of type String, and values are of any type
                            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! [String:AnyObject]
                            print("\(json)")
                            if let metadata = json["user_metadata"] {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.metadataText.text = "\(metadata)"
                                    print("metadata: \(metadata)")
                                }
                            }
                        } catch {
                            let dataString = String(data: data!, encoding: NSUTF8StringEncoding)
                            print("Oops something went wrong: \(dataString)")
                        }
                    } else {
                        print("Oops something went wrong: \(error)")
                    }
                }).resume()
            } else {
                self.showMessage("Incorrect url");
            }
        } else {
            self.showMessage("Please login first");
        }
    }
    
    func updateUserMetadataWithAuth0Toolkit() {
        //DO NOT USE IT NOW
        //TODO: correct creation of UserPatchAttributes!
        let attributes:UserPatchAttributes? = nil
        //let attributes = UserPatchAttributes().userMetadata(metadata: ["name": "\(self.nameMetadataTextField.text!)", "country": "\(self.countryMetadataTextField.text!)"])
        if let actualToken = self.tokenId, let actualUserId = self.userId {
        Auth0
        .users(token: actualToken)
        .patch(actualUserId, attributes: attributes!)
        .start { result in
                switch result {
                case .Success(let profile):
                    print("profile email: \(profile)")
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }

    @IBOutlet weak var signupEnterEmailTextField: UITextField!
    @IBOutlet weak var signupEnterPasswordTextField: UITextField!
    @IBOutlet weak var signupEmailLabel: UILabel!
    @IBOutlet weak var signupUserIdLabel: UILabel!
    @IBOutlet weak var signupMetadataText: UITextView!

    @IBAction func clickSignUpWithUserMetadataButton(sender: AnyObject) {
        if (self.signupEnterEmailTextField.text?.characters.count < 1) {
            self.showMessage("You need to eneter email");
            return;
        }
        if (self.signupEnterPasswordTextField.text?.characters.count < 1) {
            self.showMessage("You need to eneter password");
            return;
        }

        let usermetadata = ["first_name": "support", "last_name" : "Auth0", "age" : "29"]
        Auth0
            .authentication()
            .signUp(email: self.signupEnterEmailTextField.text!, username: nil, password: self.signupEnterPasswordTextField.text!, connection: "Username-Password-Authentication", userMetadata: usermetadata)
            .start { result in
                switch result {
                case .Success(let credentials):
                    print("id_token: \(credentials.idToken)")
                    self.getUserProfile(credentials.idToken!)
                case .Failure(let error):
                    print(error)
                }
        }
    }
    
    func getUserProfile(idToken: String) {
        Auth0
            .authentication()
            .tokenInfo(token: idToken)
            .start { result in
                switch result {
                case .Success(let profile):
                    print("profile userMetadata: \(profile.userMetadata)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.signupEmailLabel.text = profile.email
                        self.signupUserIdLabel.text = profile.id
                        self.signupMetadataText.text = "\(profile.userMetadata)"
                        print("metadata: \(profile.userMetadata)")
                    }
                case .Failure(let error):
                    print(error)
                }
        }
    }
    
    func showMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Auth0", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

