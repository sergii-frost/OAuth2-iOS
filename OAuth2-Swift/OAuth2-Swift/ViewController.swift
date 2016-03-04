//
//  ViewController.swift
//  OAuth2-Swift
//
//  Created by Sergii Nezdolii on 03/03/16.
//  Copyright © 2016 FrostDigital. All rights reserved.
//

import UIKit
import SVProgressHUD
import AFOAuth2Manager

extension String {
    public func urlEncode() -> String {
        let encodedURL = CFURLCreateStringByAddingPercentEscapes(
            nil,
            self as NSString,
            nil,
            "!@#$%&*'();:=+,/?[]",
            CFStringBuiltInEncodings.UTF8.rawValue)
        return encodedURL as String
    }
}

class ViewController: UIViewController {

    //MARK: IBOutlets
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    @IBOutlet weak var outputTV: UITextView!
    
    var isObserved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputTV?.text = ""
    }
    

    @IBAction func authenticate() {
        
        let baseURL = NSURL(string: "https://api.instagram.com")
        
        if !isObserved {
            // 2 Add observer
            NSNotificationCenter.defaultCenter().addObserverForName(
                kAppLaunchedWithAuthRedirectNotification,
                object: nil,
                queue: nil,
                usingBlock: { (notification: NSNotification!) -> Void in
                    // [5] extract code
                    let code = self.extractCode(notification)
                    self.consoleOut("Code to authenticate: \(code)")
                    
                    // [6] carry on oauth2 code auth grant flow with AFOAuth2Manager
                    let manager = AFOAuth2Manager(baseURL: baseURL,
                        clientID: kInstagramClientID,
                        secret: kInstagramClientSecret)
                    manager.useHTTPBasicAuthentication = false
                    
                    // [7] exchange authorization code for access token
                    manager.authenticateUsingOAuthWithURLString("oauth/access_token",
                        code: code,
                        redirectURI: kInstagramRedirection,
                        success: { (cred: AFOAuthCredential!) -> Void in
                            
                            // [8] Set credential in header
                            manager.requestSerializer.setValue("Bearer \(cred.accessToken)",
                                forHTTPHeaderField: "Authorization")
                            
                            // [9] Get Information about the user
                            manager.GET("https://api.instagram.com/v1/users/self",
                                parameters: ["access_token": cred.accessToken],
                                success: { (op: AFHTTPRequestOperation!, response: AnyObject) -> Void in
                                    self.consoleOut(response.description)
                                }, failure: { (op: AFHTTPRequestOperation?, error: NSError) -> Void in
                                    self.consoleOut(error.description)
                            })
                            
                        }, failure: { (NSError error) -> Void in
                            self.consoleOut(error.description)
                        })
                    self.isObserved = true
            })
        }
        
        authorize()
    }
    
    private func authorize() {        
        let authorizationUrl: String! = "https://api.instagram.com/oauth/authorize/?client_id=\(kInstagramClientID)&redirect_uri=\(kInstagramRedirection.urlEncode())&response_type=code"
        UIApplication.sharedApplication().openURL(NSURL(string: authorizationUrl)!)
    }
    
    
    //MARK: Helper methods 
    
    func extractCode(notification: NSNotification) -> String? {
        let url: NSURL? = (notification.userInfo as!
            [String: AnyObject])[UIApplicationLaunchOptionsURLKey] as? NSURL
        
        // [1] extract the code from the URL
        return self.parametersFromQueryString(url?.query)["code"]
    }
    
    private func parametersFromQueryString(queryString: String?) -> [String: String] {
        var parameters = [String: String]()
        if (queryString != nil) {
            let parameterScanner: NSScanner = NSScanner(string: queryString!)
            var name:NSString? = nil
            var value:NSString? = nil
            while (parameterScanner.atEnd != true) {
                name = nil;
                parameterScanner.scanUpToString("=", intoString: &name)
                parameterScanner.scanString("=", intoString:nil)
                value = nil
                parameterScanner.scanUpToString("&", intoString:&value)
                parameterScanner.scanString("&", intoString:nil)
                if (name != nil && value != nil) {
                    parameters[name!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!]
                        = value!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                }
            }
        }
        return parameters
    }

    private func consoleOut(text: String!) {
        print(text)
        if outputTV != nil {
            outputTV.text = outputTV.text + "\n" + text
            outputTV.scrollToBotom()
        }
    }

}

