//
//  ViewController.swift
//  iOSClient
//
//  Created by Brandon Kong on 4/4/18.
//  Copyright © 2018 Himokagami. All rights reserved.
//

import UIKit

class TodayController: UIViewController {
    
    var DCSZOnline = DCSZOnlineConnector()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.addNotificationObservers()
    }
    
    func addNotificationObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(refreshedHomework(withNotification:)), name: NSNotification.Name(rawValue:"refreshHomeworkList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offline(withNotification:)), name: NSNotification.Name(rawValue:"offline"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessful(withNotification:)), name: NSNotification.Name(rawValue:"loginSuccessful"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loginUnsuccessful(withNotification:)), name: NSNotification.Name(rawValue:"loginUnsuccessful"), object: nil)
    }
    
    @objc func refreshedHomework(withNotification notification : NSNotification) {
        var homeworkString = ""
        var count:Int = 1
        for activity in DCSZOnline.homeworkList{
            let selector:Bool = activity.activityStatus != "Completed"
            if (selector){
                homeworkString = homeworkString + "\(String(count)). \(activity.activityName) - \(activity.subjectName)\n  Due date: \(activity.activityDueDate)\n"
                count = count + 1
            }
        }
        let alertController = UIAlertController(title: "宿題はリフレッシュされました! ", message: homeworkString, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "がんばろう！", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func offline(withNotification notification : NSNotification) {
        let alertController = UIAlertController(title: "", message: "The server could not be reached", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func loginSuccessful(withNotification notification : NSNotification) {
        let alertController = UIAlertController(title: "Status", message: "Login successful!", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        // self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func loginUnsuccessful(withNotification notification : NSNotification) {
        let alertController = UIAlertController(title: "", message: "Wrong password!", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func press(){
        DCSZOnline.setUsername(name: "brandon.kong")
        DCSZOnline.setPassword(pwd: "")
        DCSZOnline.login()
    }
    
    


}

