//
//  GradientView.swift
//  iOSClient
//
//  Created by Brandon Kong on 5/3/18.
//  Copyright © 2018 Himokagami. All rights reserved.
//

import UIKit

class GradientView: UIView{
    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = [UIColor.init(red: 1, green: 74/255, blue: 74/255, alpha: 1).cgColor, UIColor.init(red: 1, green: 205/255, blue: 164/255, alpha: 1).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
    }
}
