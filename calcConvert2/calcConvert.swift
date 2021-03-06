//
//  calcConvert.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/21.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import Foundation

class userPreference {

}


class calcConvert {

    //*****計算機的部份*****
    var valBuffer:Double=0    //保存前數值
    var valMemory:Double=0    //m記憶值
    var opBuffer:String=""    //保存前運算子
    var txtBuffer:String=""   //組字當中的數字，empty表示重新開始組字
    var digBuffer:Double=0    //組字結果的值
    var prevInputedKey:String=""   //保存前次輸入運算子或運算元

    var pastBoard:String="" //複製貼上的暫存區

    var valueOutput:String="0"          //輸出計算結果valBuffer or digBuffer
    var memoryOutput:String=""          //輸出valMemory
    var categoryTitle=""                //目前度量種類的標題

    var historySwitch:Bool=false        //是否顯示計算歷程
    var historyText:String=""           //計算歷程的內容
//    var prevHistoryText:String=""       //前次要放入historyText的紀錄內容

    var precisionForOutput:String="9"               //輸出欄使用的精度
    let precisionForHistory:String="7"              //計算歷程使用的精度
    let precisionForHistoryLong:String="10"         //調整小數位後於historyText用較長精度顯示

    var rounding:Bool=false             //計算時是否四捨五入
    var roundingDisplay:Bool=false      //限制顯示時的小數位數
    var decimalScale:Double = 4         //四捨五入的小數位
    var roundingScale:Double=10000.0    //四捨五入的小數位,10000是4位數

    var defaults:UserDefaults
    let keyRounding:String          = "keyRounding"
    let keyRoundingDisplay:String   = "keyRoundingDisplay"
    let keyDecimalScale:String      = "keyDecimalScale"
    let keyshowPriceConvert:String  = "keyshowPriceConvert"
    let keyPriceConverting:String   = "keyPriceConverting"
    let keyHistorySwitch:String     = "keyHistorySwitch"
    let keyPreferenceUpdated:String = "keyPreferenceUpdated"



    init () {

        defaults = UserDefaults.standard


        //建立轉換係數等陣列，後續查詢匯率成功時，還會加入匯率係數，不成功就維持初始狀態
        convertX = convertXList
        category = categoryList
        unit = unitList
        exchangeRate = initRate
        backupRate = initRate
        loadExchangeRate()
        getUserPreference ()
    }

    func getUserPreference () {
        if let _ = defaults.object(forKey: keyPreferenceUpdated) {
            let ci = defaults.integer(forKey: "categoryIndex")
            let _ = self.setCategory(withCategory: ci)

            self.setRounding(withScale: defaults.double (forKey: keyDecimalScale), roundingDisplay: defaults.bool(forKey: keyRoundingDisplay), roundingCalculation: defaults.bool(forKey: keyRounding))
            let _ = self.showPriceConvertButton(withSwitch: defaults.bool(forKey: keyshowPriceConvert))
            self.setHistorySwitch(withSwitch: defaults.bool(forKey: keyHistorySwitch))
        } else {
            self.setRounding(withScale: 4, roundingDisplay: false, roundingCalculation: false)
            let _ = self.showPriceConvertButton(withSwitch: false)
            self.setHistorySwitch(withSwitch: false)
        }
    }

