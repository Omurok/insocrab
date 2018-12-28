//
//  Insurance.swift
//  APIPackageDescription
//
//  Created by Omurok Chien on 2018/10/12.
//

import Vapor
enum InsPayInterval:Int {
    case 年繳 = 0
    case 半年繳 = 1
    case 季繳 = 2
    case 月繳 = 3
    case 躉繳 = 4
}

class InsProcessor{
    var insName = ""{didSet{print("保單名稱設定為",insName)}}
    var insSurName:[String] = []{didSet{print("附約設定為",insSurName)}}
    var insMoney:Int?{didSet{print("保額設定為",insMoney)}}
    var insCompany = ""{didSet{print("保險公司名稱設定為",insCompany)}}
    var insTarget = ""{didSet{print("被保險人設定為",insTarget)}}
    var insNumber = ""{didSet{print("保單號碼設定為",insNumber)}}
    var insType:Int = 0{didSet{print("保單類型設定為",insType)}}
    var insTypeSet:Bool = false{didSet{print("保單類型已設定",insTypeSet)}}
    var insStart:[String] = []{didSet{print("保單生效日設定為",insStart)}}
    var insLifeTime = false{didSet{print("終身型設定為",insLifeTime)}}
    var insEnd:[String] = []{didSet{print("契約終止日定為",insEnd)}}
    var insPayDuration:Int?{didSet{print("繳費年間定為",insPayDuration)}}
    var insPayInterval:Int?{didSet{print("繳費週期別定為",insPayInterval)}}//０：年繳１半年繳２季繳３月繳４躉繳
    var insPayPrice:Int?{didSet{print("每次繳費金額設定為",insPayPrice)}}
    var insFirstPay:[String] = []{didSet{print("首期繳費日設定為",insFirstPay)}}
    var insEndPay:[String] = []{didSet{print("期滿繳費日設定為",insEndPay)}}
    
    func organizer(_ input:String)->String{
        startProcess(input)
        return "Return from InsProcessor Organizer \(input)"
    }
    
    
    func startOutput()->String{
        
        
        
        
        
//        let dic : [String : Any] = ["insName":insName, "insSurName":insSurName,"insMoney":insMoney ?? 0,"insCompany":insCompany,"insTarget":insTarget,"insNumber":insNumber,"insType":insType,"insStart":insStart,"insLifeTime":insLifeTime,"insEnd":insEnd,"insPayDuration":insPayDuration,"insPayInterval":insPayInterval,"insPayPrice":insPayPrice,"insFirstPay":insFirstPay,"insEndPay":insEndPay]
        
        let dic : [String : Any] = ["insName":insName, "insMoney":insMoney ?? 0,"insCompany":insCompany,"insTarget":insTarget,"insNumber":insNumber,"insType":insType,"insPayPrice":insPayPrice]
        
        
        do{let data = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            let jsonString = String(data: data, encoding: .utf8)
            print("startOutput jsonString",jsonString)
            
            
            return jsonString ?? "FAILED"
        }catch{
            return "ERROR"
        }
        
    }
    
    func startProcess(_ input:String){
        insName = ""
        insSurName = []
        insMoney = nil
        insCompany = ""
        insTarget = ""
        insNumber = ""
        insType = 0
        insTypeSet = false
        insStart = []
        insLifeTime = false
        insEnd = []
        insPayDuration = nil
        insPayInterval = nil
        insPayPrice = nil
        insFirstPay = []
        insEndPay = []
        var data:[String] = []
        for str in input.components(separatedBy: "\n"){
            data.append(str)
        }
        print(data)
        var done = false
        for i in InsuranceCompany.allValues{
            if input.contains(i.rawValue){
                setInsCompany(i)
                self.insuranceProcessor(company: i.rawValue, data: data)
                done = true
            }
        }
        if !done{
            self.insuranceProcessor(company: "", data: data)
        }
    }
    
