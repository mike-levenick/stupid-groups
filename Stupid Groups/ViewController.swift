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
    @IBOutlet weak var btnPostOutlet: NSButton!
    @IBOutlet weak var btnGetOutlet: NSButton!
    @IBOutlet weak var txtMainWrapper: NSScrollView!
    @IBOutlet var txtMain: NSTextView!

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueLogin" {
            let loginWindow: loginWindow = segue.destinationController as! loginWindow
            loginWindow.delegateAuth = self
        }
    }
    // Declare format for various logging fonts
    let myFontAttribute = [ NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)! ]
    let myHeaderAttribute = [ NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 20.0)! ]
    let myOKFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Courier", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
    ]
    let myFailFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Courier", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    ]
    let myCSVFontAttribute = [ NSAttributedString.Key.font: NSFont(name: "Courier", size: 14.0)! ]
    let myAlertFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        printString(header: true, error: false, green: false, fixedPoint: false, lineBreakAfter: true, message: "Welcome to Stupid Groups v1.0")
        printString(header: false, error: false, green: false, fixedPoint: false, lineBreakAfter: true, message: "\nSometimes your groups get too smart.\n\nStupid Groups is here to help.\n\nConvert groups that rarely change membership to Static Groups, and convert compliance reporting groups that aren't used for scoping to Advanced Searches.\n\nEnter your data above and run a Pre-Flight Check to begin.\n")
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
        clearLog()
        printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Gathering data about \(popDeviceType.titleOfSelectedItem!) group number \(txtGroupID.stringValue)...\n")
        // Prepare a URL to use for the GET call, based on device type and ID
        let getURL = prepareData().createGETURL(url: globalServerURL, deviceType: self.popDeviceType.titleOfSelectedItem!, id: self.txtGroupID.stringValue)
        
        // Pass the URL and credentials into the function to get the response XML back
        let smartGroupXML = API().get(getCredentials: globalServerCredentials, getURL: getURL)

        if smartGroupXML.contains("<name>"){
            let deviceData = prepareData().deviceData(deviceType: self.popDeviceType.titleOfSelectedItem!, conversionType: self.popConvertTo.titleOfSelectedItem!)

            // Parse the response XML to gather data needed for concatenation
            self.smartGroupCriteria = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "criteria>", endTag: "</criteria")
            self.smartGroupName = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "name>", endTag: "</name")
            self.newName = "SG Converted - \(String(describing: self.smartGroupName!))"
            self.siteID = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "site>", endTag: "</site")
            self.smartGroupMembership = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "\(deviceData[1])>", endTag: "</\(deviceData[1])")
            printString(header: false, error: false, green: true, fixedPoint: false, lineBreakAfter: false, message: "Group Found. ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Group name appears to be:\n\"\(self.smartGroupName!)\"\n\nand will be converted to\n\"\(self.newName!)\".\n\nPress the Convert button to continue.")
            readyToRun()
        } else {
            printString(header: false, error: true, green: false, fixedPoint: false, lineBreakAfter: false, message: "It seems an error has occured. ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "The data gathered by Stupid Groups does not appear to match any existing group. Please try again.")
        }

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

    func readyToRun() {
        btnPostOutlet.isHidden = false
        btnGetOutlet.isHidden = true
    }

    func notReadyToRun() {
        btnGetOutlet.isHidden = false
        btnPostOutlet.isHidden = true
    }

    func resetView() {
        print("VIEW RESET")
        btnPostOutlet.isEnabled = false
        btnPostOutlet.isTransparent = true
        btnGetOutlet.isTransparent = false
        btnGetOutlet.isEnabled = true

    }
    
    func beginRunView() {
        print("SET RUN VIEW")
    }

    // Prints fixed point text with no line break after
    func printString(header: Bool, error: Bool, green: Bool, fixedPoint: Bool, lineBreakAfter: Bool, message: String) {
        var stringToPrint = ""
        if lineBreakAfter {
            stringToPrint = message + "\n"
        } else {
            stringToPrint = message
        }
        if header {
            self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myHeaderAttribute))
        } else if error {
            self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myFailFontAttribute))
        } else if green {
            self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myOKFontAttribute))
        } else if fixedPoint {
            self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myCSVFontAttribute))
        } else {
            self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myFontAttribute))
        }
        self.txtMain.scrollToEndOfDocument(self)
    }
    // Clears the entire logging text field
    func clearLog() {
        self.txtMain.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: self.myFontAttribute))
    }
}
