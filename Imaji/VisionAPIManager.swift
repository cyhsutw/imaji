//
//  VisionAPIManager.swift
//  Imaji
//
//  Created by Cheng-Yu Hsu on 4/28/16.
//  Copyright © 2016 cyhsu. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AFNetworking
import SwiftyJSON
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


func onBackgroundThread(_ block: @escaping () -> ()) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

enum Emotion: String {
    case Joy = "joy"
    case Sorrow = "sorrow"
    case Surprise = "surprise"
    case Anger = "anger"
}

protocol VisionAPIManagerDelgate: class {
    func progressUpdated(_ progress: Double)
    func completed(objects: [String], emotions: [Emotion])
    func failed(_ error: NSError)
}

class VisionAPIManager: NSObject {
    static let sharedManager = VisionAPIManager()

    weak var delegate: VisionAPIManagerDelgate?
    
    fileprivate let apiKey = Constants.GoogleVisionAPIKey

    fileprivate lazy var networkManager: AFHTTPSessionManager = {
        
        let reqSerializer = AFJSONRequestSerializer()
        reqSerializer.setValue(
            Bundle.main.bundleIdentifier ?? "",
            forHTTPHeaderField: "X-Ios-Bundle-Identifier"
        )
        
        let resSerializer = AFJSONResponseSerializer()
        
        let manager = AFHTTPSessionManager(
            baseURL: URL(
                string: "https://vision.googleapis.com"
            )!
        )
        
        manager.requestSerializer = reqSerializer
        manager.responseSerializer = resSerializer
        return manager
    }()
    
    override init() {
        super.init()
        
    }
}

extension VisionAPIManager {
    func uploadImage(_ image: UIImage) {
        
        onBackgroundThread { 
            let thumbWidth: CGFloat = 800.0
            let thumbHeight: CGFloat = thumbWidth * image.size.height / image.size.width
            
            let thumbnail = self.resizeImage(image, toSize: CGSize(width: thumbWidth, height: thumbHeight))
            self.sendRequest(encodedImage: self.base64EncodeImage(thumbnail))
        }
    }
    
    fileprivate func resizeImage(_ image: UIImage, toSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    fileprivate func base64EncodeImage(_ image: UIImage) -> String {
        let imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.count > 2097152) {
            fatalError("Image size > 2 MB")
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    fileprivate func sendRequest(encodedImage: String) {
        
        networkManager.post(
            "/v1/images:annotate?key=\(apiKey)",
            parameters: [
                "requests": [
                    "image": [
                        "content": encodedImage
                    ],
                    "features": [
                        [
                            "type": "LABEL_DETECTION",
                            "maxResults": 10
                        ],
                        [
                            "type": "FACE_DETECTION",
                            "maxResults": 10
                        ],
                        [
                            "type": "LOGO_DETECTION",
                            "maxResults": 10
                        ]
                    ]
                ]
            ],
            progress: {
                [weak self] (progress) in
                self?.delegate?.progressUpdated(progress.fractionCompleted)
            },
            success: {
                (task, result) in
                
                let json = JSON(result!)
                let errorObject = json["error"]
                
                if errorObject.dictionaryValue != [:] {
                    self.delegate?.failed(
                        NSError(
                            domain: errorObject["message"].stringValue,
                            code: errorObject["code"].intValue,
                            userInfo: nil
                        )
                    )
                } else {
                    let resp = json["responses"][0]
                    
                    var emotionsDict = [Emotion : Double]()
                    var objectsDict = [String : Double]()
                    
                    // Get face annotations
                    let faceAnnotations: JSON = resp["faceAnnotations"]
                    if faceAnnotations != nil {
                        let emotions: Array<String> = ["joy", "sorrow", "surprise", "anger"]
                        
                        let numPeopleDetected:Int = faceAnnotations.count
                        
                        var emotionTotals: [String: Double] = ["sorrow": 0, "joy": 0, "surprise": 0, "anger": 0]
                        var emotionLikelihoods: [String: Double] = ["VERY_LIKELY": 0.9, "LIKELY": 0.75, "POSSIBLE": 0.5, "UNLIKELY":0.25, "VERY_UNLIKELY": 0.0]
                        
                        for index in 0..<numPeopleDetected {
                            let personData:JSON = faceAnnotations[index]
                            
                            // Sum all the detected emotions
                            for emotion in emotions {
                                let lookup = emotion + "Likelihood"
                                let result: String = personData[lookup].stringValue
                                emotionTotals[emotion]! += emotionLikelihoods[result]!
                            }
                        }
                        // Get emotion likelihood as a % and display in UI
                        for (emotion, total) in emotionTotals {
                            let likelihood: Double = total / Double(numPeopleDetected)
                            if likelihood > 0.6 {
                                emotionsDict[Emotion(rawValue: emotion)!] = likelihood
                            }
                        }
                    }
                    
                    // Get label annotations
                    let labelAnnotations: JSON = resp["labelAnnotations"]
                    let numLabels: Int = labelAnnotations.count
                    if numLabels > 0 {
                        for index in 0..<numLabels {
                            let label = labelAnnotations[index]["description"].stringValue
                            let score = labelAnnotations[index]["score"].doubleValue
                            objectsDict[label] = score
                        }
                    }
                    
                    self.delegate?.completed(objects: objectsDict.sortedKeysByValues(>), emotions: emotionsDict.sortedKeysByValues(>))
                }
            },
            failure: {
                [weak self] (task: URLSessionDataTask?, error: Error) in
                self?.delegate?.failed(error as NSError)
            }
        )
    }
}
