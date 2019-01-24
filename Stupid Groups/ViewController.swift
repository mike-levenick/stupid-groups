//
//  ViewController.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, URLSessionDelegate, DataSentDelegate {
    
    // Declare Variables
    var globalServerURL: String!
    var globalServerCredentials: String!
    var base64Credentials: String!
    var serverURL: String!
    var verified = false
    var globalHTTPFunction: String!
    var myURL: URL!
    var globalDebug = "off"
    var smartGroupCriteria: String!
    var smartGroupName: String!
    var newName: String!
    var siteID: String!
    var smartGroupMembership: String!
    
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
        // Gather data on the smart group to be converted
        DispatchQueue.main.async {
            let myURL = prepareData().createGETURL(url: self.globalServerURL, deviceType: self.popDeviceType.titleOfSelectedItem!, id: self.txtGroupID.stringValue)
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
                        let smartGroupXML = String(decoding: data!, as: UTF8.self)
                        print(smartGroupXML)
                        self.smartGroupCriteria = xmlParse().getValueBetween(xmlString: smartGroupXML, startTag: "criteria>", endTag: "</criteria")
                        self.smartGroupName = xmlParse().getValueBetween(xmlString: smartGroupXML, startTag: "name>", endTag: "</name")
                        self.newName = "SG Converted - \(String(describing: self.smartGroupName))"
                        self.siteID = xmlParse().getValueBetween(xmlString: smartGroupXML, startTag: "site>", endTag: "</site")
                        self.smartGroupMembership = xmlParse().getValueBetween(xmlString: smartGroupXML, startTag: "computers>", endTag: "</computers")
                    } else {
                        // Bad Response from API
                        print(httpResponse.statusCode)
                        print(httpResponse.description)
                    }
                }

                if error != nil {
                    _ = popPrompt().generalWarning(question: "Fatal Error", text: "Stupid Groups received a fatal error at authentication. The most common cause of this is an incorrect server URL. The full error output is below. \n\n \(error!.localizedDescription)")
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

            self.myURL = prepareData().createPOSTURL(url: self.globalServerURL!)

            let request = NSMutableURLRequest(url: self.myURL)
            request.httpMethod = "POST"

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
