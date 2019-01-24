//
//  apiFunctions.swift
//  Stupid Groups
//
//  Created by Michael Levenick on 1/24/19.
//  Copyright © 2019 Michael Levenick. All rights reserved.
//

import Foundation

public class API {
    
    public func get(getCredentials: String, getURL: URL) -> String {
        var stringToReturn = "nil"
        let semaphore = DispatchSemaphore(value: 0)
        print("start get function")
        let request = NSMutableURLRequest(url: getURL)
        request.httpMethod = "GET"
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(getCredentials)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
        let session = Foundation.URLSession(configuration: configuration)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                    // GOOD RESPONSE from API
                    print(httpResponse.statusCode)
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                } else {
                    // Bad Response from API
                    print(httpResponse.statusCode)
                    print(httpResponse.description)
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                }
                semaphore.signal()
            }
            
            if error != nil {
                _ = popPrompt().generalWarning(question: "Fatal Error", text: "Stupid Groups received a fatal error at authentication. The most common cause of this is an incorrect server URL. The full error output is below. \n\n \(error!.localizedDescription)")
            }
        })
        task.resume() // Kick off the actual GET here
        semaphore.wait()
        return stringToReturn
    }
    
    public func post(postCredentials: String, postURL: URL, postBody: Data) -> String {
        var stringToReturn = "nil"
        let semaphore = DispatchSemaphore(value: 0)
        print("start get function")
        let request = NSMutableURLRequest(url: postURL)
        request.httpMethod = "POST"
        request.httpBody = postBody
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(postCredentials)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
        let session = Foundation.URLSession(configuration: configuration)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                    // GOOD RESPONSE from API
                    print(httpResponse.statusCode)
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                } else {
                    // Bad Response from API
                    print(httpResponse.statusCode)
                    print(httpResponse.description)
                    stringToReturn = String(decoding: data!, as: UTF8.self)
                }
                semaphore.signal()
            }
            
            if error != nil {
                _ = popPrompt().generalWarning(question: "Fatal Error", text: "Stupid Groups received a fatal error at authentication. The most common cause of this is an incorrect server URL. The full error output is below. \n\n \(error!.localizedDescription)")
            }
        })
        task.resume() // Kick off the actual GET here
        semaphore.wait()
        return stringToReturn
    }
    
    
    
    
}