    func keyIn (_ inputedKey: String) -> String {
        //組字及運算：valBuffer得到值之後，就把組字中txtBuffer清為empty，並輸出valBuffer
        //如果收到的字是=開頭的數值，則直接帶入數值當作結果
        //如果收到的是其他如empty，則有txtBuffer就輸出txtBuffer，沒有就重新輸出valBuffer

        updateIfScaling ()  //檢查是否有用手指移動入捨小數位，有的話要先更新入捨後的結果值，再繼續運算

        switch inputedKey {
        case "[C]":
            if valBuffer==0 && txtBuffer==""{
                valMemory=0
                historyText = (priceConverting ? "@" : "") + unit[categoryIndex][unitIndex]+": "
            } else {
                historyText += txtBuffer + " " + inputedKey + " "
            }
            valBuffer=0
            opBuffer=""
            txtBuffer=""
            prevInputedKey = inputedKey
        case "[mc]":
            valMemory = 0
            historyText+=inputedKey
            prevInputedKey = inputedKey
        case "+","-","x","/","=","[m+]","[m-]","[cr]","[sr]":
            //如果四則運算子沒有輸入運算元，又連續接運算子，應消除無意義的連續運算子
            if (prevInputedKey == "+" || prevInputedKey == "-" || prevInputedKey == "x" || prevInputedKey == "/") {
                let index = historyText.index(historyText.endIndex, offsetBy: -1)
                historyText = String(historyText[..<index]) 
                //就消除乘0或除0的情形
                digBuffer = (opBuffer == "x" || opBuffer == "/" ? 1 : 0)
           }

            //這幾個運算子將結束組字並做運算；CR立方根、SR平方根、"→"是度量轉換但在unitConvert()已經處理了
            //之前有op則先拿來和現在剛輸入的數值做運算
            if txtBuffer != "" {
                historyText+=String(format:"%."+precisionForHistory+"g",(roundingDisplay ? round(digBuffer*roundingScale)/roundingScale : digBuffer))
            }
            switch opBuffer {
            case "+":
                valBuffer=(rounding ? round((valBuffer+digBuffer)*roundingScale)/roundingScale : valBuffer+digBuffer)
            case "-":
                valBuffer=(rounding ? round((valBuffer-digBuffer)*roundingScale)/roundingScale : valBuffer-digBuffer)
            case "x":
                valBuffer=(rounding ? round((valBuffer*digBuffer)*roundingScale)/roundingScale : valBuffer*digBuffer)
            case "/":
                valBuffer=(rounding ? round((valBuffer/digBuffer)*roundingScale)/roundingScale : valBuffer/digBuffer)
            case "=":
                break
            case "[m+]","[m-]","[cr]","[sr]":
                if digBuffer != 0 {     //開根後組字中又開根，應拿組字中的值來開而不是上次開根結果來開
                    valBuffer=(rounding ? round(digBuffer*roundingScale)/roundingScale : digBuffer)
                }
            default:
                //包括第一次沒有前運算子時，把組字結果做值輸出
                if txtBuffer != "" {
                    valBuffer=(rounding ? round(digBuffer*roundingScale)/roundingScale : digBuffer)
                }

            }
            if inputedKey != "=" || (opBuffer != "=" && opBuffer != "[cr]" && opBuffer != "[sr]" && opBuffer != "[m+]" && opBuffer != "[m-]" && opBuffer != "" && opBuffer != "→") {
                //抑制無效的=出現。哪些是無效的=，即之前opBuffer不是=,CR,SR,[m+],[m-]等會導致輸出結果的運算子
                historyText += (inputedKey == "=" && roundingDisplay && round(valBuffer*roundingScale)/roundingScale != valBuffer ? "≒" : inputedKey)
            }
            switch inputedKey {
            case "[m+]","[m-]","[cr]","[sr]","=":
                 switch inputedKey {
                    case "[m+]":
                        valMemory=(rounding ? round((valMemory+valBuffer)*roundingScale)/roundingScale : valMemory+valBuffer)
                    case "[m-]":
                        valMemory=(rounding ? round((valMemory-valBuffer)*roundingScale)/roundingScale : valMemory-valBuffer)
                    case "[cr]":
                        valBuffer=(rounding ? round(cbrt(valBuffer)*roundingScale)/roundingScale : cbrt(valBuffer))
                    case "[sr]":
                        valBuffer=(rounding ? round(sqrt(valBuffer)*roundingScale)/roundingScale : sqrt(valBuffer))
                    default:
                        break
                }
                //這些運算子會導致輸出結果，所以要提示運算結果，並冠空白表示段落。同前要抑制無效等號所產生的結果。
                if inputedKey != "=" || (opBuffer != "=" && opBuffer != "[cr]" && opBuffer != "[sr]" && opBuffer != "[m+]" && opBuffer != "[m-]" && opBuffer != "" && opBuffer != "→") {
//                    if inputedKey == "[cr]" || inputedKey == "[sr]" {
//                        historyText += "="
//                    }
                    historyText += " " + String(format:"%."+precisionForHistory+"g",(roundingDisplay ? round(valBuffer*roundingScale)/roundingScale : valBuffer)) + " "
                }
           default:
                break
            }

            txtBuffer = ""
            digBuffer = 0
            opBuffer = inputedKey
            prevInputedKey = inputedKey

        case "0","1","2","3","4","5","6","7","8","9",".","[mr]","[貼上]":
            //如果之前已按=,m+,m-,CR,SR等結束運算，之後沒有按運算子就開始組數字，則前數值應放棄歸零，且前運算子也清除為初始狀態
            switch opBuffer {
            case "[m+]","[m-]","[cr]","[sr]","=","→":    //度量轉換時，opBuffer是"→"
                historyText += (valBuffer != 0 || ((opBuffer == "=" || opBuffer == "[m+]" || opBuffer == "[m-]") && (opBuffer != "→" )) ? ", " : "") //此時分段落，以增加可讀性
                //條件 valBuffer != 0 剛好valBuffer計算後是0 卻不能顯示逗號
                //條件 valBuffer != 0 && digBuffer == 0 剛好valBuffer計算後是0 換單位時是空白接逗號，所以加opBuffer != "→"條件
                //條件 (valBuffer != 0 && digBuffer == 0) && (opBuffer != "→" ) 組字中換category已用＝得值，再接著組字卻沒有逗號
                //條件 (valBuffer != 0 && digBuffer == 0) && (opBuffer != "→" || valBuffer != 0) 打0按=後，再接著組新字卻沒有逗號
                //條件 (valBuffer != 0 || opBuffer == "=" || opBuffer == "[m+]" || opBuffer == "[m-]") && (opBuffer != "→" || valBuffer != 0)
                valBuffer=0
                opBuffer=""
            default:
                break
            }
            if inputedKey=="[mr]" || inputedKey=="[貼上]"{
                //mr等於重新組字，但要等組字完成才提示mr的數值
                historyText += txtBuffer + " " + inputedKey + " "
                if inputedKey=="[mr]" {
                    txtBuffer=String(format:"%."+precisionForOutput+"g",valMemory)
                    digBuffer=(rounding ? round(valMemory*roundingScale)/roundingScale : valMemory)
                } else {
                    if let valPastBoard = Double(pastBoard) {
                        txtBuffer=String(format:"%."+precisionForOutput+"g",valPastBoard)
                        digBuffer=(rounding ? round(valPastBoard*roundingScale)/roundingScale : valPastBoard)
                    } else {
                        txtBuffer="0"
                        digBuffer=0
                    }
                }

            } else {
                if txtBuffer == "0" && inputedKey != "." { txtBuffer="" } //如果組數字時已有前導零，又不是組小數，則清除前導零
                if txtBuffer == ""  && inputedKey == "." { txtBuffer="0"} //如果組字是初始empty又接小數點，則補前導零
                if txtBuffer.contains(".") && inputedKey=="." {
                    break   //重複小數點就忽略
                } else {
                    txtBuffer=txtBuffer+inputedKey  //最後把組字接上去
                    if let _=Double(txtBuffer) {
                        digBuffer=Double(txtBuffer)!    //取得組字結果值，user輸入的數值不作四捨五入
                    } else {
                        digBuffer=0
                    }               }
            }
            prevInputedKey = txtBuffer
        default:
            //只有一種特殊情形是傳入按鍵外的資料，即傳入=後接數值，則將數值帶入保存 (度量單位改變時帶入換算結果）
            if inputedKey.range(of: "=") != nil {
                let inputedValue=inputedKey.replacingOccurrences(of: "=", with: "") //去掉等號
                if let _=Double(inputedValue) {
                    valBuffer=Double(inputedValue)!
                } else {
                    valBuffer=0
                }
                txtBuffer=""
                digBuffer=0
            }
            //如果是其他情形，如empty，這裡就是什麼都不做，則相當於把txtBuffer或valBuffer重新輸出，例如為了更新畫面數值的精度時
             opBuffer = ""
        }

        prepareDisplayOutput ()

        return historyText

    }

