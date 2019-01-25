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
    var globalSmartGroupXML: String!
    
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
        // Prepare a URL to use for the GET call, based on device type and ID
        let getURL = prepareData().createGETURL(url: globalServerURL, deviceType: self.popDeviceType.titleOfSelectedItem!, id: self.txtGroupID.stringValue)
        
        // Pass the URL and credentials into the function to get the response XML back
        let smartGroupXML = API().get(getCredentials: globalServerCredentials, getURL: getURL)
        
        let deviceData = prepareData().deviceData(deviceType: self.popDeviceType.titleOfSelectedItem!, conversionType: self.popConvertTo.titleOfSelectedItem!)
        
        // Parse the response XML to gather data needed for concatenation
        self.smartGroupCriteria = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "criteria>", endTag: "</criteria")
        self.smartGroupName = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "name>", endTag: "</name")
        self.newName = "SG Converted - \(String(describing: self.smartGroupName!))"
        self.siteID = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "site>", endTag: "</site")
        self.smartGroupMembership = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "\(deviceData[1])>", endTag: "</\(deviceData[1])")
    }
    
    @IBAction func btnPOST(_ sender: Any) {
        
        let deviceData = prepareData().deviceData(deviceType: self.popDeviceType.titleOfSelectedItem!, conversionType: self.popConvertTo.titleOfSelectedItem!)
        
        let xmlToPost = prepareData().xmlToPost(newName: newName, siteID: siteID, criteria: smartGroupCriteria, membership: smartGroupMembership, conversionType: popConvertTo.titleOfSelectedItem!, deviceRoot: deviceData[0], devicePlural: deviceData[1], deviceSingular: deviceData[2])
        
        let postURL = prepareData().createPOSTURL(url: globalServerURL, endpoint: deviceData[3] )
        let postResponse = API().post(postCredentials: globalServerCredentials, postURL: postURL, postBody: xmlToPost)
        
    }
    

    func userDidAuthenticate(base64Credentials: String, url: String) {
        self.globalServerCredentials = base64Credentials
        self.globalServerURL = url
        verified = true
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
    
}
