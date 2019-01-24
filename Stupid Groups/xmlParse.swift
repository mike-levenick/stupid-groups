//
//  xmlParse.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/23/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Foundation

public class xmlParse {

    // extract the value between (different) tags - start
    func getValueBetween(xmlString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = xmlString.range(of: startTag),
            let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
            rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
        } else {
            // DEBUG HERE
            
            //if self.debug { self.writeToLog(stringOfText: "[tagValue2] Start, \(startTag), and end, \(endTag), not found.\n") }
        }
        return rawValue
    }
    //  extract the value between (different) tags - end

}