    func prepareDisplayOutput () {
        //顯示計算結果
        if let _ = scalingValue {
            valueOutput = scalingOutput!
        } else {
            if self.txtBuffer == "" {
                valueOutput = String(format:"%."+precisionForOutput+"g",(roundingDisplay ? round(valBuffer*roundingScale)/roundingScale : valBuffer))
            } else {
                if opBuffer == "[mr]" || opBuffer == "[貼上]" {
                    valueOutput = String(format:"%."+precisionForOutput+"g",(roundingDisplay ? round(digBuffer*roundingScale)/roundingScale : digBuffer)) //不使用txtBuffer因為mr後txtBuffer精度不準
                } else {
                    valueOutput = txtBuffer
                }
            }
        }
        //顯示暫存值
        if self.valMemory == 0 {
            memoryOutput = ""
        } else {
            memoryOutput = "m = " + String(format:"%."+precisionForOutput+"g",(roundingDisplay ? round(valMemory*roundingScale)/roundingScale : valMemory))
        }

    }



    func setPrecisionForOutput (withPrecision precision: String) {
        precisionForOutput = precision
        prepareDisplayOutput ()
    }

    func setRounding (withScale scale:Double, roundingDisplay:Bool, roundingCalculation:Bool) {
        self.decimalScale = scale
        self.roundingScale = pow (10.0, scale)
        self.rounding = roundingCalculation
        self.roundingDisplay = roundingDisplay
        prepareDisplayOutput ()

        defaults.set(rounding, forKey: keyRounding)
        defaults.set(roundingDisplay, forKey: keyRoundingDisplay)
        defaults.set(decimalScale, forKey: keyDecimalScale)
        defaults.set(Date(), forKey: keyPreferenceUpdated)
    }




    //***** 用手指變動小數位數 *****
    var scalingValue:Double?    //用手指變動小數位數的暫存值
    var originValue:Double?     //原始數值
    var scalingOutput:String?   //scalingValue的輸出，要負責在不足位數補零以容易辨識目前調到幾位

    func startScaling () -> (Int, Int) {
        originValue = ( txtBuffer == "" ? valBuffer : digBuffer)
        if scalingValue == nil {
            scalingValue = originValue
        }
        let factor:(originScale:Int,movingScale:Int) = (decimalScale(originValue!),decimalScale(scalingValue!))
        if factor.originScale == 0 {
            scalingValue = nil  //小數位數本來就是零，不做了
            originValue = nil
        }
        return factor   //不做時，手指頭移動還是觸動位移計算，但不會叫onScaling()，也不會就不會在historyText寫[≒]
    }

