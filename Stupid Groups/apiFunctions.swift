//
//  apiFunctions.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/24/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Foundation

public class API {

    // This function can be used for any GET. Pass in a URL and base64 encoded credentials.
    // The credentials are inserted into the header.
    public func get(getCredentials: String, getURL: URL) -> String {

        // Declare a variable to be populated, and set up the HTTP Request with headers
        var stringToReturn = "nil"
        let semaphore = DispatchSemaphore(value: 0)
        let request = NSMutableURLRequest(url: getURL)
        request.httpMethod = "GET"
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(getCredentials)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
        let session = Foundation.URLSession(configuration: configuration)

        // Completion handler. This is what ensures that the response is good/bad
        // and also what handles the semaphore
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                    // Good response from API
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                    NSLog("[INFO  ]: Successful GET completed by StupidGroups.app")
                    NSLog(response?.description ?? "nil")
                } else {
                    // Bad Response from API
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                    NSLog("[ERROR ]: Failed GET completed by StupidGroups.app")
                    NSLog(response?.description ?? "nil")
                }
                semaphore.signal() // Signal completion to the semaphore
            }
            
            if error != nil {
                NSLog("[FATAL ]: " + error!.localizedDescription)
                stringToReturn = String("[FATAL ]: " + error!.localizedDescription)
                semaphore.signal()
            }
        })
        task.resume() // Kick off the actual GET here
        semaphore.wait() // Wait for the semaphore before moving on to the return value
        return stringToReturn
    }

    // This function can be used for any POST. Pass in a URL and base64 encoded credentials.
    // The credentials are inserted into the header.
    public func post(postCredentials: String, postURL: URL, postBody: Data) -> String {

        // Declare a variable to be populated, and set up the HTTP Request with headers
        var stringToReturn = "nil"
        let semaphore = DispatchSemaphore(value: 0)
        let request = NSMutableURLRequest(url: postURL)
        request.httpMethod = "POST"
        request.httpBody = postBody
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(postCredentials)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
        let session = Foundation.URLSession(configuration: configuration)

        // Completion handler. This is what ensures that the response is good/bad
        // and also what handles the semaphore
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                    // Good Response from API
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                    NSLog("[INFO  ]: Successful POST completed by StupidGroups.app")
                    NSLog(response?.description ?? "nil")
                } else {
                    // Bad Response from API
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                    NSLog("[ERROR ]: Failed POST completed by StupidGroups.app")
                    NSLog(response?.description ?? "nil")
                }
                semaphore.signal()
            }
            
            if error != nil {
                NSLog("[FATAL ]: StupidGroups.app has encountered a fatal error.")
                NSLog(error!.localizedDescription)
            }
        })
        task.resume() // Kick off the actual GET here
        semaphore.wait()
        return stringToReturn
    }
    
    
    
    
}
