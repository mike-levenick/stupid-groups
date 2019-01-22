//
//  ViewController.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa
import SwiftyJSON

class ViewController: NSViewController, URLSessionDelegate, DataSentDelegate {
    
    // Declare Variables
    var globalServerURL: String!
    var globalServerCredentials: String!
    var base64Credentials: String!
    var serverURL: String!
    var verified = false
    
    // Set up outlets
    @IBOutlet weak var lblResults: NSTextField!
    @IBOutlet weak var txtGroupID: NSTextField!
    @IBOutlet weak var popConvertTo: NSPopUpButton!
    @IBOutlet weak var popDeviceType: NSPopUpButton!
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueLogin" {
            let loginWindow: loginWindow = segue.destinationController as! loginWindow
            loginWindow.delegateAuth = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        performSegue(withIdentifier: "segueLogin", sender: self)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func btnRun(_ sender: Any) {
        // Determine whether we're converting to static group or advanced search
        if popConvertTo.titleOfSelectedItem == "Static Group" {
            print("Static")
        } else {
            print("Adavnced")
        }

        // Gather data on the smart group to be converted
        DispatchQueue.main.async {
        let myURL = xmlBuilder().createGETURL(url: self.globalServerURL, deviceType: self.popDeviceType.titleOfSelectedItem!, id: self.txtGroupID.stringValue)
            let request = NSMutableURLRequest(url: myURL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(String(describing: self.globalServerCredentials!))", "Content-Type" : "text/xml", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        // GOOD RESPONSE from API
                        print(httpResponse.description)
                        print(String(decoding: data!, as: UTF8.self))
                        
                        do {
                            // Build a variable of the JSON returned
                            let smartGroupJSON = try JSON(data: data!)
                            
                            // Determine whether the returned group is a smart group
                            let isSmart = smartGroupJSON["computer_group"]["is_smart"].boolValue
                            if isSmart {
                                print("YEP")
                            }
                            
                            print(isSmart)
                            print("Smart Group JSON")
                            print("Smart Group JSON")
                            print("Smart Group JSON")
                            
                            // Parse out the criteria
                            print(smartGroupJSON["computer_group"]["criteria"].arrayValue)
                            
                        } catch {
                            // Catching errors in converting the data received from the API to JSON format
                            print("Error Caught Here")
                        }
                        
                        
                    } else {
                        // Bad Response from API
                        print(httpResponse.statusCode)
                        print(httpResponse.description)
                    }
                }
            
                if error != nil {
                    _ = popPrompt().generalWarning(question: "Fatal Error", text: "The MUT received a fatal error at authentication. The most common cause of this is an incorrect server URL. The full error output is below. \n\n \(error!.localizedDescription)")
                }
            })
            task.resume() // Kick off the actual GET here
        }
        
    }

    func userDidAuthenticate(base64Credentials: String, url: String) {
        //print(base64Credentials)
        self.globalServerCredentials = base64Credentials
        //print(url)
        self.globalServerURL = url
        verified = true
        print(globalServerURL!)
        print(globalServerCredentials!)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

