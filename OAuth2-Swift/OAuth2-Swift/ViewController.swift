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
import SwiftyJSON
import SDWebImage

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
    
    @IBOutlet weak var outputTV: UITextView!
    
    @IBOutlet weak var avatar: UIImageView!
    var isObserved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputTV?.text = ""
    }

    @IBAction func authenticate() {
        
        
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
                    let manager = AFOAuth2Manager(baseURL: NSURL(string: kFortumBaseUrl),
                        clientID: kFortumClientID,
                        secret: kFortumClientSecret)
                    manager.useHTTPBasicAuthentication = false
                    
                    // [7] exchange authorization code for access token
                    manager.authenticateUsingOAuthWithURLString(kFortumTokenUrl,
                        code: code,
                        redirectURI: kFortumRedirectUrl,
                        success: { (cred: AFOAuthCredential!) -> Void in
                            self.consoleOut("Access Token: \(cred.accessToken)")
                            // [8] Set credential in header
                            manager.requestSerializer.setValue("Bearer \(cred.accessToken)",
                                forHTTPHeaderField: "Authorization")
                            manager.responseSerializer = AFJSONResponseSerializer()
                            
                            // [9] Get Information about the user
                            manager.GET(kFortumUserInfoUrl,
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
        guard outputTV != nil else {
            return
        }
        outputTV.text = outputTV.text + "\n" + text
        outputTV.scrollToBotom()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SSOLoginSegue" {
            guard let loginVC = segue.destinationViewController as? LoginViewController else {
                return
            }
            
            loginVC.baseUrl = kFortumAuthUrl + "?response_type=code&&scope=openid&client_id=\(kFortumClientID)&redirect_uri=\(kFortumRedirectUrl.urlEncode())"
            authenticate()
        }
    }
}

