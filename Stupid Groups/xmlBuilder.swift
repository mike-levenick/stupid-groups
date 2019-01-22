//
//  xmlBuilder.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa
import Foundation

public class xmlBuilder {
    // Globally declaring the xml variable to allow the various functions to populate it
    var xml: XMLDocument?
    
    // MARK: - URL Creation based on dropdowns
    
    /* ===
     These various functions are called when the HTTP Requests are made, based on the dropdown values selected
     I used to have these all in one big function and split them out through if/then statements here, but
     it became rather difficult to add new functionality such as the static group population.
     === */
    
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
    
    // MARK: - XML Creation based on dropdowns
    
    /* ===
     This section will first use an anonymous hash/tuple to "translate" the human readable dropdowns into
     a more computer readable format.
     
     The values here typically directly translate into what the XML expects to see on a PUT or POST
     however some are simply identifiable placeholders. The logic statements below help to determine which XML format
     should be built and used for the upload, depending on what is being done. The various methods of building the xml
     are mostly due to how different various JSS API endpoints behave, and how the xml format differs between them.
     For example, sites are under the general subset, in a site sub-subset for ios and mac, but simply in the sites subset for users
     === */
    
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

