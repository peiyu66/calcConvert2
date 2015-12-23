//
//  calcConvert.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/21.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import Foundation


class calcConvert {

    //*****計算機的部份*****
    var valBuffer:Double=0    //保存前數值
    var valMemory:Double=0    //m記憶值
    var opBuffer:String=""    //保存前運算子
    var txtBuffer:String=""   //組字當中的數字，empty表示重新開始組字
    var digBuffer:Double=0    //組字結果的值
    var historyBuffer:String=""
    var historyList:([String])=[""] //輸入按鍵的歷史紀錄
    let precision:String="15" //最高精度是15



    init () {
        convertX = convertXList
        category = categoryList
        unit = unitList
    }

    func keyIn (inputedKey: String) -> String {
        //組字及運算：valBuffer得到值之後，就把組字中txtBuffer清為empty，並輸出valBuffer
        //如果收到的字是=開頭的數值，則直接帶入數值當作結果
        //如果收到的是其他如empty，則有txtBuffer就輸出txtBuffer，沒有就重新輸出valBuffer

        switch inputedKey {
        case "C":
            if valBuffer==0 && txtBuffer==""{
                valMemory=0
            }
            valBuffer=0
            opBuffer=""
            txtBuffer=""
            historyList=[""]
            historyBuffer=""
//        case "back":
//            if historyList.count > 1 {
//                historyList.removeLast()
//                historyBuffer=""
//                for key in historyList {
//                    historyBuffer += key
//                }
//            }
        case "mc":
            valMemory = 0
        case "+","-","*","/","=","m+","m-","CR","SR":
            //這幾個運算子將結束組字並做運算；CR立方根、SR平方根
            //之前有op則先拿來和現在剛輸入的數值做運算
            switch opBuffer {
                case "+":
                    valBuffer=valBuffer+digBuffer
                case "-":
                    valBuffer=valBuffer-digBuffer
                case "*":
                    valBuffer=valBuffer*digBuffer
                case "/":
                    valBuffer=valBuffer/digBuffer
                case "=":
                    break
                case "m+","m-":
                    if txtBuffer != "" {    //前組字中按暫存，現在又按其他運算子，才可將組字值代入
                        valBuffer=digBuffer
                    }
                case "CR","SR":
                    if digBuffer != 0 {     //前組字中開根，然後呢？
                        valBuffer=digBuffer
                    }
                default:
                    //第一次沒有前運算子時，把組字結果做值輸出
                    if txtBuffer != "" {
                        valBuffer=digBuffer
                    }
            }
            switch inputedKey {
                case "m+":
                    valMemory=valMemory+valBuffer
                case "m-":
                    valMemory=valMemory-valBuffer
                case "CR":
                    valBuffer=cbrt(valBuffer)
                case "SR":
                    valBuffer=sqrt(valBuffer)
                default:
                    break
            }

//            historyList.append(txtBuffer)
//            historyList.append(inputedKey)
//            historyBuffer+=txtBuffer
//            historyBuffer+=inputedKey

            txtBuffer=""
            digBuffer=0
            opBuffer=inputedKey
        case "0","1","2","3","4","5","6","7","8","9",".","mr":
            if opBuffer == "=" {    //如果之前已按=結束運算，之後沒有按運算子就開始組數字，則前數值應放棄歸零，且前運算子也清除為初始狀態
                valBuffer=0
                opBuffer=""
            }
            if inputedKey=="mr" {
                txtBuffer=String(format:"%."+precision+"g",valMemory)
                digBuffer=valMemory
            } else {
                if txtBuffer == "0" && inputedKey != "." { txtBuffer="" } //如果組數字時已有前導零，又不是組小數，則清除前導零
                if txtBuffer == ""  && inputedKey == "." { txtBuffer="0"} //如果組字是初始empty又接小數點，則補前導零
                if txtBuffer.containsString(".") && inputedKey=="." {
                    break   //重複小數點就忽略
                } else {
                    txtBuffer=txtBuffer+inputedKey  //最後把組字接上去
                    if let _=Double(txtBuffer) {
                        digBuffer=Double(txtBuffer)!    //取得組字結果值
                    } else {
                        digBuffer=0
                    }               }
            }
        default:
            //只有一種特殊情形是傳入按鍵外的資料，即傳入=後接數值，則將數值帶入保存 (度量單位改變時帶入換算結果）
            if inputedKey.rangeOfString("=") != nil {
                let inputedValue=inputedKey.stringByReplacingOccurrencesOfString("=", withString: "") //去掉等號
                if let _=Double(inputedValue) {
                    valBuffer=Double(inputedValue)!
                } else {
                    valBuffer=0
                }
                txtBuffer=""
                digBuffer=0
            }
            //如果是其他情形，如empty，這裡就是什麼都不做，則相當於把txtBuffer或valBuffer重新輸出，例如為了更新畫面數值的精度時
        }

        return txtBuffer

    }


