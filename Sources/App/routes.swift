import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    
    router.post("ImageDocToData"){
        req -> Future<String> in
        return
        try req.content.decode(DocProcessRequest.self).map(to: String.self) {
            docRequest in
            
            var finished = false
            print(docRequest.key)
            print(docRequest.image)
            
          
            if docRequest.key == keyForABO{
                  Tool.shared.usageRecorder()
            }else{
                return "Auth failed"
            }
           let processor = InsProcessor()
            
            if let request = Tool.shared.createReq(with: docRequest.image.base64EncodedString()){
                Tool.shared.runRequestOnBackgroundThread(request, completion: { (str) in
                    
                    processor.startProcess(str)
                    print(processor.output)
                    finished = true
                })
            }
            while !finished{
                sleep(1)
            }
            Tool.shared.resourceUpload(result: processor.output, imageData: docRequest.image)
            print(processor.output)
            return processor.output
          
            

        }
    }
    
   
}

