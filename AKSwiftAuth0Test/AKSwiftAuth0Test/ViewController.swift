//
//  ViewController.swift
//  AKSwiftAuth0Test
//
//  Created by Iuliia Zhelem on 08.07.16.
//  Copyright © 2016 Akvelon. All rights reserved.
//

import UIKit
import Lock

//Please use your Auth0 APIv2 token from https://auth0.com/docs/api/management/v2/tokens
//scopes : update:users
let kAuth0APIv2Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJJdUFiSnZvZXpwZTFFWUM2ZVhRRUoyd0QwSm5MOE5IZSIsInNjb3BlcyI6eyJ1c2VycyI6eyJhY3Rpb25zIjpbInVwZGF0ZSJdfX0sImlhdCI6MTQ2ODA0NjQ1MSwianRpIjoiOTA5MmJiMzBiNTJhNWYxNDQ5NjQ0NjNiZjY3ODM3OWUifQ.YS24m0ywZo2B6Y2Wfu11zzudLHU-25XK3DIiSZPVldA"

class ViewController: UIViewController {
    
    var userId:String?
    
    required init?(coder aDecoder: NSCoder) {
        userId = nil
        super.init(coder: aDecoder)
    }


    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var nameMetadataTextField: UITextField!
    @IBOutlet weak var countryMetadataTextField: UITextField!
    @IBOutlet weak var metadataText: UITextView!

    @IBAction func clickOpenLockUIButton(sender: AnyObject) {
        let controller = A0Lock.sharedLock().newLockViewController()
        controller.closable = true
        controller.onAuthenticationBlock = { (profile: A0UserProfile?, token: A0Token?) in
            dispatch_async(dispatch_get_main_queue()) {
                self.usernameLabel.text = profile!.name
                self.emailLabel.text = profile!.email
                self.userIdLabel.text = profile!.userId
                self.userId = profile!.userId
                self.metadataText.text = "\(profile!.userMetadata)"
                print("metadata: \(profile!.userMetadata)")
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.presentViewController(controller, animated: true, completion: nil)

    }

    @IBAction func clickUpdateUserdataButton(sender: AnyObject) {
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
    
    func showMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Auth0", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

