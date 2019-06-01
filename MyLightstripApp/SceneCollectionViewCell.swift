//
//  SceneCollectionViewCell.swift
//  MyLightstripApp
//
//  Created by Ivan Bui on 2019-05-16.
//  Copyright © 2019 Ivan Bui. All rights reserved.
//

import UIKit
import AFNetworking

class SceneCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    let serverURL = "SERVER_BASE_URL"
    var colourR: CGFloat = 0
    var colourG: CGFloat = 0
    var colourB: CGFloat = 0
    var brightness: CGFloat = 0
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.backgroundColor = UIColor(red: 238.0/255, green: 233.0/255, blue: 233.0/255, alpha: 0.6)
                self.label.textColor = UIColor.black
            } else {
                self.backgroundColor = UIColor(red: 31.0/255, green: 33.0/255, blue: 36/255, alpha: 1.0)
                self.label.textColor = UIColor.white
            }
        }
    }
    
    func changeScene() {
        let baseUrl = Bundle.main.object(forInfoDictionaryKey: serverURL) as! String
        let manager = AFHTTPSessionManager()
        let params = [
            "r": colourR,
            "g": colourG,
            "b": colourB,
            "brightness": brightness
        ]
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.post(baseUrl + "colour/rgb", parameters: params, progress: nil, success: { (sessionTask, respose) in
            if let dict = respose as? Dictionary<String,Any> {
                print(dict)
            } else {
            }
        }, failure: { (sessionTask, error) in
            print(error)
        })
//        manager.get(baseUrl + "colour/rgb", parameters: parameters, progress: nil, success: { (sessionTask, respose) in
//            if let dict = respose as? Dictionary<String,Any> {
//                print(dict)
//            } else {
//            }
//        }, failure: { (sessionTask, error) in
//            print(error)
//        })
    }
}
