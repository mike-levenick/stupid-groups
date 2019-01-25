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

    // Returns an array
    public func deviceData(deviceType: String, conversionType: String) -> Array<String> {
        var xmlData = ["nil","nil","nil"]
        
        // Mobile Device
        if deviceType == "Mobile Device" {
            if conversionType == "Advanced Search" {
                xmlData = ["advanced_mobile_device_search","mobile_devices","mobile_device","advancedmobiledevicesearches"]
            }
            if conversionType == "Static Group" {
                xmlData = ["mobile_device_group","mobile_devices","mobile_device","mobiledevicegroups"]
            }
            
        // Computers
        } else if deviceType == "Computer" {
            if conversionType == "Advanced Search" {
                xmlData = ["advanced_computer_search","computers","computer","advancedcomputersearches"]
            }
            if conversionType == "Static Group" {
                xmlData = ["computer_group","computers","computer","computergroups"]
            }
        // Users
        } else {
            if conversionType == "Advanced Search" {
                xmlData = ["advanced_user_search","users","user","advancedusersearches"]
            }
            if conversionType == "Static Group" {
                xmlData = ["user_group","users","user","usergroups"]
            }
        }
        return xmlData
    }
    
    public func xmlToPost(newName: String, siteID: String, criteria: String, membership: String, conversionType: String, deviceRoot: String, devicePlural: String, deviceSingular: String) -> Data {
        
        var newXMLString = "nil"
        var displayFields = "nil"
        
        if devicePlural == "users" {
            displayFields = """
            <size>7</size>
            <display_field>
            <name>Computers</name>
            </display_field>
            <display_field>
            <name>Email Address</name>
            </display_field>
            <display_field>
            <name>Full Name</name>
            </display_field>
            <display_field>
            <name>Mobile Devices</name>
            </display_field>
            <display_field>
            <name>Phone Number</name>
            </display_field>
            <display_field>
            <name>Position</name>
            </display_field>
            <display_field>
            <name>Username</name>
            </display_field>
            """
        }
        
        if devicePlural == "mobile_devices" {
            displayFields = """
            <size>5</size>
            <display_field>
            <name>Asset Tag</name>
            </display_field>
            <display_field>
            <name>Device ID</name>
            </display_field>
            <display_field>
            <name>Display Name</name>
            </display_field>
            <display_field>
            <name>Serial Number</name>
            </display_field>
            <display_field>
            <name>Username</name>
            </display_field>
            """
        }
        
        if devicePlural == "computers" {
            displayFields = """
            <size>5</size>
            <display_field>
            <name>Asset Tag</name>
            </display_field>
            <display_field>
            <name>Computer Name</name>
            </display_field>
            <display_field>
            <name>JSS Computer ID</name>
            </display_field>
            <display_field>
            <name>Serial Number</name>
            </display_field>
            <display_field>
            <name>Username</name>
            </display_field>
            """
        }
        
        // Build XML for an Advanced Search conversion
        if conversionType == "Advanced Search" {
            newXMLString = """
            <\(deviceRoot)>
                <name>\(newName)</name>
                <site>\(siteID)</site>
                <criteria>\(criteria)</criteria>
                <display_fields>\(displayFields)</display_fields>
            </\(deviceRoot)>
            """
            //print(newXMLString) // Uncomment for debugging
        }

        // Build XML for a Static Group conversion
        if conversionType == "Static Group" {
            newXMLString = """
            <\(deviceRoot)>
                <name>\(newName)</name>
                <site>\(siteID)</site>
                <is_smart>false</is_smart>
                <\(devicePlural)>\(membership)</\(devicePlural)>
            </\(deviceRoot)>
            """
            //print(newXMLString) // Uncomment for debugging
        }
        
        let myData: Data? = newXMLString.data(using: .utf8) // non-nil
        return myData!
    }
    
    func parseXML(fullXMLString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = fullXMLString.range(of: startTag),
            let end  = fullXMLString.range(of: endTag, range: start.upperBound..<fullXMLString.endIndex) {
            rawValue.append(String(fullXMLString[start.upperBound..<end.lowerBound]))
        } else {
            // DEBUG HERE
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
            endpoint = "mobiledevicegroups"
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
    
    public func createPOSTURL(url: String, endpoint: String) -> URL {
        let stringURL = "\(url)\(endpoint)/id/0"
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

