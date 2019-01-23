//
//  popPrompt.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/21/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Cocoa
import Foundation

public class popPrompt {
    
    var globalCSVString: String!
    
    
    // Generate a generic warning message for invalid credentials etc
    public func generalWarning(question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlert.Style.warning
        myPopup.addButton(withTitle: "OK")
        return myPopup.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    // Generate a specific prompt to ask for credentials
    public func selectDelim (question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlert.Style.warning
        myPopup.addButton(withTitle: "Use Comma")
        myPopup.addButton(withTitle: "Use Semi-Colon")
        return myPopup.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    // Generate a specific prompt to ask for concurrent runs
    public func selectConcurrent (question: String, text: String) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = NSAlert.Style.warning
        myPopup.addButton(withTitle: "2 at a time")
        myPopup.addButton(withTitle: "1 at a time")
        return myPopup.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn
    }
    
}
