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
    // Many of these are declared globally so they can be easily passed from function to function
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
    @IBOutlet weak var txtPrefix: NSTextField!


    // Declare outlets for use in the view
    @IBOutlet weak var txtGroupID: NSTextField!
    @IBOutlet weak var popConvertTo: NSPopUpButton!
    @IBOutlet weak var popDeviceType: NSPopUpButton!
    @IBOutlet weak var btnPostOutlet: NSButton!
    @IBOutlet weak var btnGetOutlet: NSButton!
    @IBOutlet weak var txtMainWrapper: NSScrollView!
    @IBOutlet var txtMain: NSTextView!

    // Prepare the segue for the sheet view of the login window to appear
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueLogin" {
            let loginWindow: loginWindow = segue.destinationController as! loginWindow
            loginWindow.delegateAuth = self
        }
    }

    // Print some welcome messaging upon loading the view
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 383, height: 420) // Limits resizing of the window
        printString(header: true, error: false, green: false, fixedPoint: false, lineBreakAfter: true, message: "Welcome to Stupid Groups v1.0")
        printString(header: false, error: false, green: false, fixedPoint: false, lineBreakAfter: true, message: "\nSometimes your groups get too smart.\n\nStupid Groups is here to help.\n\nConvert groups that rarely change membership to Static Groups, and convert compliance reporting groups that aren't used for scoping to Advanced Searches.\n\nEnter your data above and run a Pre-Flight Check to begin.\n")
    }

    // Trigger the actual sheet segue upon the view fully appearing
    // It seems to work better here than in viewDidLoad().
    override func viewWillAppear() {
        super.viewWillAppear()
        performSegue(withIdentifier: "segueLogin", sender: self)
    }

    // I'm relatively certain this is not needed, but I will leave it in and commented for now.
    /*
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
     */

    // This is the "Pre-Flight Check" button.
    @IBAction func btnGET(_ sender: Any) {
        // Clear the box on the main view controller, and then print some information.
        clearLog()
        printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Gathering data about \(popDeviceType.titleOfSelectedItem!) group number \(txtGroupID.stringValue)...\n")
        NSLog("[INFO  ]: Starting GET function.")
        // Prepare a URL to use for the GET call, based on device type and ID
        let getURL = prepareData().createGETURL(url: globalServerURL, deviceType: self.popDeviceType.titleOfSelectedItem!, id: self.txtGroupID.stringValue)
        
        // Pass the URL and credentials into the function to get the response XML back
        let smartGroupXML = API().get(getCredentials: globalServerCredentials, getURL: getURL)

        // I opted to parse the returned data, and look for a <name> tag instead of using the
        // response code, as I have noticed the response code is not always reliable when
        // working with MUT.
        if smartGroupXML.contains("<name>"){
            let deviceData = prepareData().deviceData(deviceType: self.popDeviceType.titleOfSelectedItem!, conversionType: self.popConvertTo.titleOfSelectedItem!)

            // Parse the response XML to gather data needed for concatenation
            self.smartGroupCriteria = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "criteria>", endTag: "</criteria")
            self.smartGroupName = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "name>", endTag: "</name")
            self.newName = "\(txtPrefix.stringValue) \(String(describing: self.smartGroupName!))".replacingOccurrences(of: "  ", with: " ")
            self.siteID = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "site>", endTag: "</site")
            self.smartGroupMembership = prepareData().parseXML(fullXMLString: smartGroupXML, startTag: "\(deviceData[1])>", endTag: "</\(deviceData[1])")
            printString(header: false, error: false, green: true, fixedPoint: false, lineBreakAfter: false, message: "Group Found. ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Group name appears to be:\n\"\(self.smartGroupName!)\"\n\nand will be converted to\n\"\(self.newName!)\".\n\nPress the Convert button to continue.")
            readyToRun()
        } else {
            printString(header: false, error: true, green: false, fixedPoint: false, lineBreakAfter: false, message: "It seems an error has occured. ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "The data gathered by Stupid Groups does not appear to match any existing group. Please try again.")
        }
        NSLog("[INFO  ]: GET function returned: " + smartGroupXML)
    }
    
    @IBAction func btnPOST(_ sender: Any) {
        clearLog()
        printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Submitting data to create new \(popConvertTo.titleOfSelectedItem!) named \(newName ?? "nil")...\n")
        notReadyToRun()
        NSLog("[INFO  ]: Starting POST function.")
        let deviceData = prepareData().deviceData(deviceType: self.popDeviceType.titleOfSelectedItem!, conversionType: self.popConvertTo.titleOfSelectedItem!)
        
        let xmlToPost = prepareData().xmlToPost(newName: newName, siteID: siteID, criteria: smartGroupCriteria, membership: smartGroupMembership, conversionType: popConvertTo.titleOfSelectedItem!, deviceRoot: deviceData[0], devicePlural: deviceData[1], deviceSingular: deviceData[2])
        let postURL = prepareData().createPOSTURL(url: globalServerURL, endpoint: deviceData[3] )
        let postResponse = API().post(postCredentials: globalServerCredentials, postURL: postURL, postBody: xmlToPost)

        if postResponse.contains("<id>"){
            DispatchQueue.main.async {
                self.clearLog()
            let newID = prepareData().parseXML(fullXMLString: postResponse, startTag: "id>", endTag: "</id")
            self.printString(header: false, error: false, green: true, fixedPoint: false, lineBreakAfter: false, message: "Success! ")
            self.printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "Your group was converted to \(self.popConvertTo.titleOfSelectedItem!), with a name of \(self.newName ?? "nil") and an ID of \(newID).")
            }
        } else if postResponse.contains("Error: Duplicate name"){
            clearLog()
            printString(header: false, error: true, green: false, fixedPoint: false, lineBreakAfter: false, message: "ERROR: Duplicate. ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "It appears that a \(popConvertTo.titleOfSelectedItem!) with a name of \"\(newName ?? "nil")\" already exists.\n\nIf you have a clustered environment, or JamfCloud, it may take a few minutes for the group to appear in your web GUI after conversion.\n\nIf you would like to replace the old \(popConvertTo.titleOfSelectedItem!), please manually delete it and try again.")
        } else {
            clearLog()
            printString(header: false, error: true, green: false, fixedPoint: false, lineBreakAfter: false, message: "ERROR: ")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: "An unspecified error has occured. Full API response below:\n\n")
            printString(header: false, error: false, green: false, fixedPoint: true, lineBreakAfter: true, message: postResponse)
        }
        NSLog("[INFO  ]: POST function returned: " + postResponse)
    }

    // This function is required to allow the login window to pass
    // the URL and base64 encoded credentials forward to the main view controller.
    func userDidAuthenticate(base64Credentials: String, url: String) {
        self.globalServerCredentials = base64Credentials
        self.globalServerURL = url
        verified = true
    }

    // This function is required to allow the app to communicate with
    // servers who are using non-trusted SSL certificates (built-in/self-signed)
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

    // Set the view to "ready to run" state
    func readyToRun() {
        btnPostOutlet.isHidden = false
        btnGetOutlet.isHidden = true
    }

    // Set the view to require another Pre-Flight Check
    func notReadyToRun() {
        btnGetOutlet.isHidden = false
        btnPostOutlet.isHidden = true
    }

    // This function will append text to the primary log block on the
    // main view controller. You can call this function to append or print
    // text to the log box, and select various formats depending on your use.
    // The bool selectors all overrule each other from left to right
    // for example, if you select TRUE for header, it will ignore "error" "green" and "fixed point"
    // Additional line breaks can be added by including \n in the message string

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

    // Declare format for various output fonts for the end user to see.
    // These are the font formats called by the printString function.
    let myFontAttribute = [ NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)! ]
    let myHeaderAttribute = [ NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 20.0)! ]
    let myOKFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
    ]
    let myFailFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    ]
    let myCSVFontAttribute = [ NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)! ]
    let myAlertFontAttribute = [
        NSAttributedString.Key.font: NSFont(name: "Helvetica Neue Thin", size: 14.0)!,
        NSAttributedString.Key.foregroundColor: NSColor(deviceRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    ]

    // These actions are to reset the pre-flight button with the notreadytorun() function
    // If something changes such as group ID or group type/target type
    @IBAction func popGroupType(_ sender: Any) {
        notReadyToRun()
    }
    @IBAction func popConvertTo(_ sender: Any) {
        notReadyToRun()
    }
    @IBAction func txtIDAction(_ sender: Any) {
        notReadyToRun()
    }
    @IBAction func txtPrefixAction(_ sender: Any) {
        notReadyToRun()
    }

}
