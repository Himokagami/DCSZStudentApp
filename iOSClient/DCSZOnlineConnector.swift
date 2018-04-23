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
import NotificationCenter

let site_url = "https://dcszonline.dulwich-suzhou.cn/"
let login_url = "login/index.php"
let homework_url = "blocks/homework/view.php?course=1"
let homeworkdata_url = "blocks/homework/ajax/view_timetable.php"
let activity_url = "blocks/homework/assignment.php"

let session = Alamofire.SessionManager.default

private var username = ""
private var password = ""

private var userid = 0
private var userRealName = ""
private var sessionkey = ""

public var homeworkList: NSArray = []

class DCSZOnlineConnector{
    
    public func setUsername(name: String){
        username = name
    }
    
    public func setPassword(pwd: String){
        password = pwd
    }
    
    public func getUsername() -> String{
        return username
    }
    
    public func getPassword() -> String{
        return username
    }
    
    public func login(){ //TODO: add wrong password and no internet detection
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        //Request a smaller page for faster login time
        session.request(site_url + homework_url, method: .get).responseString { response in
            if (response.result.isSuccess){
                let loginPacket = ["username": username, "password": password, "anchor": ""]
                session.request(site_url + login_url, method: .post, parameters: loginPacket).responseString { response in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if (response.result.isSuccess){
                        //print(response.result.value!)
                        
                        do{
                            let doc: Document = try SwiftSoup.parse(response.result.value!)
                            
                            // Gets the session key from the javascript string
                            let head: Elements = try doc.select("head")
                            let script = try head.select("script").toString()
                            sessionkey = script.components(separatedBy: "\"sesskey\":\"")[1].components(separatedBy: "\"")[0]
                            
                            let body:Elements = try doc.select("body")
                            let data = try body.toString()
                            userid = Int(data.components(separatedBy: "<input id=\"user\" name=\"user\" type=\"hidden\" value=\"")[1].components(separatedBy: "\"")[0])!//TODO: Better algorithm
                            
                            if (sessionkey != "" && userid != 0){
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: self)
                                self.refreshHomeworkList()
                            }
                            
                        } catch Exception.Error(let type, let message) {
                            print(message)
                        } catch {
                            print("error")
                        }
                    }
                }
            }else{
                //No internet connection
                NotificationCenter.default.post(name: Notification.Name(rawValue: "offline"), object: self)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    public func refreshHomeworkList(){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let homeworkPacket = ["course": 1, "sesskey": sessionkey, "displayuser": userid, "user": userid, "usertype": "learner", "marking": 0] as [String : Any]
        session.request(site_url + homeworkdata_url, method: .post, parameters: homeworkPacket).responseString { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            if (response.result.isSuccess){
                do{
                    let doc: Document = try SwiftSoup.parse(response.result.value!)
                    
                } catch Exception.Error(let type, let message) {
                    print(message)
                } catch {
                    print("error")
                }
                
                
            }else{
                NotificationCenter.default.post(name: Notification.Name(rawValue: "offline"), object: self)
            }
            
        }
    }
    
    public func getCurrentSessionKey() -> String{
        return ""
    }
    
    public func getHomeworkDescription(courseid: Int, activityid: Int){
        
    }
    
    public func updateHomeworkStatus(courseid: Int, activityid: Int){
        
    }
    
    
    
    
}
