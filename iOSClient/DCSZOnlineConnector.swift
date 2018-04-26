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
                                print("login successful")
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
                    var homeworkcache:Array<Any> = []
                    let doc: Document = try SwiftSoup.parse(response.result.value!)
                    
                    let rawHomework: Array = try doc.select("table").first()!.select("tbody").first()!.select("tr").array()
                    for homework in rawHomework.enumerated(){
                        // let index = homework.offset
                        let value = homework.element
                        
                        let rawHomeworkData: Array = try value.select("td").array()
                        
                        if (rawHomeworkData.count == 0){ break }
                        
                        
                        // Data analysis
                        let course: String = try rawHomeworkData[0].text()
                        let courseid: String = try rawHomeworkData[2].select("a").first()!.attr("href").components(separatedBy: "?")[1].components(separatedBy: "&")[0].components(separatedBy: "=")[1]
                        let subject: String = try rawHomeworkData[1].text()
                        let activity: String = try rawHomeworkData[2].select("a").first()!.text()//removes the space at the front of each title
                        //activity.remove(at: activity.startIndex)
                        let activityid: String = try rawHomeworkData[2].select("a").first()!.attr("href").components(separatedBy: "?")[1].components(separatedBy: "&")[1].components(separatedBy: "=")[1].components(separatedBy: "\\")[0]
                        let set_by: String = try rawHomeworkData[3].text()
                        let status: String = try rawHomeworkData[4].text()
                        let grade: String = try rawHomeworkData[5].text()
                        let feedback: String = try rawHomeworkData[6].text()
                        let duedate: Array = try rawHomeworkData[7].text().components(separatedBy: "\n")[0].components(separatedBy: " ")
                        let duedate_day: String = duedate[0]
                        let duedate_month: String = duedate[1] // TODO: add months string to int converter
                        let duedate_year: String = duedate[2]
                        
                        var homeworkPayload = [course.replacingOccurrences(of: "<\\/td>", with: ""),
                                               courseid,
                                               subject.replacingOccurrences(of: "<\\/td>", with: ""),
                                               activity.replacingOccurrences(of: "<\\/a><\\/td>", with: ""),
                                               activityid,
                                               set_by.replacingOccurrences(of: "<\\/td>", with: ""),
                                               status.replacingOccurrences(of: "<\\/td>", with: ""),
                                               grade.replacingOccurrences(of: "<\\/td>", with: ""),
                                               feedback.replacingOccurrences(of: "<\\/td>", with: ""),
                                               duedate_day,
                                               duedate_month,
                                               duedate_year.replacingOccurrences(of: "<\\/td><\\/tr>\\n", with: "").replacingOccurrences(of: "<\\/tbody>\\n<\\/table><\\/div>\",\"htmltimetable\":\"", with: "")
                        ]
                        for hw in homeworkPayload.enumerated(){
                            let hwIndex = hw.offset
                            if (hwIndex != 1 && hwIndex != 4){
                                homeworkPayload[hwIndex] = homeworkPayload[hwIndex].replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/")
                            }
                        }
                        
                        homeworkcache.append(homeworkPayload)
                    }
                    print(homeworkcache)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshHomeworkList"), object: self)
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
