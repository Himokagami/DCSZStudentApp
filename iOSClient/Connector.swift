//
//  Connector.swift
//  iOSClient
//
//  Created by Brandon Kong on 4/5/18.
//  Copyright © 2018 Himokagami. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftSoup

let site_url = "http://dcszonline.dulwich-suzhou.cn/"
let login_url = "login/index.php"
let homework_url = "blocks/homework/view.php?course=1"
let homeworkdata_url = "blocks/homework/ajax/view_timetable.php"
let activity_url = "blocks/homework/assignment.php"

let sessionManager = Alamofire.SessionManager.default

class Connector{
    init() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        sessionManager.request(site_url + login_url, method: .post, parameters: ["username": "brandon.kong", "password": "***REMOVED***", "anchor": ""]).responseString { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            print("Success: \(response.result.isSuccess)")
            print("Response String: \(response.result.value ?? "")")
            self.retrieveHomework()
        }
    }
    
    public func retrieveHomework(){
        sessionManager.request(site_url + homework_url, method: .get).responseString { response in
            print("Success: \(response.result.isSuccess)")
            print("Response String: \(response.result.value ?? "")")
        }
    }
}