    func insuranceProcessor(company:String,data:[String]){
        print("Insurance Processor into \(company)")
        let stringIndexMax = data.count - 1
        //Find InsTarget 被保險人
        findInsTarget(data)
        //Find insName 保單名稱
        findInsName(data)
        //Find insNumber 保單號碼
        findInsNumber(data)
        //MARK:按照公司優化
        switch company {
        case InsuranceCompany.幸福.rawValue:
            for i in 0...stringIndexMax{
                if data[i].contains("種類") && insName == ""{
                    insName = colonProcessor(data[i])
                }
                if data[i].contains("新台幣")  && insPayPrice == nil{
                    print("data[i]",data[i])
                    let decoloned = colonProcessor(data[i])
                    //                    print("decoloned",decoloned)
                    insPayPrice = moneyProcessor(decoloned)
                    //                    print("money",money)
                    
                }
            }
        case InsuranceCompany.大都會.rawValue:
            for i in 0...stringIndexMax{
                
                if data[i].contains("保險種類") && insName == ""{
                    insName = colonProcessor(data[i])
                }
                if data[i] == "主契約" && i+1 <= stringIndexMax && insName == ""{
                    insName = data[i+1]
                }
                
                if data[i].contains("被保險") && data[i].count > 5 && insTarget == ""{
                    if data[i].contains(":"){
                        insTarget = colonProcessor(data[i])
                    }
                }
                if data[i].contains("單號碼") && data[i].count > 5 && insNumber == ""{
                    if data[i].contains(":"){
                        insNumber = colonProcessor(data[i])
                    }
                }
                if data[i].contains("契約始期") && insStart == [] {
                    let paras = data[i].components(separatedBy: " ")
                    print("paras",paras)
                    var element:[Int] = []
                    for para in paras{
                        let trimmed = para.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
                        if let result = Int(trimmed){
                            element.append(result)
                        }
                    }
                    print(element)
                    insStart = dateExtractor(data[i])
                    insFirstPay = insStart
                }
                if data[i].contains("00,000") && insMoney == nil{
                    insMoney = moneyProcessor(data[i])
                    if i+2 <= stringIndexMax{
                        insPayPrice =  moneyProcessor(data[i+2])
                    }
                }
                
            }
        case InsuranceCompany.遠雄.rawValue:
            for i in 0...stringIndexMax{
                
                let source = data[i].replacingOccurrences(of: " ", with: "")
                if source.contains("被保險") && insTarget == ""{
                    insTarget = colonProcessor(source)
                }
                if insTarget != "" && source == insTarget{
                    if i+1 <= stringIndexMax{
                        insName = data[i+1]
                    }
                }
                
                if source.contains("每期保險費") && insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)
                }
            }
            
        case InsuranceCompany.富邦.rawValue:
            for i in 0...stringIndexMax{
                let source = data[i].replacingOccurrences(of: " ", with: "")
                print(source)
                if source.contains("保險名稱") && insName == ""{
                    insName = colonProcessor(source)
                }
                if data[i].contains("萬元"){
                    insMoney = wanYuanProcessor(data[i])
                }
                if source.contains("保險金額") && insMoney == nil{
                    insMoney = (wanYuanProcessor(source))
                }
                if source.contains("保險期間") && insStart == []{
                    insStart = dateExtractor(source)
                    insFirstPay = insStart
                }
                if source.contains("主契約保險費") && insPayPrice == nil{
                    if i+1 <= stringIndexMax{
                        insPayPrice =  moneyProcessor(data[i+1])
                    }
                }
                if source.contains("元整") && (insPayPrice == nil || insPayPrice == 0){
                    insPayPrice = moneyProcessor(source)
                }
            }
            
