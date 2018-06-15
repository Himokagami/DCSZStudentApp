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


let site_url = "https://myschool.dulwich-suzhou.cn/"
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
private var isOnline = false

class DCSZOnlineConnector{
    
    public var homeworkList: Array<Homework> = []
    
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
        if (!isOnline){
            session.request(site_url + homework_url, method: .get).responseString { response in
                if (response.result.isSuccess){
                    let loginPacket = ["username": username, "password": password, "anchor": ""]
                    session.request(site_url + login_url, method: .post, parameters: loginPacket).responseString { response in
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        if (response.result.isSuccess){
                            //print(response.result.value!)
                            
                            do{
                                
                                isOnline = true
                                
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
                }
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
                    var homeworkcache:Array<Homework> = []
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
                        let monthToNumDictionary: [String: String] = ["January": "1",
                                                                      "February": "2",
                                                                      "March": "3",
                                                                      "April": "4",
                                                                      "May": "5",
                                                                      "June": "6",
                                                                      "July": "7",
                                                                      "August": "8",
                                                                      "September": "9",
                                                                      "October": "10",
                                                                      "November": "11",
                                                                      "December": "12"]
                        let duedate_month: String = monthToNumDictionary[duedate[1]]! // TODO: add months string to int converter
                        let duedate_year: String = duedate[2].replacingOccurrences(of: "<\\/td><\\/tr>\\n", with: "").replacingOccurrences(of: "<\\/tbody>\\n<\\/table><\\/div>\",\"htmltimetable\":\"", with: "")
                        let duedate_string: String = duedate_day + "-" + duedate_month + "-" + duedate_year
                        var activityRequireUpload: Bool = false
                        
                        if (status.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/") == "Not submitted"){
                            activityRequireUpload = true
                        }
                        
                        let homeworkPackage: Homework =  Homework(courseName: course.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 courseId: Int(courseid)!,
                                 subjectName: subject.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityName: activity.replacingOccurrences(of: "<\\/a><\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityId: Int(activityid)!,
                                 activityTeacher: set_by.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityStatus: status.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityGrade: grade.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityRequireUpload: activityRequireUpload,
                                 activityFeedback: feedback.replacingOccurrences(of: "<\\/td>", with: "").replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"),
                                 activityDueDate: duedate_string.replacingOccurrences(of: "\'", with: "‘").replacingOccurrences(of: "\\/", with: "/"))
                        homeworkcache.append(homeworkPackage)
                    }
                    // print(homeworkcache)
                    self.homeworkList = self.sortHomeworkListByDate(list: homeworkcache)
                    self.getHomeworkDescription(homeworkIndex: 2)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshHomeworkList"), object: self)
                } catch Exception.Error(let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }else{
                NotificationCenter.default.post(name: Notification.Name(rawValue: "offline"), object: self)
            }
            
        }
    }
    
    public func checkIsOnline(){
        
    }
    
    public func getConnectionStatus() -> Bool{
        return isOnline
    }
    
    public func markHomeworkAsDone(homeworkIndex: Int){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let markPayload = ["action": "markdone",
                             "cancelurl": "http://dcszonline.dulwich-suzhou.cn",
                             "user": String(userid),
                             "course": String(homeworkList[homeworkIndex].courseId),
                             "id": String(homeworkList[homeworkIndex].activityId),
                             "canedit": "0",
                             "nosub": "1"]
        session.request(site_url + activity_url, method: .post, parameters: markPayload).responseString { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if (response.result.isSuccess){
                //print(response.result.value!)
                
                do{
                    let doc: Document = try SwiftSoup.parse(response.result.value!)
                    let response: String = (try doc.body()?.getElementById("page")?.select("div").first()?.select("section").first()?.select("div").first()?.select("div").first()?.select("label").first()?.select("span").first()?.text())!
                    //todo: add response control
                } catch Exception.Error(let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }else{
                NotificationCenter.default.post(name: Notification.Name(rawValue: "offline"), object: self)
            }
        }
    }
    
    public func getHomeworkDescription(homeworkIndex: Int){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        session.request(site_url + activity_url + "?course=\(homeworkList[homeworkIndex].courseId)&id=\(homeworkList[homeworkIndex].activityId)", method: .get).responseString { response in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if (response.result.isSuccess){
                do{
                    let doc: Document = try SwiftSoup.parse(response.result.value!)
                    let description: String = try (doc.getElementById("activitydesc")?.select("div").first()?.text())!
                    print(description)
                    //todo: add response control
                } catch Exception.Error(let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }else{
                NotificationCenter.default.post(name: Notification.Name(rawValue: "offline"), object: self)
            }
        }
    }
    
    public func sortHomeworkListByDate(list: Array<Homework>) -> Array<Homework>{
        //Create time list from homework list
        var timelist: Array<String> = []
        for activity in list{
            timelist.append(activity.activityDueDate)
        }
        
        //Sort time list by converting to Date() and then convert back
        var convertedArray: [Date] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        for dat in timelist {
            let date = dateFormatter.date(from: dat)
            if let date = date {
                convertedArray.append(date)
            }
        }
        let sortedTime = convertedArray.sorted(by: { $0.compare($1) == .orderedDescending })
        timelist = []
        for time in sortedTime{
            let timeStringArray = dateFormatter.string(from: time).components(separatedBy: "-")
            var timeStringDay = timeStringArray[0]
            var timeStringMonth = timeStringArray[1]
            let timeStringYear = timeStringArray[2]
            let timeIntMonth = Int(timeStringMonth)!
            timeStringMonth = String(describing: timeIntMonth)
            
            let timeIntDay = Int(timeStringDay)!
            timeStringDay = String(describing: timeIntDay)
            
            let timeString = timeStringDay + "-" + timeStringMonth + "-" + timeStringYear
            timelist.append(timeString)
        }
        /*
         var timeString = dateFormatter.string(from: time)
         let originaltimeStringMonth = timeString.components(separatedBy: "-")[1]
         var timeStringMonth = timeString.components(separatedBy: "-")[1]
         if (timeStringMonth.prefix(1) == "0"){timeStringMonth.remove(at: timeStringMonth.startIndex)}
         timeString = timeString.replacingOccurrences(of: originaltimeStringMonth, with: timeStringMonth)
         timelist.append(timeString)
        */
        
        
        //Sort homework using the sorted time list
        var sortedList:Array<Homework> = list
        for activity in list{
            for time in timelist.enumerated(){
                let index = time.offset
                let activityTime = time.element
                if(activity.activityDueDate == activityTime){
                    sortedList[index] = activity
                    timelist[index] = "none"
                    break
                }
            }
        }
        return sortedList
    }
    
    public func getCurrentSessionKey() -> String{
        return ""
    }
    
}
