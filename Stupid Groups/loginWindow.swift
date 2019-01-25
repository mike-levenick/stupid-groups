//
//  loginWindow.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Foundation
import Cocoa

protocol DataSentDelegate {
    func userDidAuthenticate(base64Credentials: String, url: String)
}

class loginWindow: NSViewController, URLSessionDelegate {
    //class here
    
    let loginDefaults = UserDefaults.standard
    var delegateAuth: DataSentDelegate? = nil
    
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
        preferredContentSize = NSSize(width: 383, height: 400)
        // If we have a URL and a User stored focus the password field
        if loginDefaults.value(forKey: "InstanceURL") != nil  && loginDefaults.value(forKey: "UserName") != nil {
            self.txtPassOutlet.becomeFirstResponder()
        }
    }
    
    @IBAction func btnSubmit(_ sender: Any) {

        txtURLOutlet.stringValue = txtURLOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        txtUserOutlet.stringValue = txtUserOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        txtPassOutlet.stringValue = txtPassOutlet.stringValue.trimmingCharacters(in: CharacterSet.whitespaces)
        
        // Warn the user if they have failed to enter an instancename AND prem URL
        if txtURLOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Server Info", text: "It appears that you have not entered any information for your Jamf Pro URL. Please enter either a Jamf Cloud instance name, or your full URL if you host your own server.")
            NSLog("ERROR: No server info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Warn the user if they have failed to enter a username
        if txtUserOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Username Found", text: "It appears that you have not entered a username for Stupid Groups to use while accessing Jamf Pro. Please enter your username and password, and try again.")
            NSLog("ERROR: No user info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Warn the user if they have failed to enter a password
        if txtPassOutlet.stringValue == "" {
            _ = popPrompt().generalWarning(question: "No Password Found", text: "It appears that you have not entered a password for Stupid Groups to use while accessing Jamf Pro. Please enter your username and password, and try again.")
            NSLog("ERROR: No password info was entered. Setting doNotRun to 1")
            doNotRun = "1" // Set Do Not Run flag
        }
        
        // Move forward with verification if we have not flagged the doNotRun flag
        if doNotRun != "1" {
            
            // Create the API-Friendly Jamf Pro URL with resource appended
            if txtURLOutlet.stringValue.rangeOfCharacter(from: punctuation) == nil {
                serverURL = "https://\(txtURLOutlet.stringValue).jamfcloud.com/JSSResource/"
            } else {
                serverURL = "\(txtURLOutlet.stringValue)/JSSResource/"
                serverURL = serverURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource") // Clean up in case of double slash
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

            if authResponse.contains("<activation_code><organization_name>") {
                NSLog("INFO: Successful authentication attempt.")
                self.verified = true
                // Store username if button pressed
                if self.chkRememberMe.state.rawValue == 1 {
                    self.loginDefaults.set(self.txtUserOutlet.stringValue, forKey: "UserName")
                    self.loginDefaults.set(self.txtURLOutlet.stringValue, forKey: "InstanceURL")
                    self.loginDefaults.set(true, forKey: "Remember")
                    self.loginDefaults.synchronize()

                } else {
                    self.loginDefaults.removeObject(forKey: "UserName")
                    self.loginDefaults.removeObject(forKey: "InstanceURL")
                    self.loginDefaults.set(false, forKey: "Remember")
                    self.loginDefaults.synchronize()
                }
                self.spinProgress.stopAnimation(self)
                self.btnSubmitOutlet.isHidden = false

                if self.delegateAuth != nil {
                    self.delegateAuth?.userDidAuthenticate(base64Credentials: self.base64Credentials!, url: self.serverURL!)
                    self.dismiss(self)
                }
            } else {
                DispatchQueue.main.async {
                    self.spinProgress.stopAnimation(self)
                    self.btnSubmitOutlet.isHidden = false
                    _ = popPrompt().generalWarning(question: "Invalid Credentials", text: "The credentials you entered do not seem to have sufficient permissions. This could be due to an incorrect user/password, or possibly from insufficient permissions. Stupid Groups tests this against the user's ability to view the Activation Code via the API.")
                    NSLog("INFO: Invalid authentication attempt.")
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
    @IBAction func btnQuit(_ sender: Any) {
        self.dismiss(self)
        NSApplication.shared.terminate(self)
    }
}