    func onScaling (_ factor: Int) {
         if factor == 0 {
            scalingValue = round(originValue!)  //小數位＝0時....其實10的0次方得1也行，不過多算1次多1次誤差
            scalingOutput = String(format:"%."+precisionForOutput+"g", scalingValue!)
         } else {
            let scale = pow(10,Double(factor))
            scalingValue = round(originValue! * scale) / scale
            scalingOutput = String(format:"%."+precisionForOutput+"g", scalingValue!)
            let scalingFactor = decimalScale(scalingValue!)
            if scalingFactor < factor {
                if let _ = scalingOutput!.range(of: ".") {
                    scalingOutput = scalingOutput! + String(repeating: "0", count: (factor - scalingFactor))
                } else {
                    scalingOutput = scalingOutput! + "." + String(repeating: "0", count: (factor - scalingFactor))
                }
            }
        }
        prepareDisplayOutput ()

    }

    func updateIfScaling () {
        if let _ = scalingValue {
            if txtBuffer == "" {    //如果位數沒變，給原始值，避免暫存值因為旋轉機體導致精度變動而失真，historyText並用長精度顯示
                valBuffer = (decimalScale(scalingValue!) == decimalScale(originValue!) ? originValue! : scalingValue!)
                historyText += "[≒] " + String(format:"%."+precisionForHistoryLong+"g",(roundingDisplay ? round(valBuffer*roundingScale)/roundingScale : valBuffer))
            } else {
                digBuffer = (decimalScale(scalingValue!) == decimalScale(originValue!) ? originValue! : scalingValue!)
            }
            scalingValue = nil
            originValue = nil
        }
    }


    func decimalScale (_ d:Double) -> Int {   //回傳double的小數位數，用於手指操作進位時
        var scale:Int = 0
        let s:String = String(format:"%."+precisionForOutput+"g",d)
        if let p = s.range(of: ".")?.lowerBound {
            let pIdx = s.index(p, offsetBy: 1)
            scale = s[pIdx...].count    //s.substring(from: pi).count
//        } else if let _ = s.range(of: "e+")?.lowerBound {
//            scale = 0
//        } else if let _ = s.range(of: "e-")?.lowerBound {
//            scale = 0
//        } else {
//            scale = 0
        }
//        let pIndex = s.index((s.range(of: ".")?.lowerBound), offsetBy: 1)
//        let ePlus  = s.index((s.range(of: "e+")?.lowerBound), offsetBy: 2)
//        let eMinus = s.index((s.range(of: "e-")?.lowerBound), offsetBy: 2)
//        if  let _ = ePlus {
//            scale = 0
//        } else if let _ = eMinus {
//            scale = Int(s.substring(from: eMinus))!
//        } else if let _ = pIndex {
//                scale = s.substring(from: pIndex).characters.count
//        } else {
//            scale = 0
//        }
        return scale
    }







    //*****度量衡轉換的部份*****
    var categoryIndex:Int = 0           //目前度量種類
    var unitIndex:Int = 0               //保留前單位
    var priceConverting:Bool=false      //單價換算是否啟動
    var showPriceConvertButton:Bool=true     //是否隱藏單價換算開關


    //度量種類
    var category:([String]) = []          //在init()會塞入categoryList這個陣列，之後取得匯率時再加入currencyCategory
    let categoryList:([String]) =  ["重量","長度","面積"]
    let currencyCategory:([String])=["貨幣"]


    //單位
    var unit:([[String]]) = []           //在init()會塞入unitList這個陣列，之後取得匯率時再加入currencyList
    var unitList:([[String]]) =  [
            ["公克","公斤","台斤","台兩","英磅","盎司"],        // 重量
            ["公尺","公分","台尺","台寸","英尺","英寸"],        // 長度
            ["台坪","台畝","台分","台甲","平方公尺","公頃","平方英尺"]    // 面積
        ]
    let currencyList:([[String]]) = [["台幣","美元","日圓","歐元","英鎊","越南盾","港幣","韓元","人民幣"]]
    let currencyCode:([String]) = ["TWD","USD","JPY","EUR","GBP","VND","HKD","KRW","CNY"] //這是Yahoo的查詢代碼
    var queryTime:Date?     //查詢當中的時間
    var currencyTime:Date?  //最後成功取得全部匯率的時間

