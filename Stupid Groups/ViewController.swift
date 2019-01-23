//
//  ViewController.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa
import SwiftyJSON
import SwiftyXMLParser

class ViewController: NSViewController, URLSessionDelegate, DataSentDelegate {
    
    // Declare Variables
    var globalServerURL: String!
    var globalServerCredentials: String!
    var globalJSONtoPOST: JSON!
    var base64Credentials: String!
    var serverURL: String!
    var verified = false
    var globalHTTPFunction: String!
    var myURL: URL!
    var globalDebug = "off"
    
    // Set up operation queue for runs
    let myOpQueue = OperationQueue()
    
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

    @IBAction func btnGET(_ sender: Any) {
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
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(String(describing: self.globalServerCredentials!))", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        // GOOD RESPONSE from API
                        //print(httpResponse.description)
                        //print(String(decoding: data!, as: UTF8.self))
                        /*
                        do {
                            // Build a variable of the JSON returned
                            let smartGroupJSON = try JSON(data: data!)
                            print(smartGroupJSON)
                            
                            // Determine whether the returned group is a smart group
                            let isSmart = smartGroupJSON["computer_group"]["is_smart"].boolValue
                            let criteria = smartGroupJSON["computer_group"]["criteria"].arrayValue
                            let membership = smartGroupJSON["computer_group"]["computers"].arrayValue
                            let siteID = smartGroupJSON["computer_group"]["site"]["id"].intValue
                            let smartName = smartGroupJSON["computer_group"]["name"].stringValue
                            let newName = "SG - \(smartName)"
                            print("Is smart \(isSmart)")
                            print("Criteria \(criteria)")
                            print("Membership \(membership)")
                            print("Site ID \(siteID)")
                            print("Name \(smartName)")
                            
                            //var advancedJSON: JSON =  ["advanced_computer_search": ["name": newName,  "criteria": criteria, "site": ["id": siteID], "display_fields": ["name": "Asset Tag","name": "Computer Name","name": "JSS Computer ID","name": "Serial Number","name": "Username"]]]
                            let advancedJSON: JSON =  ["advanced_computer_search": ["name": newName,  "criteria": criteria,"view_as" : "Standard Web Page", "site": ["id": siteID], "display_fields": [["name":"Asset Tag"],["name":"Computer Name"],["name":"JSS Computer ID"],["name":"Serial Number"],["name":"Username"]]]]
                            
                            self.globalJSONtoPOST = advancedJSON
                            print("TO UPLOAD")
                            print (self.globalJSONtoPOST)
                            
                        } catch {
                            // Catching errors in converting the data received from the API to JSON format
                            print("Error Caught Here")
                        }*/
                    
                    
                        // Build a variable of the XML returned
                        let smartGroupXML = XML.parse(data!)
                        
                        // Determine whether the returned group is a smart group
                        let isSmart = smartGroupXML.computer_group.is_smart.text
                        print("Is smart \(String(describing: isSmart!))")
                        
                        let oldName = smartGroupXML["computer_group"]["name"].text
                        print("Old Name is \(String(describing: oldName!))")
                        let newName = "SG - \(String(describing: oldName!))"
                        print("New Name is \(newName)")
                        
                        let criteria = smartGroupXML["computer_group"]["criteria"]
                        print(criteria)
                        
                        
                        
                        
                        //print("Is smart \(isSmart)")
                        //print("Criteria \(criteria)")
                        //print("Membership \(membership)")
                        //print("Site ID \(siteID)")
                        //print("Name \(name)")
                        
                        
                        
                        
                        
                        
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
    
    @IBAction func btnPOST(_ sender: Any) {
        

            
            // Async update the UI for the start of the run
            DispatchQueue.main.async {
                self.beginRunView()
            }
            
            // Set the max concurrent ops to the selectable number
            myOpQueue.maxConcurrentOperationCount = 1
            
            // Semaphore causes the op queue to wait for responses before sending a new request
            let semaphore = DispatchSemaphore(value: 0)

                // Add a PUT or POST request to the operation queue
                myOpQueue.addOperation {
                    
                    self.myURL = xmlBuilder().createPOSTURL(url: self.globalServerURL!)
                    
                    let request = NSMutableURLRequest(url: self.myURL)
                    request.httpMethod = "POST"
                    do {
                        request.httpBody = try self.globalJSONtoPOST!.rawData()
                    } catch {
                        //errors caught here
                    }
                    
                    let configuration = URLSessionConfiguration.default
                    configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.globalServerCredentials!)", "Content-Type" : "application/json", "Accept" : "application/json"]
                    let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {
                        (data, response, error) -> Void in
                        
                        // If debug mode is enabled, print out the full data from the curl
                        /*if let myData = String(data: data!, encoding: .utf8) {
                            if self.globalDebug == "on" {
                                // DO STUFF HERE IF DEBUG IS ON
                            }
                        }*/
                        
                        // If we got a response
                        if let httpResponse = response as? HTTPURLResponse {
                            
                            // If that response is a success response
                            if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                                DispatchQueue.main.async {
                                    // GOOD RESPONSE GOES HERE
                                    print(httpResponse.statusCode)
                                    
                                }
                            } else {
                                // If that response is not a success response
                                DispatchQueue.main.async {
                                    // BAD RESPONSE GOES HERE
                                    print(httpResponse.statusCode)
                                    print(httpResponse.debugDescription)
                                    if let myData = String(data: data!, encoding: .utf8) {
                                        print(myData)
                                    }
                                    do {
                                        if let postData = try String(data: self.globalJSONtoPOST!.rawData(), encoding: .utf8) {
                                            print(postData)
                                        }
                                    } catch {
                                        
                                    }
                                    
                                }
                                    if httpResponse.statusCode == 409 {
                                    // 409 SPECIFIC STUFF GOES HERE
                                    }
                                    // Update the progress bar
                                }
                            
                            // Signal that the response was received
                            semaphore.signal()
                            DispatchQueue.main.async {
                                // ASYNC UPDATES TO THE GUI GO HERE

                            }
                        }
                        // Log errors if received (we probably shouldn't ever end up needing this)
                        if error != nil {
                            _ = popPrompt().generalWarning(question: "Fatal Error", text: "The MUT received a fatal error while uploading. \n\n \(error!.localizedDescription)")
                        }
                    })
                    // Send the request and then wait for the semaphore signal
                    task.resume()
                    semaphore.wait()
                    
                    // If we're on the last row sent, update the UI to reset for another run
                    DispatchQueue.main.async {
                        self.resetView()
                    }
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
    func resetView() {
        print("VIEW RESET")
    }
    
    func beginRunView() {
        print("SET RUN VIEW")
    }
    @IBAction func codeTest(_ sender: Any) {
    }
    
}

/* LESLIE CODE TO PARSE XML SWITCH TO THIS:
 Usage: stuffBetweenTags = tagValue(fullXML, starttag, endttag)
 
 // extract the value between (different) tags - start
 func tagValue2(xmlString:String, startTag:String, endTag:String) -> String {
 var rawValue = ""
 if let start = xmlString.range(of: startTag),
 let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
 rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
 } else {
 if self.debug { self.writeToLog(stringOfText: "[tagValue2] Start, \(startTag), and end, \(endTag), not found.\n") }
 }
 return rawValue
 }
 //  extract the value between (different) tags - end
 
 */
