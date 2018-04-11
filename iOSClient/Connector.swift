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

//var userid:Int
//var userRealName:String
var username = "brandon.kong"
var password = "***REMOVED***"

class Connector{
    init() {
        userLogin(username: username, password: password)
    }
    
    public func userLogin(username:String, password:String){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        //Actual login request
        let login = {sessionManager.request(site_url + login_url, method: .post, parameters: ["username": username, "password": password, "anchor": ""]).responseString { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if (response.result.isSuccess){
                print(response.result.value!)
                }
            }
        }
        //Request a smaller page first for faster login time
        sessionManager.request(site_url + homework_url, method: .get).responseString { response in
            login()
        }
    }
    
    public func retrieveHomework(){
        sessionManager.request(site_url + homework_url, method: .get).responseString { response in
            print("Success: \(response.result.isSuccess)")
            print("Response String: \(response.result.value ?? "")")
        }
    }
}