        case InsuranceCompany.全球.rawValue:
            for i in 0...stringIndexMax{
                let source = data[i].replacingOccurrences(of: " ", with: "")
                if source.contains("計劃單位") && insName == "" {
                    if i+1 <= stringIndexMax{
                        insName = data[i+1]
                    }
                }
                if source.contains("年") && source.contains("月") && source.contains("日") && insStart == []{
                    insStart = dateExtractor(source)
                    insFirstPay = insStart
                }
                if source.contains("應繳保險費") && insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)
                }
            }
            
        case InsuranceCompany.中興.rawValue:
            for i in 0...stringIndexMax{
                if data[i] == "主契約" && insName == ""{
                    if i+1 <= stringIndexMax{
                        insName = data[i+1]}
                }
                if data[i] == "附加契約"{
                    if i+1 <= stringIndexMax{
                        insSurName.append(data[i+1])
                    }
                }
                if data[i].contains("契約期") && insStart == []{
                    insStart = dateExtractor(data[i])
                    insFirstPay = insStart
                }
                
                if data[i].contains("每期保險費") && insPayInterval == nil{
                    if data[i].contains("半年"){
                        insPayInterval = InsPayInterval.半年繳.rawValue
                        
                    }else if data[i].contains("年"){
                        insPayInterval = InsPayInterval.年繳.rawValue
                    }else if data[i].contains("季"){
                        insPayInterval = InsPayInterval.季繳.rawValue
                    }else if data[i].contains("月"){
                        insPayInterval = InsPayInterval.月繳.rawValue
                    }
                    insPayPrice = moneyProcessor(data[i])
                }
            }
            
        case InsuranceCompany.保誠.rawValue:
            for i in 0...stringIndexMax{
                if data[i].contains("保險種類") && insName == ""{
                    insName = blankProcessor(data[i])
                }
                if data[i].contains("萬元"){
                    insMoney = wanYuanProcessor(data[i])
                }
                if data[i].contains("被保險") && data[i].count > 5 && insTarget == ""{
                    insTarget = stringRemover(input: data[i], toRemove: "被保險人")
                    
                }
                if data[i].contains("每期保險費") && insPayInterval == nil{
                    if data[i].contains("半年"){
                        insPayInterval = InsPayInterval.半年繳.rawValue
                        
                    }else if data[i].contains("年"){
                        insPayInterval = InsPayInterval.年繳.rawValue
                    }else if data[i].contains("季"){
                        insPayInterval = InsPayInterval.季繳.rawValue
                    }else if data[i].contains("月"){
                        insPayInterval = InsPayInterval.月繳.rawValue
                    }
                    insPayPrice = moneyProcessor(data[i])
                }
                
                if data[i].contains("單號") && insNumber == ""{
                    insNumber = blankProcessor(data[i])
                }
                
            }
            
        case InsuranceCompany.國寶.rawValue:
            for i in 0...stringIndexMax{
                if data[i].contains("保單") && insNumber == ""{
                    insNumber = colonProcessor(data[i])
                }
                if data[i].contains("種類") && insName == ""{
                    insName = colonProcessor(data[i])
                }
                if data[i].contains("保險附"){
                    insSurName.append(colonProcessor(data[i]))
                }
                if data[i].contains("0,000") && insMoney == nil{
                    let paras = data[i].components(separatedBy: " ")
                    for para in paras{
                        if para.contains("0,000"){
                            insMoney = moneyProcessor(para)}
                    }
                }
                if (data[i].contains("被保險") || data[i].contains("被保险人")) && insTarget == ""{
                    if data[i].contains(":"){
                        if let result = data[i].components(separatedBy: ":").last{insTarget = result
                        }else if  data[i].contains("："){
                            if let result = data[i].components(separatedBy: "：").last{insTarget = result
                            }}else{insTarget = data[i]}}
                }
                
            }
            
        case InsuranceCompany.南山.rawValue:
            for i in 0...stringIndexMax{
                print("南山字串[\(data[i])]")
                if  data[i].contains(",000") && insMoney == nil{
                    
                    let sliced = data[i].components(separatedBy: " ")
                    print("南山 sliced = ",sliced)
                    var possibleNums:[Int] = []
                    for data in sliced{
                        if let sol = moneyProcessor(data),sol >= 6{
                            possibleNums.append(sol)
                        }
                    }
                    if possibleNums.count == 3{
                        if insMoney == nil{
                            insMoney = possibleNums[0]}
                        if insPayPrice == nil{
                            insPayPrice = possibleNums[1]}
                        if insPayDuration == nil{
                            insPayDuration = possibleNums[2]
                            setEndPay()
                        }
                    }
                    //                    insMoney = moneyProcessor(data[i])
                }
                let source = data[i]
                if (source.contains("保險費") || source.contains("保費總額") ){
                    print("保險費保費總額")
                    if let hasValue = moneyProcessor(source){
                        insPayPrice = hasValue
                    }else if i < data.count+1 ,let hasValue = moneyProcessor(data[i+1]){
                        insPayPrice = hasValue}
                }
                if (source.contains("保險費") || source.contains("保費總額") ) && insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)
                }
                if data[i].contains("元整"){
                    if let hasValue = moneyProcessor(data[i]){
                        insPayPrice = hasValue
                    }else if i-1 >= 0, let hasValue = moneyProcessor(data[i-1]){
                        insPayPrice = hasValue
                    }}}
            findInsMoneyPrice(data)
            
        default:
            print("into default")
            for i in 0...stringIndexMax{
                let source = data[i].replacingOccurrences(of: " ", with: "")
                if source.contains("種類") && insName == ""{
                    insName = colonProcessor(source)
                }
                if source.contains("被保險") && insTarget == ""{
                    if source.contains(":"){
                        if let result = source.components(separatedBy: ":").last{insTarget = result
                        }else if  source.contains("："){
                            if let result = source.components(separatedBy: "：").last{insTarget = result
                            }}else{insTarget = source}}
                }
                
                if (source.contains("保險費") || source.contains("保費總額") ) && insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)
                }
                
            }
        }
        
        //END of Company Related set
        findPayDuration(data)
        
        findInsType(data)
        
        
        findInsMoneyPrice(data)
        output = startOutput()
        
    }
    var output:String = ""
    //MARK:Finders
    
    func findInsType(_ data:[String]){
        print("IN FINDINSTYPE")
        for d in data{
            
            
            if d.contains("附約") && (d.contains("醫療") || d.contains("失能") || d.contains("意外") || d.contains("傷害") || d.contains("癌症") || d.contains("手術") || d.contains("傷") || d.contains("殘")) {
                insSurName.append(d)
            }
            
            let source = d.replacingOccurrences(of: " ", with: "")
            if source.contains("單號") && insNumber == ""{
                insNumber = colonProcessor(source)
            }
            if source.contains("被保險") && insTarget == ""{
                insTarget = colonProcessor(source)
            }
            if source.contains("公司") && insCompany == ""{
                insCompany = source
            }
            if source.contains("壽險") && insTypeSet == false{
                insType = 0
                insTypeSet = true
            }
            if source.contains("意外險") && insTypeSet == false{
                insType = 1
                insTypeSet = true
                
            }
            if (source.contains("儲蓄")||source.contains("投資")) && insTypeSet == false{
                insType = 2
                insTypeSet = true
            }
            if source.contains("防癌險") && insTypeSet == false{
                insType = 4
                insTypeSet = true
            }
            if (source.contains("醫療險") || source.contains("醫療保險")) && insTypeSet == false{
                insType = 3
            }
            if (source.contains("長照") || source.contains("殘扶") || source.contains("殘廢")) && insTypeSet == false{
                insType = 5
                insTypeSet = true
            }
            
            if source.contains("終身"){
                insLifeTime = true
                insEnd = []
            }else if source.contains("定期"){
                insLifeTime = false
            }
            
            
            if (source.contains("半年繳") || source.contains("按半年")){
                insPayInterval = InsPayInterval.半年繳.rawValue
                if insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)}
            }
            if (source.contains("年繳") || source.contains("按年") || source.contains("每拾")) {
                insPayInterval = InsPayInterval.年繳.rawValue
                if insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)}
            }
            if (source.contains("季繳") || source.contains("按季")){
                insPayInterval = InsPayInterval.季繳.rawValue
                if insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)}
            }
            if (source.contains("月繳") || source.contains("按月")){
                insPayInterval = InsPayInterval.月繳.rawValue
                if insPayPrice == nil{
                    insPayPrice = moneyProcessor(source)}
            }
            if (source.contains("躉繳") || source.contains("臺繳") || source.contains("蔓繳") || source.contains("並繳")){
                insPayInterval = InsPayInterval.躉繳.rawValue
            }
            
            if source.contains("00,000") && insMoney == nil{
                insMoney = moneyProcessor(source)
            }
            if source.contains("契約始期") && insStart == [] {
                
                insStart = dateExtractor(source)
                insFirstPay = insStart
                if let num = insPayDuration,insStart.count > 0{
                    if let year = Int(insStart[0]){
                        let endYear = String(year+num)
                        insEndPay = insStart
                        insEndPay[0] = endYear
                    }
                }
                
                
            }
            if (source.contains("契約終期") || source.contains("契約滿期")) && insEnd == [] {
                insLifeTime = false
                print("IN findInsTypeIN 契約終期 契約滿期")
                insEnd = dateExtractor(source)
                
            }
        }
    }
    
    func findInsName(_ data:[String]){
        //MARK:Find InsName 保單名稱
        let stringIndexMax = data.count - 1
        
        var possibleInsName:[String] = []
        
        for i in 0...stringIndexMax{
            let target = data[i]
            if target.count >= 8 && target.count <= 25{
                if target.contains("公司") || target.contains("民國") || target.contains("幣值") || target.contains("份數") || target.contains("如上") || target.contains("日期"){
                }else{
                    possibleInsName.append(target)
                    
                }
            }
        }
        print("possibleInsName",possibleInsName)
        for possible in possibleInsName{
            for profile in insNameProfile{
                if possible.contains(profile){
                    if possible.contains(":"){
                        if let result = possible.components(separatedBy: ":").last{
                            insName = result
                        }
                    }else{
                        insName = possible
                    }
                    
                    return
                }
            }
        }
    }
    func findInsNumber(_ data:[String]){
        //MARK:Find InsNumber 保單號碼
        let stringIndexMax = data.count - 1
        
        var possibleInsNumber:[String] = []
        
        for i in 0...stringIndexMax{
            let target = data[i]
            
            if target.contains("保單號碼") && (target.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil){
                if let result = target.components(separatedBy: ":").last{
                    insNumber = result
                }
                
                return
            }
            
            
            
            
            if target.count >= 8 && target.count <= 15{
                if target.contains("公司") || target.contains("民國") || target.contains("幣值") || target.contains("份數") || target.contains("如上") || target.contains("日期") || target.contains("年") || target.contains("要保人"){
                }else{possibleInsNumber.append(target)}}}
        print("possibleInsNumber",possibleInsNumber)
        var hasNumber:[String] = []
        for each in possibleInsNumber{
            if (each.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil) && !each.contains(",") && !each.contains("元"){
                hasNumber.append(each)
            }
        }
        print("hasNumber",hasNumber)
        if let number = hasNumber.first{
            insNumber = number
        }
    }
    func findPayDuration(_ data:[String]){
        for source in data{
            if source.contains("6年"){insPayDuration = 6}
            if source.contains("10年"){insPayDuration = 10}
            if source.contains("15年"){insPayDuration = 15}
            if source.contains("20年"){insPayDuration = 20}
            if source.contains("21年"){insPayDuration = 21}
            if source.contains("25年"){insPayDuration = 25}
            if source.contains("30年"){insPayDuration = 30}
            if source.contains("六年"){insPayDuration = 6}
            if source.contains("十年"){insPayDuration = 10}
            if source.contains("十五年"){insPayDuration = 15}
            if source.contains("二十年"){insPayDuration = 20}
            if source.contains("二十一年"){insPayDuration = 21}
            if source.contains("二十五年"){insPayDuration = 25}
            if source.contains("三十年"){insPayDuration = 30}
        }
        setEndPay()
        
    }
    func setEndPay(){
        if let foundPayDuration = insPayDuration{
            if insFirstPay != [],insFirstPay.count == 3,let insFirstPayYear = Int(insFirstPay[0]){
                insEndPay = [String(insFirstPayYear+foundPayDuration),insFirstPay[1],insFirstPay[2]]
                if !insLifeTime{
                    insEnd = insEndPay
                }
            }
            
        }
    }
    
    func findInsTarget(_ data:[String]){
        //MARK:Find InsTarget 被保險人
        //先判定先有被保險人？
        let stringIndexMax = data.count - 1
        var firstInsTarget = true
        var firstInsTargetFound = false
        var insTargetSet = false
        for i in 0...stringIndexMax{
            if !firstInsTargetFound{
                if data[i].contains("被保") || data[i].contains("保被"){firstInsTargetFound = true}
                if data[i].contains("要保"){
                    firstInsTarget = false
                    firstInsTargetFound = true
                }}}
        print("firstInsTarget = ",firstInsTarget)
        var possibleInsTarget:[String] = []
        for i in 0...stringIndexMax{
            guard 2 <= data[i].count && data[i].count <= 12 else{continue}
            for lastNames in taiwanLastName{
                if data[i].contains(lastNames){
                    if !(data[i].contains("保單") || data[i].contains("號碼") || data[i].contains("項目") || data[i].contains("契約") || data[i].contains("計畫") || data[i].contains("保險費") || data[i].contains("萬元") || data[i].contains("保險單") || data[i].contains("金額") || data[i].contains("單位") || data[i].contains("股份") || data[i].contains("有限") || data[i].contains("公司") || data[i].contains("繳費") || data[i].contains("保障") || data[i].contains("壽險") || data[i].contains("終身") || data[i].contains("意外") || data[i].contains("身故") || data[i].contains("回饋") || data[i].contains("分享")){
                        
                        possibleInsTarget.append(data[i])}
                    
                }}}
        print("possibleInsTarget",possibleInsTarget)
        
        for p in possibleInsTarget{
            if p.contains("被保險人"){
                if let result = p.components(separatedBy: "被保險人").last{
                    if let trimmed = result.components(separatedBy: ":").last{
                        insTarget = trimmed
                    }else{
                        insTarget = result}
                }
                insTargetSet = true
            }
            
        }
        
        if firstInsTarget{
            if let it = possibleInsTarget.first{
                if !insTargetSet{
                    if it.contains(":"){
                        if let result = it.components(separatedBy: ":").last{
                            insTarget = result
                        }
                        
                    }else{
                        insTarget = it
                    }
                    
                    insTargetSet = true}
            }}else{if possibleInsTarget.count >= 2 {
            let lt = possibleInsTarget[1]
            if !insTargetSet{
                if lt.contains("被保險人"){
                    if let result = lt.components(separatedBy: "被保險人").last{
                        insTarget = result
                    }
                    
                }else{
                    insTarget = lt
                }
                
                insTargetSet = true}
            }}
    }
    func findInsMoneyPrice(_ data:[String]){
        var possiblePrice:[Int] = []
        let stringIndexMax = data.count - 1
        for i in 0...stringIndexMax{
            if data[i].contains(","){
                let dataSliced = data[i].components(separatedBy: " ")
                for j in dataSliced{
                    if let sol = moneyProcessor(j){
                        possiblePrice.append(sol)}}}}
        print("possiblePrice=",possiblePrice)
        
        var max = 0
        var second = 0
        var minimal = 100
        for price in possiblePrice{
            if price > max{
                max = price
            }
            if (price > second) && (price < max){
                second = price
            }
            if price < minimal && price >= 6{
                minimal = price
            }
        }
        print("max",max,"second",second,"minimal",minimal)
        if insMoney == nil{insMoney = max}
        if insPayPrice == nil{insPayPrice = second}
        if insPayDuration == nil && minimal != 100{insPayDuration = minimal
            setEndPay()
        }
    }
    
    //MARK:Processors
    
    func colonProcessor(_ input:String) -> String{
        var output = ""
        if input.contains(":"){
            if let result = input.components(separatedBy: ":").last{output = result
            }else if  input.contains("："){
                if let result = input.components(separatedBy: "：").last{output = result
                }}else{output = input}}else{
            output = input
        }
        return output
    }
    func moneyProcessor(_ input:String) -> Int?{
        print("MoneyProcessor Input = ",input)
        var result:Int = 0
        let output = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        if let money = Int(output){
            result = money
        }
        print("MoneyProcessor result = ",result)
        if result == 0{
            return nil
        }else{
            return result
        }
        
    }
    func blankProcessor(_ input:String) -> String{
        var output = ""
        if input.contains(" "){
            if let result = input.components(separatedBy: " ").last{
                output = result
            }else{
                output = input
            }
        }else{
            output = input
        }
        return output
    }
    func wanYuanProcessor(_ input:String) -> Int?{
        if input.contains("萬"){
            if let num = moneyProcessor(input){
                return num * 10000
            }else{
                return nil
            }
            
        }else{
            let numberic = moneyProcessor(input)
            return numberic
        }
    }
    func stringRemover(input:String, toRemove:String) -> String{
        var output = ""
        if input.contains(toRemove){
            if let result = input.components(separatedBy: toRemove).last{
                output = result
            }else{
                output = input
            }
        }else{
            output = input
        }
        return output
    }
    func dateExtractor(_ input:String) -> [String]{
        
        print("Into dateExtractor")
        print("USE STRING",input)
        
        
        var output:[String] = []
        
        if input.contains("年"){
            print("contains年月日")
            var components:[String] = []
            if let year = input.components(separatedBy: "年").first,let rest = input.components(separatedBy: "年").last{
                components.append(year)
                if let month = rest.components(separatedBy: "月").first,let rest2 = rest.components(separatedBy: "月").last{
                    components.append(month)
                    if let day = rest2.components(separatedBy: "日").first{
                        components.append(day)
                    }
                }
            }
            print("components",components)
            let paras = input.components(separatedBy: "年")
            print("paras=",paras)
            var element:[Int] = []
            for para in components{
                let trimmed = para.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
                if let result = Int(trimmed){
                    element.append(result)
                }
            }
            print("paras processed",paras)
            var elementInString:[String] = []
            for i in element{
                if i < 10{
                    let i0 = "0" + String(i)
                    elementInString.append(i0)
                }else{
                    elementInString.append(String(i))
                }
            }
            if let elementYear = elementInString.first{
                if let yearInInt = Int(elementYear){
                    if yearInInt < 1000{
                        let wYear = yearInInt + 1911
                        elementInString.remove(at: 0)
                        elementInString.insert(String(wYear), at: 0)
                    }
                }
            }
            print("elementInString",elementInString)
            output = elementInString
            
            
        }else{
            print("NO 年月日")
            var trimmed = input.components(separatedBy: CharacterSet.decimalDigits.inverted)
            print("trimmed separated",trimmed)
            trimmed = trimmed.filter { $0 != ""}
            print("trimmed filted",trimmed)
            
            if trimmed.count < 3, trimmed.count > 1{
                if let year = Int(trimmed[0]), year > 3000{
                    output = [String(year/100),String(year%100),trimmed[1]]
                }else if let month = Int(trimmed[1]), month > 12{
                    output = [trimmed[0],String(month/100),String(month%100)]
                }
            }
            if let elementYear = output.first{
                if let yearInInt = Int(elementYear){
                    if yearInInt < 1000{
                        let wYear = yearInInt + 1911
                        output.remove(at: 0)
                        output.insert(String(wYear), at: 0)
                    }
                }
            }
            
            
            
        }
        return output
    }
    
    func arrayToDate(_ input:[String]) -> Date?{
        if input.count == 3{
            if let year = Int(input[0]), let month = Int(input[1]) ,let day = Int(input[2]){
                var yearPro = year
                if yearPro < 200 {yearPro += 1911}
                let cal = Calendar(identifier: .gregorian)
                let component = DateComponents(calendar: cal, timeZone: nil, era: nil, year: yearPro, month: month, day: day, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                if let date = component.date{
                    return date
                }else{
                    return nil
                }
            }else{
                return nil
            }
        }else{
            return nil
        }
    }
    func dateEndCalculator(_ startDate:Date?,durationInYear:Int) -> Date?{
        let cal = Calendar(identifier: .gregorian)
        
        if let start = startDate{
            let year = cal.component(.year, from: start)
            let month = cal.component(.month, from: start)
            let day = cal.component(.day, from: start)
            let endYear = year+durationInYear
            let endComp = DateComponents(calendar: cal, timeZone: nil, era: nil, year: endYear, month: month, day: day, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
            if let end = endComp.date{
                
                return end
            }else{
                print("endComp to Date failed")
                return nil
            }
            
        }else{
            print("NO STARTDATE")
            return nil
        }
    }
    let insNameProfile = ["定期壽險","定期保險","萬能壽險","健康保險","傷病保險","傷病終身","終身保險","住院醫療","御守醫療","傷害醫療","旅行平安","疾病醫療","終身保險","終身壽險","定期","意外","傷害","長期照顧","住院","利率變動型","變動型還本","變動型保本","變動型增額","養老保險","年金保險","變額壽險","轉蛋保險","終身醫療"]
    let taiwanLastName = ["陳","林","黃","張","李","王","吳","劉","蔡","楊","許","鄭","謝","郭","洪","邱","曾","廖","賴","徐","周","葉","蘇","莊","呂","江","何","蕭","羅","高","潘","簡","朱","鍾","彭","游","詹","胡","施","沉","余","盧","趙","梁","顏","柯","翁","魏","孫","戴","方","宋","范","鄧","杜","傅","侯","曹","薛","丁","卓","馬","董","唐","藍","蔣","石","紀","姚","古","連","馮","歐","程","湯","康","田","姜","汪","白","鄒","尤","巫","鍾","塗","龔","嚴","韓","袁","阮","黎","金","童","陸","夏","柳","邵","錢","溫","伍","倪","於","譚","駱","熊","任","顧","甘","秦","毛","史","章","萬","俞","官","雷","饒","粘","張簡","闕","崔","尹","凌","孔","歐陽","辛","易","辜","陶","龍","段","葛","韋","池","孟","殷","褚","賈","賀","麥","管","莫","文","向","關","包","丘","陳黃","范姜","華","武","利","梅","張陳","李陳","左","房","魯","佘","陳李","鮑","安","花","郝","穆","全","邢","塗","蒲","成","常","陳吳","谷","盛","耿","練","聶","鄔","祝","曲","解","繆","齊","申","岳","李林","閻","應","單","符","籃","舒","喬","陽","牛","畢","林吳","翟","季","裴","鄞","留","卜","覃","喻","項","焦","滕","商","買","虞","車","戚","苗","李黃","牟","臧","陳許","力","樂","黃吳","雲","張李","樓","費","艾","屈","司","巴","尚","宗","桂","王李","靳","諶","欒","衛","宮","祁","路","刁","幸","沙","李王","蔡黃","時","劉黃","柴","劉張","瞿","談","隋","竇","柏","鄺","霍","閔","查","周黃","冉","遲","仲","吉","仇","鄂","儲","松","東","湛","榮","匡","冷","風","婁","蘇陳","昌","裘","龐","卞","謝林","晏","桑","邱黃","甯","初","張楊","席","岑","叢","朱陳","邊","姬","郁","偕","兵","曾林","區","屠","徐陳","蒙","蘭","郎","勞","張廖","聞","佟","鞠","景","張許","奚","甄","明","厲","陳呂","米","荊","卯","江謝","郭黃","機","伊","原","封","盤","才","乾","翁林","鄭黃","錡","郭李","粟","標","容","宣","王劉","宜","皮","鄢","黨","候","茅","竺","藺","敖","蓋","司徒","寇","洗","南","於","芮","惠","苑","危","嵇","禹","婿","諸","狄","枋","杞","師","吳鄭","逄","釋","烏","修","楚","岩","貝","鹿","哀","農","浦","欉","姜林","城","戎","葉劉","忻","豐","那","滿","強","覺","闞","帥","劉許","戰","濮","都","晁","燕","洪許","郜"]
    
    func setInsCompany(_ oriInsCompany:InsuranceCompany){
        switch oriInsCompany {
        case .幸福:
            insCompany = "幸福人壽 (轉)國泰人壽"
        case .大都會:
            insCompany = "大都會人壽 (轉)中國信託人壽"
        case .遠雄:
            insCompany = "遠雄人壽保險股份有限公司"
        case .富邦:
            insCompany = "富邦人壽保險股份有限公司"
        case .全球:
            insCompany = "全球人壽保險股份有限公司"
        case .中興:
            insCompany = "中興人壽 (轉)遠雄人壽"
        case .保誠:
            insCompany = "保誠人壽保險股份有限公司"
        case .國寶:
            insCompany = "國寶人壽 (轉)國泰人壽"
        case .南山:
            insCompany = "南山人壽保險保險股份有限公司"
        case .臺銀:
            insCompany = "臺銀人壽保險保險股份有限公司"
        case .台灣人壽:
            insCompany = "台灣人壽保險保險股份有限公司"
        case .國泰:
            insCompany = "國泰人壽保險保險股份有限公司"
        case .中國人壽:
            insCompany = "中國人壽保險保險股份有限公司"
        case .新光:
            insCompany = "新光人壽保險保險股份有限公司"
        case .三商美邦:
            insCompany = "三商美邦人壽保險保險股份有限公司"
        case .宏泰:
            insCompany = "宏泰人壽保險保險股份有限公司"
        case .安聯:
            insCompany = "安聯人壽保險保險股份有限公司"
        case .中華郵政:
            insCompany = "中華郵政股份有限公司壽險處"
        case .保德信:
            insCompany = "保德信國際人壽保險股份有限公司"
        case .元大:
            insCompany = "元大人壽保險保險股份有限公司"
        case .第一金:
            insCompany = "第一金人壽保險保險股份有限公司"
        case .合作金庫:
            insCompany = "合作金庫人壽保險保險股份有限公司"
        case .康健:
            insCompany = "國際康健人壽保險保險股份有限公司"
        case .友邦:
            insCompany = "友邦保險控股有限公司"
        case .巴黎:
            insCompany = "法商法國巴黎人壽保險股份有限公司台灣分公司"
        case .安達:
            insCompany = "英屬百慕達商安達人壽保險股份有限公司台灣分公司"
        case .蘇黎世:
            insCompany = "英屬曼島商蘇黎世國際人壽保險股份有限公司台灣分公司"
        }
    }
}

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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
public struct InsOriginalInfo: Content {
    var text: String
}
enum InsuranceCompany:String {
    
    case 幸福 = "幸福"
    case 大都會 = "大都會"
    case 遠雄 = "遠雄"
    case 富邦 = "富邦"
    case 全球 = "全球"
    case 中興 = "中興"
    case 保誠 = "保誠"
    case 國寶 = "國寶"
    case 南山 = "南山"
    case 臺銀 = "台銀"
    case 台灣人壽 = "台灣人壽"
    case 國泰 = "國泰"
    case 中國人壽 = "中國人壽"
    case 新光 = "新光"
    case 三商美邦 = "三商美邦"
    case 宏泰 = "宏泰"
    case 安聯 = "安聯"
    case 中華郵政 = "中華郵政"
    case 保德信 = "保德信"
    case 元大 = "元大"
    case 第一金 = "第一金"
    case 合作金庫 = "合作金庫"
    case 康健 = "康健"
    case 友邦 = "友邦"
    case 巴黎 = "巴黎"
    case 安達 = "安達"
    case 蘇黎世 = "蘇黎世"
    
    
    static let allValues = [幸福,大都會,遠雄,富邦,全球,中興,保誠,國寶,南山,臺銀,台灣人壽,國泰,中國人壽,新光,三商美邦,宏泰,安聯,中華郵政,保德信,元大,第一金,合作金庫,康健,友邦,巴黎,安達,蘇黎世]
}
