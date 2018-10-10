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
        gradientLayer.colors = [UIColor(red:0.20, green:0.20, blue:0.20, alpha:1.0).cgColor, UIColor(red:0.35, green:0.33, blue:0.33, alpha:1.0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
    }
}
