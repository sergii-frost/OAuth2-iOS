//
//  LoginViewController.swift
//  OAuth2-Swift
//
//  Created by Sergii Nezdolii on 07/03/16.
//  Copyright © 2016 FrostDigital. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webview: UIWebView!
    
    var baseUrl: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let baseRequest = NSURLRequest(URL: NSURL(string: baseUrl)!)
        webview.loadRequest(baseRequest)
    }
    
    //MARK: UIWebView Delegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("URL to load: \(request.URL?.absoluteString)")
        if request.URL?.host == NSURL(string: kFortumRedirectUrl)?.host {
            guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
                return true
            }
            dismiss()
            appDelegate.handleOAuthRedirect(request.URL!)
            return false
        }
        return true
    }
    
    func dismiss() {
        if self.navigationController != nil {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
}
