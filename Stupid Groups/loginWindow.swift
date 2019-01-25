//
//  loginWindow.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Foundation
import Cocoa

// This delegate is required to pass the base64 credentials and URL to the main view
protocol DataSentDelegate {
    func userDidAuthenticate(base64Credentials: String, url: String)
}

class loginWindow: NSViewController, URLSessionDelegate {

    // Set up defaults and a delegate used for credential/url passing
    let loginDefaults = UserDefaults.standard
    var delegateAuth: DataSentDelegate? = nil

    // Declare outlets used on the login screen
    @IBOutlet weak var txtURLOutlet: NSTextField!
    @IBOutlet weak var txtUserOutlet: NSTextField!
    @IBOutlet weak var txtPassOutlet: NSSecureTextField!
    @IBOutlet weak var spinProgress: NSProgressIndicator!
    @IBOutlet weak var btnSubmitOutlet: NSButton!
    @IBOutlet weak var chkRememberMe: NSButton!
    @IBOutlet weak var chkBypass: NSButton!
    
    var doNotRun: String!
    var serverURL: String!
    var base64Credentials: String!
    var verified = false

    // This punctuation variable is used for cleaning thngs up below
    let punctuation = CharacterSet(charactersIn: ".:/")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore the Username to text box if we have a default stored
        if loginDefaults.value(forKey: "UserName") != nil {
            txtUserOutlet.stringValue = loginDefaults.value(forKey: "UserName") as! String
        }
        
        // Restore Prem URL to text box if we have a default stored
        if loginDefaults.value(forKey: "InstanceURL") != nil {
            txtURLOutlet.stringValue = loginDefaults.value(forKey: "InstanceURL") as! String
        }
        
        if ( loginDefaults.value(forKey: "InstanceURL") != nil || loginDefaults.value(forKey: "InstanceURL") != nil ) && loginDefaults.value(forKey: "UserName") != nil {
            if self.txtPassOutlet.acceptsFirstResponder == true {
                self.txtPassOutlet.becomeFirstResponder()
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        preferredContentSize = NSSize(width: 383, height: 400) // Limits resizing of the window
        // If we have a URL and a User stored focus the password field
        if loginDefaults.value(forKey: "InstanceURL") != nil  && loginDefaults.value(forKey: "UserName") != nil {
            self.txtPassOutlet.becomeFirstResponder()
        }
    }
    
    @IBAction func btnSubmit(_ sender: Any) {

        // Clean up extraneous whitespace characters
        txtURLOutlet.stringValue = txtURLOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        txtUserOutlet.stringValue = txtUserOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        txtPassOutlet.stringValue = txtPassOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        
        // Warn the user if they have failed to enter an instancename or prem URL
        if txtURLOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Server Info", text: "It appears that you have not entered any information for your Jamf Pro URL. Please enter either a Jamf Cloud instance name, or your full URL if you host your own server.")
            NSLog("[ERROR ]: No server info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Warn the user if they have failed to enter a username
        if txtUserOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Username Found", text: "It appears that you have not entered a username for Stupid Groups to use while accessing Jamf Pro. Please enter your username and password, and try again.")
            NSLog("[ERROR ]: No user info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Warn the user if they have failed to enter a password
        if txtPassOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Password Found", text: "It appears that you have not entered a password for Stupid Groups to use while accessing Jamf Pro. Please enter your username and password, and try again.")
            NSLog("[ERROR ]: No password info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Move forward with verification if we have not flagged the doNotRun flag
        if doNotRun != "1" {
            
            // Create the API-Friendly Jamf Pro URL with resource appended, cleaning up double slashes
            if txtURLOutlet.stringValue.rangeOfCharacter(from: punctuation) == nil {
                serverURL = "https://\(txtURLOutlet.stringValue).jamfcloud.com/JSSResource/"
            } else {
                serverURL = "\(txtURLOutlet.stringValue)/JSSResource/"
                serverURL = serverURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            }

            btnSubmitOutlet.isHidden = true
            spinProgress.startAnimation(self)
            
            // Concatenate the credentials and base64 encode the resulting string
            let concatCredentials = "\(txtUserOutlet.stringValue):\(txtPassOutlet.stringValue)"
            let utf8Credentials = concatCredentials.data(using: String.Encoding.utf8)
            base64Credentials = utf8Credentials?.base64EncodedString()
            
            // MARK - Credential Verification API Call
            let testURL = prepareData().createAuthURL(url: self.serverURL!)
            let authResponse = API().get(getCredentials: self.base64Credentials!, getURL: testURL)
            print(authResponse)

            // Look for the activation_code tag in the response. This works far better
            // than looking for a 200 response, because Jamf Now instances do not have
            // an API, but if you run a GET to them, you will always get a 200 response.
            // This causes issues with MUT, and I plan to implement this same code there as well.
            if authResponse.contains("<activation_code><organization_name>") {
                NSLog("[INFO  ]: Successful authentication attempt.")
                self.verified = true
                // Store username if remember me is checked
                if self.chkRememberMe.state.rawValue == 1 {
                    self.loginDefaults.set(self.txtUserOutlet.stringValue, forKey: "UserName")
                    self.loginDefaults.set(self.txtURLOutlet.stringValue, forKey: "InstanceURL")
                    self.loginDefaults.set(true, forKey: "Remember")
                    self.loginDefaults.synchronize()

                // Dump the stored defaults if no remember me is checked
                } else {
                    self.loginDefaults.removeObject(forKey: "UserName")
                    self.loginDefaults.removeObject(forKey: "InstanceURL")
                    self.loginDefaults.set(false, forKey: "Remember")
                    self.loginDefaults.synchronize()
                }
                self.spinProgress.stopAnimation(self)
                self.btnSubmitOutlet.isHidden = false

                // Pass the information forward using the delgate and dismiss the login view
                if self.delegateAuth != nil {
                    self.delegateAuth?.userDidAuthenticate(base64Credentials: self.base64Credentials!, url: self.serverURL!)
                    self.dismiss(self)
                }
            } else {

                // Display an error message if there is no activation_code tag found
                DispatchQueue.main.async {
                    self.spinProgress.stopAnimation(self)
                    self.btnSubmitOutlet.isHidden = false
                    _ = popPrompt().generalWarning(question: "Invalid Credentials", text: "The credentials you entered do not seem to have sufficient permissions. This could be due to an incorrect user/password, or possibly from insufficient permissions. Stupid Groups tests this against the user's ability to view the Activation Code via the API.")
                    NSLog("[INFO  ]: Invalid authentication attempt.")

                    // Pass forward credentials and dismiss view if the "bypass authentication"
                    // checkbox is checked. This is used in security-conscious organizations
                    // where some admins have minimal permissions, and cannot GET the activation code
                    if self.chkBypass.state.rawValue == 1 {
                        if self.delegateAuth != nil {
                            self.delegateAuth?.userDidAuthenticate(base64Credentials: self.base64Credentials!, url: self.serverURL!)
                            self.dismiss(self)
                        }
                        self.verified = true
                    }
                }
            }
        } else {
            // Reset the Do Not Run flag so that on subsequent runs we try the checks again.
            doNotRun = "0"
        }
    }
    
    // This is required to allow un-trusted SSL certificates. Leave it alone.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

    // This is added because it is actually the only way to quit the app with the sheet view
    // down over the main view controller.
    @IBAction func btnQuit(_ sender: Any) {
        self.dismiss(self)
        NSApplication.shared.terminate(self)
    }
}