    //*****度量衡轉換的部份*****
    var categoryIndex:Int = 0         //目前度量種類
    var unitIndex:Int = 0             //保留前單位
    var priceConverting:Bool=false    //單價換算是否啟動


    //度量種類
    var category:([String])           //在init()會塞入categoryList這個大陣列，之後取得匯率時再加入currencyCategory
    let categoryList:([String]) =  ["重量","長度","面積"]
    let currencyCategory:([String])=["匯兌"]


    //單位
    var unit:([[String]])            //在init()會塞入unitList這個陣列，之後取得匯率時再加入currencyList
    var unitList:([[String]]) =  [
            ["公斤","公克","台斤","台兩","磅","盎司"],   // 重量
            ["公尺","公分","台尺","英尺","英寸"],       // 長度
            ["平方公尺","平方英尺","坪"]               // 面積
        ]
    let currencyList:([[String]]) = [["台幣","日圓","美元","歐元","人民幣","港幣"]]
    let currencyCode:([String]) = ["TWD","JPY","USD","EUR","CNY","HKD"] //這是Yahoo的查詢代碼
    var currencyTime:NSDate?  //取得匯率的時間

    //轉換係數：為了增加精度所以使用雙係數。例如3公斤=5台斤，則2公斤=2*5/3台斤。
    //這是3維陣列：[度量種類][原單位][新單位]
    let convertXList:([[[(Double,Double)]]]) = [
        //重量
        [   //  公斤              公克              台斤             台兩            磅             盎司
            [(1.0,1.0),         (1000.0,1.0),   (5.0,3.0),   (80.0,3.0), (1.0,0.45359237),(16.0,0.45359237)],  // 公斤 3公斤=5台斤
            [(1.0,1000.0),      (1.0,1.0),      (5.0,3000.0),(8.0,300.0),(1.0,453.59237), (16.0,453.59237)],   // 公克 3000公克=5台斤=80台兩
            [(3.0,5.0),         (3000.0,5.0),   (1.0,1.0),   (16.0,1.0), (3.0,2.26796185),  (48.0,2.26796185)],// 台斤 1台斤=16台兩=(3/2.26796185)磅
            [(3.0,80.0),        (300.0,8.0),    (1.0,16.0),  (1.0,1.0),  (3.0,36.2873896), (48.0,36.2873896)], // 台兩 1台兩=(3/2.26796185*16)磅=(3/36.2873896)磅
            [(0.45359237,1.0),  (453.59237,1.0),(2.26796185,3.0),(36.2873896,3.0),(1.0,1.0), (16.0,1.0)],      // 磅 1磅=453.59237公克=16盎司=(453.59237*5)/3000台斤=(2.26796185/3)台斤
            [(0.45359237,16.0), (453.59237,16.0),(2.26796185,48.0),(36.2873896,48.0),(1.0,16.0), (1.0,1.0)]    // 盎司
        ],

        //長度
        [   //   公尺         公分        台尺		          英呎			英吋
            [(1.0,  1.0),(100.0,  1.0),(33.0, 10.0),  (100.0, 30.48),(100.0, 2.54)],   		// 公尺 10公尺=33台尺
            [(1.0,100.0),(1.0,    1.0),(33.0,1000.0), (1.0,30.48),   (1.0,2.54)],  			// 公分
            [(10.0,33.0),(1000.0,33.0),(1.0, 1.0),    (1.0, 1.00584),(12.0, 1.00584)],      // 台尺 1005.84台尺=1000英呎=300.48公尺=300.48*3.3台尺
            [(30.48,100.0),(30.48,1.0),(1.00584, 1.0),(1.0, 1.0),    (12.0, 1.0)],   		// 英呎 1英呎=30.48公分=12英吋
            [(2.54,100.0), (2.54,1.0), (1.00584, 12.0),(1.0, 12.0),  (1.0, 1.0)]    		// 英吋
        ],

        //面積
        [   // 平方公尺             平方英尺         坪
            [(1.0,1.0),       (100.0,9.290304),(121.0,400.0)],      //平方公尺 400平方公尺=121坪
            [(9.290304,100.0),(1.0,1.0),       (11.241268,400.0)],  //平方英尺 100平方英尺=9.290304平方公尺
            [(400.0,121.0),(400.0,11.241268),  (1.0,1.0)]           //坪 11.241268坪=400平方英尺
        ]
    ]
    var convertX:([[[(Double,Double)]]])    //在init()會塞入convertXList這個大陣列，之後取得匯率時再加入exchangeRate這個陣列
    var exchangeRate:([[[(Double,Double)]]]) = [[
        //台幣        日圓      美元      歐元       人民幣    港幣
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],  //台幣
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],  //日圓
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],  //美元
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],  //歐元
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)],  //人民幣
        [(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0),(1.0,1.0)]   //港幣
    ]]






    func unitConvert (unitIndexTo:Int) -> Double {
        var output:Double=0
        let factor0=convertX[categoryIndex][unitIndex][unitIndexTo].0
        let factor1=convertX[categoryIndex][unitIndex][unitIndexTo].1
        if priceConverting {
            output = valBuffer * factor1 / factor0    //單價換算時，轉換係數的分子分母顛倒
        } else {
            output = valBuffer * factor0 / factor1
        }
        unitIndex=unitIndexTo
        valBuffer=output
        return valBuffer
    }



    func getExchangeRate () {
        let dispatchGroup:dispatch_group_t = dispatch_group_create()
        var allRateUpdated:Bool = true
        for (indexFrom,codeFrom) in self.currencyCode.enumerate() {
            for (indexTo,codeTo) in self.currencyCode.enumerate() {
                if indexFrom < indexTo {
                    dispatch_group_enter(dispatchGroup)
                        let url = NSURL(string: "http://download.finance.yahoo.com/d/quotes.csv?s="+codeFrom+codeTo+"=X&f=nl1d1t1");
                        let request = NSURLRequest(URL: url!)
                        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data, response, error) in
                            if error == nil {
                                if let downloadedData = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                                    self.exchangeRate[0][indexFrom][indexTo].0 = Double(downloadedData.componentsSeparatedByString(",")[1])!
                                    self.exchangeRate[0][indexTo][indexFrom].1 = self.exchangeRate[0][indexFrom][indexTo].0
                                    let d = downloadedData.componentsSeparatedByString(",")[2].stringByReplacingOccurrencesOfString("\"", withString: "")
                                    let t = downloadedData.componentsSeparatedByString(",")[3].stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "").uppercaseString
                                    let dateFormatter = NSDateFormatter()
                                    dateFormatter.locale=NSLocale(localeIdentifier: "us")
                                    dateFormatter.dateFormat = "M/d/yyyyh:mmazzz"
                                    if let dt = dateFormatter.dateFromString(d+t+"GMT") {
                                        self.currencyTime = dt
                                    }
                                }
                            } else {
                                allRateUpdated = false
                            }
                            dispatch_group_leave(dispatchGroup)
                        })
                    task.resume()
                }

            }
        }
        dispatch_group_notify(dispatchGroup,dispatch_get_main_queue(), {
            if allRateUpdated {
                self.convertX = self.convertXList + self.exchangeRate
                self.unit = self.unitList + self.currencyList
                self.category = self.categoryList + self.currencyCategory
            } else {
                self.currencyTime = nil
            }
        })

    }

}