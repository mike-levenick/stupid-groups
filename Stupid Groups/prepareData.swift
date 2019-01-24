//
//  xmlBuilder.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa
import Foundation

public class prepareData {
    // Globally declaring the xml variable to allow the various functions to populate it
    var xml: XMLDocument?

    public func xmlROOT(deviceType: String) -> String {
        var xmlRoot = "none"
        if deviceType == "Mobile Device" {
            xmlRoot = "mobile_device_group"
        } else if deviceType == "Computer" {
            xmlRoot = "computer_group"
        } else {
            xmlRoot = "user_group"
        }
        return xmlRoot
    }
    
    func parseXML(fullXMLString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = fullXMLString.range(of: startTag),
            let end  = fullXMLString.range(of: endTag, range: start.upperBound..<fullXMLString.endIndex) {
            rawValue.append(String(fullXMLString[start.upperBound..<end.lowerBound]))
        } else {
            // DEBUG HERE
            
            //if self.debug { self.writeToLog(stringOfText: "[tagValue2] Start, \(startTag), and end, \(endTag), not found.\n") }
        }
        return rawValue
    }

    // Create the URL for generic updates, such as asset tag and username
    public func createPUTURL(url: String, endpoint: String, idType: String, columnA: String) -> URL {
        let stringURL = "\(url)\(endpoint)/\(idType)/\(columnA)"
        let urlwithPercentEscapes = stringURL.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
        let encodedURL = NSURL(string: urlwithPercentEscapes!)
        //print(urlwithPercentEscapes!) // Uncomment for debugging
        return encodedURL! as URL
    }
    
    // Create the URL that is used to verify the credentials against reading activation code
    public func createAuthURL(url: String) -> URL {
        let stringURL = "\(url)activationcode"
        let encodedURL = NSURL(string: stringURL)
        //print(urlwithPercentEscapes!) // Uncomment for debugging
        return encodedURL! as URL
    }
    
    // Create the URL that is used to gather the information from an existing smart group
    public func createGETURL(url: String, deviceType: String, id: String) -> URL {
        var endpoint = "none"
        if deviceType == "Mobile Device" {
            endpoint = "mobilegroups"
        } else if deviceType == "Computer" {
            endpoint = "computergroups"
        } else {
            endpoint = "usergroups"
        }
        let stringURL = "\(url)\(endpoint)/id/\(id)"
        let encodedURL = NSURL(string: stringURL)
        //print(urlwithPercentEscapes!) // Uncomment for debugging
        return encodedURL! as URL
    }
    
    public func createPOSTURL(url: String) -> URL {
        let stringURL = "\(url)advancedcomputersearches/id/0"
        let encodedURL = NSURL(string: stringURL)
        //print(urlwithPercentEscapes!) // Uncomment for debugging
        return encodedURL! as URL
    }
    
    // MARK: - XML Creation based on dropdowns
    
    public func createXML(popIdentifier: String, popDevice: String, popAttribute: String, eaID: String, columnB: String, columnA: String) -> Data {
        var returnedXML: Data?
        
        // BUILD XML FOR GENERIC USER UPDATES
        if 1==1 && 2==2 {
            let root = XMLElement(name: "user")
            let xml = XMLDocument(rootElement: root)
            let value = XMLElement(name: "name", stringValue: "value")
            root.addChild(value)
            //print(xml.xmlString) // Uncomment for debugging
            returnedXML = xml.xmlData
        }
        
        return returnedXML!
    }
}

