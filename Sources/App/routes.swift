import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
//    router.get { req in
//        return "It works!"
//    }
//
//    // Basic "Hello, world!" example
//    router.get("hello") { req in
//        return "Hello, world!"
//    }

//    router.post("doc"){
//        req -> Future<HTTPStatus> in
//        return try req.content.decode(DocProcessRequest.self).map(to: HTTPStatus.self) {
//            docRequest in
//            print(docRequest.key)
//            print(docRequest.image)
//
//            if imageSizeChecker(imgData: docRequest.image){
//
//
//                createRequest(with: docRequest.image.base64EncodedString(), completion: {str in
//                    print(str)
//                })
//                return .ok
//
//            }else{
//                return .conflict
//            }
//
//        }
//    }
    
    router.post("ImageDocToData"){
        req -> Future<String> in
        return
        try req.content.decode(DocProcessRequest.self).map(to: String.self) {
            docRequest in
            
            var finished = false
            print(docRequest.key)
            print(docRequest.image)
            
          
            if docRequest.key == keyForABO{
                  usageRecorder()
            }else{
                return "Auth failed"
            }
           let processor = InsProcessor()
            
            if let request = createReq(with: docRequest.image.base64EncodedString()){
                runRequestOnBackgroundThread(request, completion: { (str) in
                    
                    processor.startProcess(str)
                    print(processor.output)
                    finished = true
                })
            }
            while !finished{
                sleep(1)
            }
            resourceUpload(result: processor.output, imageData: docRequest.image)
            print(processor.output)
            return processor.output
          
            

        }
    }
    
   
}

