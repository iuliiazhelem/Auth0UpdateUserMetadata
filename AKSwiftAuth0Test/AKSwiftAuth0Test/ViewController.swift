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
        //TODO: correct creation of UserPatchAttributes
        //let attributes = UserPatchAttributes().userMetadata(metadata: ["name": "\(self.nameMetadataTextField.text!)", "country": "\(self.countryMetadataTextField.text!)"])
        
        let attributes = ["name": "\(self.nameMetadataTextField.text!)", "country": "\(self.countryMetadataTextField.text!)"]
        //create PATCH request for creating/updating user metadata
        //APIv2 https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id
        if let actualToken = self.tokenId, let actualUserId = self.userId {
            Auth0
                .users(token: actualToken)
                //.patch(actualUserId, attributes: attributes)
                .patch(actualUserId, userMetadata: attributes)
                .start { result in
                    switch result {
                    case .Success(let profile):
                        if let metadata = profile["user_metadata"] {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.metadataText.text = "\(metadata)"
                                print("metadata: \(metadata)")
                            }
                        }
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
        //signup with user metadata
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