    //轉換係數：為了增加精度所以使用雙係數。例如3公斤=5台斤，則2公斤=2*5/3台斤。
    //這是3維陣列：[度量種類][原單位][新單位]
    let convertXList:([[[(Double,Double)]]]) = [
        //重量
        [   //  公克              公斤              台斤             台兩            磅             盎司
            [(1.0,1.0),         (1.0,1000.0),   (5.0,3000.0),(8.0,300.0),(1.0,453.59237), (16.0,453.59237)],  // 公克 3000公克=5台斤=80台兩
            [(1000.0,1.0),      (1.0,1.0),      (5.0,3.0),   (80.0,3.0), (1.0,0.45359237),(16.0,0.45359237)],   // 公斤 3公斤=5台斤
            [(3000.0,5.0),      (3.0,5.0),      (1.0,1.0),   (16.0,1.0), (3.0,2.26796185),  (48.0,2.26796185)],// 台斤 1台斤=16台兩=(3/2.26796185)磅
            [(300.0,8.0),       (3.0,80.0),     (1.0,16.0),  (1.0,1.0),  (3.0,36.2873896), (48.0,36.2873896)], // 台兩 1台兩=(3/2.26796185*16)磅=(3/36.2873896)磅
            [(453.59237,1.0),  (0.45359237,1.0),(2.26796185,3.0),(36.2873896,3.0),(1.0,1.0), (16.0,1.0)],      // 磅 1磅=453.59237公克=16盎司=(453.59237*5)/3000台斤=(2.26796185/3)台斤
            [(453.59237,16.0), (0.45359237,16.0),(2.26796185,48.0),(36.2873896,48.0),(1.0,16.0), (1.0,1.0)]    // 盎司
        ],

        //長度
        [   //   公尺         公分          台尺		       台寸             英呎		     英吋
            [(1.0,  1.0),(100.0,  1.0),(33.0, 10.0),  (330.0, 10.0),  (100.0, 30.48),(100.0, 2.54)],    // 公尺 10公尺=33台尺
            [(1.0,100.0),(1.0,    1.0),(33.0,1000.0), (330.0,1000.0), (1.0,30.48),   (1.0,2.54)],       // 公分
            [(10.0,33.0),(1000.0,33.0),(1.0, 1.0),    (10.0, 1.0),    (1.0, 1.00584),(12.0, 1.00584)],  // 台尺 1005.84台尺=1000英呎=304.8公尺=304.8*3.3台尺
            [(10.0,330.0),(1000.0,330.0),(1.0, 10.0), (1.0, 1.0),     (1.0, 10.0584),(12.0, 10.0584)],  // 台寸 1台尺=10台寸
            [(30.48,100.0),(30.48,1.0),(1.00584, 1.0),(10.0584, 1.0), (1.0, 1.0),    (12.0, 1.0)],      // 英呎 1英呎=30.48公分=12英吋
            [(2.54,100.0), (2.54,1.0), (1.00584, 12.0),(10.0584, 12.0),(1.0, 12.0),  (1.0, 1.0)]        // 英吋
        ],

//        //面積
//        [   // 平方公尺             平方英尺         坪
//            [(1.0,1.0),       (100.0,9.290304),(121.0,400.0)],      //平方公尺 400平方公尺=121坪
//            [(9.290304,100.0),(1.0,1.0),       (11.241268,400.0)],  //平方英尺 100平方英尺=9.290304平方公尺
//            [(400.0,121.0),(400.0,11.241268),  (1.0,1.0)]           //坪 11.241268坪=400平方英尺
//        ]
//        //面積
//        [   //   坪                平方公尺          平方英尺
//            [(1.0,1.0),        (400.0,121.0),(400.0,11.241268),],   //坪 11.241268坪=400平方英尺
//            [(121.0,400.0),    (1.0,1.0),       (100.0,9.290304)],  //平方公尺 400平方公尺=121坪
//            [(11.241268,400.0),(9.290304,100.0),(1.0,1.0)]          //平方英尺 100平方英尺=9.290304平方公尺
//        ]
        //面積：坪、畝、分、甲、平方公尺、公頃、平方英尺
        [   //   坪             畝           分         甲           平方公尺          公頃         平方英尺
            [(1.0,1.0),     (1.0,30.0),(1.0,293.4),(1.0,2934.0),(400.0,121.0),  (0.04,121.0),(400.0,11.241268),],     //坪 11.241268坪=400平方英尺
            [(30.0,1.0),    (1.0,1.0), (1.0,9.78), (1.0,97.8),  (12000.0,121.0),(1.2,121.0), (12000,11.241268)],  //畝 1畝=30坪=(30*400/11.241268)平方英尺, 121畝=12000平方公尺=1.2公頃
            [(293.4,1.0),   (9.78,1.0),(1.0,1.0),  (1.0,10.0),  (117360,121), (11.736,121),(117360.0,11.2412678)],      //分 1分=9.78畝, 112412.678畝=(12000*9.78)平方英尺=117360平方英尺
            [(2934,1.0),    (97.8,1.0),(10.0,1.0), (1.0,1.0),   (1173600,121),   (117.36,121), (117360.0,1.12412678)],  //甲 1甲=10分=97.8畝,(121/97.8)甲=1.2頃,121甲=117.36頃
            [(121.0,400),(121.0,12000),(121,117360),(121,1173600),(1.0,1.0),  (1.0,10000), (100.0,9.290304)],    //平方公尺 400平方公尺=121坪
            [(121.0,0.04), (121.0,1.2),(121,11.736),(121,117.36),(10000,1.0),    (1.0,1.0),   (1000000,9.290304)],  //公頃 10000平方公尺=1頃,1000000平方英尺=92903.04平方公尺=9.290304公頃
            [(11.241268,400.0),(11.241268,12000),(11.2412678,117360),(1.12412678,117360),(9.290304,100),(9.290304,1000000),(1.0,1.0)]  //平方英尺 100平方英尺=9.290304平方公尺
        ]
    ]
    var convertX:([[[(Double,Double)]]]) = []    //在init()會塞入convertXList這個大陣列，之後取得匯率時再加入exchangeRate這個陣列
    var initRate:([[[(Double,Double)]]]) = [[
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)]
    ]]
    var exchangeRate:([[[(Double,Double)]]]) = []   //在查詢時帶入initRate，因為台灣銀行的匯率係數和Yahoo!顛倒，所以查詢時要重置
    var backupRate:([[[(Double,Double)]]]) = []     //Yahoo!查詢時會破壞exchangeRate所以先保存起來，失敗時復原




    func setCategory (withCategory categoryIndex: Int) ->String {
        let _ = self.keyIn("=") //先取得計算機的結果
        self.categoryIndex = categoryIndex
        categoryTitle = category[categoryIndex] + (priceConverting ? "，單價換算＄" : "")
        defaults.set(categoryIndex, forKey: "categoryIndex")
        defaults.set(Date(), forKey: keyPreferenceUpdated)
        return changeUnit (withUnit: 0)
    }

    func showPriceConvertButton (withSwitch show:Bool) ->String {
        showPriceConvertButton = show
        defaults.set(showPriceConvertButton, forKey: keyshowPriceConvert)
        defaults.set(Date(), forKey: keyPreferenceUpdated)
        return setPriceConverting(withSwitch: (show ? defaults.bool(forKey: keyPriceConverting) : false)) //如果不顯示開關，也要關閉單價換算為OFF

    }

    func setPriceConverting (withSwitch priceConverting: Bool) ->String {
        self.priceConverting = priceConverting
        defaults.set(priceConverting, forKey: keyPriceConverting)
        defaults.set(Date(), forKey: keyPreferenceUpdated)
        categoryTitle = category[categoryIndex] + (priceConverting ? "，單價換算＄" : "")
        return changeUnitInHistoryText ()
    }

    func changeUnit (withUnit unitIndex: Int) ->String {
        opBuffer = "→"  //代表這次不是加減乘除，是度量轉換
        self.unitIndex = unitIndex
        return changeUnitInHistoryText ()
    }

    func setHistorySwitch (withSwitch historySwitch: Bool) {
        self.historySwitch = historySwitch
        defaults.set(historySwitch, forKey: keyHistorySwitch)
        defaults.set(Date(), forKey: keyPreferenceUpdated)
    }




    func changeUnitInHistoryText () ->String {
        //變換度量單位時輸出：[@]<單位名稱>：[目前數值][前運算子] opBuffer代表剛開始沒有前運算子則不輸出0；前運算子是"→"也要抑制
        let text = (opBuffer == "" || historyText == "" ? "" : " ") + (priceConverting ? "@" : "") + unit[categoryIndex][unitIndex] + ": " + (valBuffer == 0 ? "" :String(format:"%."+precisionForHistory+"g",(roundingDisplay ? round(valBuffer*roundingScale)/roundingScale : valBuffer))) + (txtBuffer == "" || opBuffer == "→" ? "" : opBuffer)

        //初始時，setCategory和setPriceConverting會重複叫changeUnitInHistoryText，則不要重複給相同單位名稱
        if text != " " + historyText {
            historyText += text
        }
        return self.historyText
    }



    func unitConvert (_ unitIndexTo:Int) -> String {
        var output:Double=0
        let factor0=convertX[categoryIndex][unitIndex][unitIndexTo].0
        let factor1=convertX[categoryIndex][unitIndex][unitIndexTo].1
        let _ = self.keyIn("=") //先取得計算機的結果
        if priceConverting {
            output = (rounding ? round((valBuffer * factor1 / factor0)*roundingScale)/roundingScale : valBuffer * factor1 / factor0)    //單價換算時，轉換係數的分子分母顛倒
        } else {
            output = (rounding ? round((valBuffer * factor0 / factor1)*roundingScale)/roundingScale : valBuffer * factor0 / factor1)
        }

        //轉換的提示以箭頭符號開始，然後提示轉換後的數值和單位
        if output != 0 {
            historyText += "→"
        }

        valBuffer=output

        prepareDisplayOutput()

        return self.changeUnit(withUnit: unitIndexTo)

     }

    var rateSource:String = ""  //查詢的資料來源，台灣銀行或Yahoo!


    func loadExchangeRate() {
        if let dt = defaults.object(forKey: "currencyTime") {
            currencyTime    = dt as? Date
            rateSource      = defaults.string(forKey: "rateSource")!
            if let e = defaults.object(forKey: "exchangeRate")  {
                let ex = e as! [[[[Double]]]]
                var rx:[[[(Double,Double)]]]=[]
                for r1 in ex {
                    var r1x:[[(Double,Double)]]=[]
                    for r2 in r1 {
                        var r2x:[(Double,Double)]=[]
                        for r3 in r2 {
                            r2x.append((r3[0],r3[1]))
                        }
                        r1x.append(r2x)
                    }
                    rx.append(r1x)
                }
                self.exchangeRate = rx
                self.convertX = self.convertXList + self.exchangeRate
                self.unit = self.unitList + self.currencyList
                self.category = self.categoryList + self.currencyCategory
            }
        }
    }

    func saveExchangeRate() {
        if let _ = currencyTime {
            var ex:[[[[Double]]]] = []
            for r1 in exchangeRate {
                var r1x:[[[Double]]] = []
                for r2 in r1 {
                    var r2x:[[Double]]=[]
                    for r3 in r2 {
                        r2x.append([r3.0,r3.1])
                    }
                    r1x.append(r2x)
                }
                ex.append(r1x)
            }
            defaults.setValue(ex, forKey: "exchangeRate")
            defaults.setValue(currencyTime, forKey: "currencyTime")
            defaults.setValue(rateSource, forKey: "rateSource")
            self.convertX = self.convertXList + self.exchangeRate
            self.unit = self.unitList + self.currencyList
            self.category = self.categoryList + self.currencyCategory
        }

    }

    func getExchangeRate () {
        if let _ = currencyTime {
            if currencyTime!.timeIntervalSinceNow < -1800 {
                botQuery()  //上次查詢超過30分鐘再重新查詢匯率
            }
        } else  {
            botQuery()  //還沒成功查過就重試查詢匯率
        }
    }


    //查詢台灣銀行匯率

    func botQuery () {
        self.queryTime = nil
        let url = URL(string: "http://rate.bot.com.tw/Pages/Static/UIP003.zh-TW.htm");
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            if error == nil {
                if let downloadedData = String(data: data!, encoding: String.Encoding.utf8) {
                    let leading = "最新掛牌時間：<span class=\"time\">"
                    let trailing = "</span>"
                    if let range = downloadedData.range(of: "\(leading)(.+)\(trailing)", options: .regularExpression) {
                        let startIndex = downloadedData.index(range.lowerBound, offsetBy: leading.count)
                        let endIndex   = downloadedData.index(range.upperBound, offsetBy: 0-trailing.count)
                        let dTime = String(downloadedData[startIndex..<endIndex])
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale=Locale(identifier: "zh_TW")
                        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm zzz"
                        if let dt = dateFormatter.date(from: dTime+" GMT+8") {
                            self.queryTime = dt
                            self.botQueryText ()
                        }

                    }
                }
            }
            if self.queryTime == nil {
                self.yahooQuery()
            } else {
                self.currencyTime = self.queryTime
                self.rateSource = "台灣銀行"    //未超過2小時就繼續用台灣銀行的數字
//                if (0 - (self.currencyTime!.timeIntervalSinceNow / 60)) > 120 {
//                    self.yahooQuery()  //台灣銀行掛牌時間超過2小時再重新查詢Yahoo!匯率
//                }
            }
        })
        task.resume()
        
    }


    func botQueryText () {

        let url = URL(string: "http://rate.bot.com.tw/xrt/fltxt/0/day");
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
            if error == nil {
                if let downloadedData = String(data: data!, encoding: String.Encoding.utf8) {
                    self.exchangeRate = self.initRate
                    for (indexFrom,_) in self.currencyCode.enumerated() {
                        for (indexTo,currencyTo) in self.currencyCode.enumerated() {
                            if indexFrom < indexTo {    //只查一半的表格，另一半就是係數顛倒，所以直接填入
                                if indexFrom == 0 {
                                    self.exchangeRate[0][indexFrom][indexTo].1 = self.botRate(downloadedData,currency: currencyTo).spotSelling
                                    self.exchangeRate[0][indexTo][indexFrom].0 = self.exchangeRate[0][indexFrom][indexTo].1
                                } else {
                                    self.exchangeRate[0][indexFrom][indexTo].1 = self.exchangeRate[0][0][indexTo].1   //以下皆以對台幣的價格帶入，以維持換算係數的一致
                                    self.exchangeRate[0][indexFrom][indexTo].0 = self.exchangeRate[0][0][indexFrom].1
                                    self.exchangeRate[0][indexTo][indexFrom].1 = self.exchangeRate[0][0][indexFrom].1
                                    self.exchangeRate[0][indexTo][indexFrom].0 = self.exchangeRate[0][0][indexTo].1

                               }
                            }
                            
                        }
                    }

                    self.saveExchangeRate()


                }
            }
        })
        task.resume()

    }

    func botRate (_ data:String,currency:String) -> (cashBuying:Double,cashSelling:Double,spotBuying:Double,spotSelling:Double) {
        var cashBuying:Double   = 0
        var cashSelling:Double  = 0
        var spotBuying:Double   = 0
        var spotSelling:Double  = 0
        var buying:String  = "本行買入"
        var selling:String = "本行賣出"
        if data.contains("Currency") {
            buying  = "Buying"
            selling = "Selling"
        }
        let leading = "\(currency)         \(buying)"
        let trailing = "\r"
        if let range=data.range(of: "\(leading)(.+)\(trailing)", options: .regularExpression) {
            let startIndex = data.index(range.lowerBound, offsetBy: leading.count)
            let endIndex = data.index(range.upperBound, offsetBy: 0-trailing.count)
            let data1 = String(data[startIndex..<endIndex])    //data.substring(with: range).replacingOccurrences(of: currency+"         \(buying)", with: "")
//            let data2 = data1.replacingOccurrences(of: "\r", with: "")
            let data3 = data1.replacingOccurrences(of: selling, with: "")
            let data4 = data3.replacingOccurrences(of: "    ", with: " ")
            let data5 = data4.replacingOccurrences(of: "  ", with: " ")
            let data6 = data5.replacingOccurrences(of: "  ", with: " ")
            let data0 = data6.replacingOccurrences(of: "  ", with: " ")
            if let d1=Double(data0.components(separatedBy: " ")[1]) {
                cashBuying  = d1    //買入現金
            }
            if let d2=Double(data0.components(separatedBy: " ")[10]) {
                cashSelling = d2    //買入即期
            }
            if let d3=Double(data0.components(separatedBy: " ")[2]) {
                spotBuying  = d3    //賣出現金
            }
            if let d4=Double(data0.components(separatedBy: " ")[11]) {
                spotSelling = d4    //賣出即期
            }
            if cashSelling == 0 {
                cashSelling = spotSelling
            }
            if spotSelling == 0 {
                spotSelling = cashSelling
            }
            if cashBuying == 0 {
                cashBuying = spotBuying
            }
            if spotBuying == 0 {
                spotBuying = cashBuying
            }
        }
        return (cashBuying,cashSelling,spotBuying,spotSelling)
    }

    //查詢Yahoo!匯率

    func yahooQuery () {
        self.backupRate = self.exchangeRate
        self.exchangeRate = self.initRate
        self.queryTime = nil
        let dispatchGroup:DispatchGroup = DispatchGroup()
        var yahooSucceed:Bool = true
        for (indexFrom,codeFrom) in self.currencyCode.enumerated() {
            for (indexTo,codeTo) in self.currencyCode.enumerated() {
                if indexFrom < indexTo {    //只查一半的表格，另一半就是係數顛倒，所以直接填入
                    if indexFrom == 0  { //只查第一排也就是台幣，其他排以台幣為基礎作換算
                        dispatchGroup.enter()
                            let url = URL(string: "http://download.finance.yahoo.com/d/quotes.csv?s="+codeFrom+codeTo+"=X&f=nl1d1t1");
//                        let url = NSURL(string: "http://download.finance.yahoo.com/d/quotes.csv?s="+codeTo+codeFrom+"=X&f=nl1d1t1");
                            let request = URLRequest(url: url!)
                            let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
                                if error == nil {
                                    if let downloadedData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                                        //查到的價格是對美金1元的換算係數，所以另一半係數就是預設表格中的1.0，就不用改
                                        self.exchangeRate[0][indexFrom][indexTo].0 = Double(downloadedData.components(separatedBy: ",")[1])!
                                        self.exchangeRate[0][indexTo][indexFrom].1 = self.exchangeRate[0][indexFrom][indexTo].0
                                        let d = downloadedData.components(separatedBy: ",")[2].replacingOccurrences(of: "\"", with: "")
                                        let t = downloadedData.components(separatedBy: ",")[3].replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\n", with: "").uppercased()
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.locale=Locale(identifier: "en_US")
                                        dateFormatter.dateFormat = "M/d/yyyy h:mma zzz"
                                        if let dt = dateFormatter.date(from: d+" "+t+" GMT") {
                                            self.queryTime = dt
                                         }
                                    }
                                } else {
                                    yahooSucceed = false
                                }
                                dispatchGroup.leave()
                            })
                        task.resume()
                    }
                }

            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            if yahooSucceed {
                for (indexFrom,_) in self.currencyCode.enumerated() {
                    for (indexTo,_) in self.currencyCode.enumerated() {
                        if indexFrom < indexTo && indexFrom != 0 {    //只查一半的表格，另一半就是係數顛倒，所以直接填入
                            self.exchangeRate[0][indexFrom][indexTo].0 = self.exchangeRate[0][0][indexTo].0   //以下皆以對台幣的價格帶入，以維持換算係數的一致
                            self.exchangeRate[0][indexFrom][indexTo].1 = self.exchangeRate[0][0][indexFrom].0
                            self.exchangeRate[0][indexTo][indexFrom].0 = self.exchangeRate[0][0][indexFrom].0
                            self.exchangeRate[0][indexTo][indexFrom].1 = self.exchangeRate[0][0][indexTo].0

                        }

                    }
                }
                //把匯率加入到度量轉換係數的大陣列
                if let _ = self.queryTime {
                    self.rateSource = "Yahoo!"
                    self.currencyTime = self.queryTime! //這裡沒有!會當掉
                    self.saveExchangeRate()
                } else {
                    self.exchangeRate = self.backupRate
                }

            }
        })

    }

}
