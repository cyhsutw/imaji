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

func onBackgroundThread(block: () -> ()) {
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        block
    )
}

enum Emotion: String {
    case Joy = "joy"
    case Sorrow = "sorrow"
    case Surprise = "surprise"
    case Anger = "anger"
}

protocol VisionAPIManagerDelgate: class {
    func progressUpdated(progress: Double)
    func completed(objects objects: [String], emotions: [Emotion])
    func failed(error: NSError)
}

class VisionAPIManager: NSObject {
    static let sharedManager = VisionAPIManager()

    weak var delegate: VisionAPIManagerDelgate?
    
    private let API_KEY = "PLACE_YOUR_API_KEY_HERE"

    private lazy var networkManager: AFHTTPSessionManager = {
        
        let reqSerializer = AFJSONRequestSerializer()
        reqSerializer.setValue(
            NSBundle.mainBundle().bundleIdentifier ?? "",
            forHTTPHeaderField: "X-Ios-Bundle-Identifier"
        )
        
        let resSerializer = AFJSONResponseSerializer()
        
        let manager = AFHTTPSessionManager(
            baseURL: NSURL(
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
    func uploadImage(image: UIImage) {
        
        onBackgroundThread { 
            let thumbWidth: CGFloat = 800.0
            let thumbHeight: CGFloat = thumbWidth * image.size.height / image.size.width
            
            let thumbnail = self.resizeImage(image, toSize: CGSizeMake(thumbWidth, thumbHeight))
            self.sendRequest(encodedImage: self.base64EncodeImage(thumbnail))
        }
    }
    
    private func resizeImage(image: UIImage, toSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func base64EncodeImage(image: UIImage) -> String {
        let imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.length > 2097152) {
            print("OMG WTF?")
        }
        
        return imagedata!.base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn)
    }
    
    private func sendRequest(encodedImage encodedImage: String) {
        
        networkManager.POST(
            "/v1/images:annotate?key=\(API_KEY)",
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
                (taks, result) in
                print(result)
                
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
                [weak self] (task, error) in
                self?.delegate?.failed(error)
            }
        )
    }
}