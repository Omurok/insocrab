//
//  DataReciver.swift
//  App
//
//  Created by Omurok Chien on 2018/12/26.
//

import Foundation

import Vapor
import Multipart

let keyForABO = "4e117cf8-24bb-4c01-a0d7-053b7318d96c"




let googleAPIKey = "AIzaSyA35lu_7xo7_UFVltN86SfE7qeybTVi3iY"
var googleURL: URL {
    return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
}

struct DocProcessRequest:Content {
    var key:String
    var image: Data
}
class Tool{
    static let shared = Tool()

func imageSizeChecker(imgData:Data) -> Bool{
    if imgData.count > 2097152{
        return false
    }else{
        return true
    }
    
}

func createReq(with imageBase64: String) -> URLRequest?{
    // Create our request URL
    
    var request = URLRequest(url: googleURL)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
    let jsonStr =
    """
    {
    "requests": [
    {
    "image": {
    "content": "\(imageBase64)"
    },
    "features": [
    {
    "type": "DOCUMENT_TEXT_DETECTION"
    }
    ]
    }
    ]
    }
    
    """
    if let jsonData = jsonStr.data(using: String.Encoding.utf8,allowLossyConversion: false){
        do {let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            
            request.httpBody = jsonData
            return request
           
        }catch{
            print(error.localizedDescription)
        }
    }else{
        print("JSON convert ERROR")
        return nil
    }
    return nil
}


func createRequest(with imageBase64: String,completion:@escaping (String)->Void){
    // Create our request URL
    
    var request = URLRequest(url: googleURL)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
    let jsonStr =
    """
{
  "requests": [
    {
      "image": {
        "content": "\(imageBase64)"
      },
      "features": [
        {
          "type": "DOCUMENT_TEXT_DETECTION"
        }
      ]
    }
  ]
}

"""
    if let jsonData = jsonStr.data(using: String.Encoding.utf8,allowLossyConversion: false){
        do {let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
           
            request.httpBody = jsonData
            
            runRequestOnBackgroundThread(request, completion: completion)
        }catch{
            print(error.localizedDescription)
        }
    }else{
        print("JSON convert ERROR")
    }

}

let session = URLSession.shared

func runRequestOnBackgroundThread(_ request: URLRequest,completion:@escaping (String)->Void){
    // run the request
    print("runRequestOnBackgroundThread")
    
    let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
        
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "")
            return
        }
        do{ let result = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
            if let str = result["responses"] as? [Any],let str1 = str[0] as? [String:Any]{
                if let fullText = str1["fullTextAnnotation"] as? [String:Any] ,let text = fullText["text"] as? String{
//                    print("text",text)
                    completion(text)
                   
                }
            }else{
                print("downcast error")
            }
        }catch{
            print(error.localizedDescription)
        }
        
        
//        if let str = String(data: data, encoding: String.Encoding.utf8){
//            print(str)
//        }
        
//        self.analyzeResults(data)
        }
    task.resume()
}

func usageRecorder(){
    if let url = URL(string: "https://twins.taipei/ins/API/misc/docProcessUsageRecorder.php?user=MyAbao"){
        let urlRequest = URLRequest(url: url)
        let task = session.dataTask(with: urlRequest)
        task.resume()

    }
}
    func resourceUpload(result:String,imageData:Data){
        
        if let url = URL(string: "https://twins.taipei/ins/API/misc/uploadPolicyImageFA.php"){
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let random = "20743080998065749"
            let boundary = "Boundary+\(random)\(random)"
            var body = Data()
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let parameters:[String:Any] = ["MandeResult":result]
            for (key, value) in parameters {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
            let dataPath:[String:Data] = ["Image":imageData]
            for (key, value) in dataPath {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(random)\"\r\n")
                
                body.appendString(string: "Content-Type: image/jpg\r\n\r\n")
                body.append(value)
                body.appendString(string: "\r\n")
            }
            body.appendString(string: "--\(boundary)--\r\n")
            request.httpBody = body
            let task = session.dataTask(with: request)
            task.resume()
        }
    }
}
extension Data{
    
    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
