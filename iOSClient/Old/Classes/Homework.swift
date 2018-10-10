//
//  Homework.swift
//  iOSClient
//
//  Created by Brandon Kong on 5/6/18.
//  Copyright © 2018 Himokagami. All rights reserved.
//

import Foundation

class Homework{
    public var courseName: String
    public var courseId: Int
    public var subjectName: String
    public var activityName: String
    public var activityId: Int
    public var activityTeacher: String
    public var activityStatus: String
    public var activityGrade: String
    public var activityRequireUpload: Bool
    public var activityFeedback: String
    public var activityDueDate: String
    
    required init(courseName: String,
                  courseId: Int,
                  subjectName: String,
                  activityName: String,
                  activityId: Int,
                  activityTeacher: String,
                  activityStatus: String,
                  activityGrade: String,
                  activityRequireUpload: Bool,
                  activityFeedback: String,
                  activityDueDate: String) {
        self.courseName = courseName
        self.courseId = courseId
        self.subjectName = subjectName
        self.activityName = activityName
        self.activityId = activityId
        self.activityTeacher = activityTeacher
        self.activityStatus = activityStatus
        self.activityGrade = activityGrade
        self.activityRequireUpload = activityRequireUpload
        self.activityFeedback = activityFeedback
        self.activityDueDate = activityDueDate
    }
}
