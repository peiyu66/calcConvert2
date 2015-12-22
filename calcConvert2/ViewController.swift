//
//  ViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/21.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

class ViewController: UIViewController, tableViewDelegate {

    let precisionLong:String   = "15"
    let precisionShort:String  = "8"
    var calc:calcConvert = calcConvert()
    var precision:String = ""

    @IBOutlet weak var uiOutput: UILabel!
    @IBOutlet weak var uiMemory: UILabel!
    @IBOutlet weak var uiUnits: UISegmentedControl!
    @IBOutlet weak var uiHistory: UITextView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize the output labels.
        uiOutput.adjustsFontSizeToFitWidth=true
        uiMemory.adjustsFontSizeToFitWidth=true
        uiOutput.text="0"
        uiMemory.text=""
        uiHistory.text=""

        if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
            precision=precisionLong
        } else {
            precision=precisionShort
        }

        changedSetting(withIndex: calc.categoryIndex,priceConverting:calc.priceConverting) //起始度量種類是0重量，單價換算是關閉

        calc.getExchangeRate()  //查詢匯率

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //設定category度量種類
    func changedSetting(withIndex index: Int?, priceConverting: Bool?) {
        calc.categoryIndex=index!
        calc.priceConverting=priceConverting!
        navigationItem.title="度量："+calc.category[calc.categoryIndex]
        if calc.priceConverting {
            navigationItem.title=navigationItem.title!+"，單價換算＄"
        }
        populateSegmentUnits(calc.categoryIndex)  //度量種類改變時，重新建立度量單位的選項

    }

    //產生units選項
    func populateSegmentUnits (catalogIndex:IntegerLiteralType) {
        //自定函數用來做出度量單位選項
        uiUnits.removeAllSegments()
        for tx in calc.unit[catalogIndex] {
            uiUnits.insertSegmentWithTitle(tx, atIndex: uiUnits.numberOfSegments, animated: false)
        }
        uiUnits.selectedSegmentIndex=0
        calc.unitIndex=uiUnits.selectedSegmentIndex
    }

    @IBAction func SegUnitValueChanged(sender: UISegmentedControl) {
        //度量單位改變時，相當於先按=取得計算機結果、轉換、傳送empty輸出轉換結果
        calcKeyIn("=")
        calc.unitConvert(sender.selectedSegmentIndex)
        calcKeyIn("")
    }


    //機體旋轉時
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
            precision=precisionLong
        } else {
            precision=precisionShort
        }
        calcKeyIn("") //重新輸出數值
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let destViewController = segue.destinationViewController as! TableViewController
        destViewController.viewDelegate=self
        destViewController.calc = calc
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }


    //計算機介面

    func calcKeyIn(key: String) {
        if calc.keyIn(key) == "" {
            uiOutput.text = String(format:"%."+precision+"g",calc.valBuffer)
            uiHistory.text = calc.historyBuffer
        } else {
            uiOutput.text = String(format:"%."+precision+"g",calc.digBuffer)
        }
        if calc.valMemory == 0 {
            uiMemory.text = ""
        } else {
            uiMemory.text = "m = "+String(format:"%."+precision+"g",calc.valMemory)
        }
    }

    @IBAction func uiKey1(sender: UIButton) {
        calcKeyIn("1")
    }
    @IBAction func uiKey2(sender: UIButton) {
        calcKeyIn("2")
    }
    @IBAction func uiKey3(sender: UIButton) {
        calcKeyIn("3")
    }
    @IBAction func uiKey4(sender: UIButton) {
        calcKeyIn("4")
    }
    @IBAction func uiKey5(sender: UIButton) {
        calcKeyIn("5")
    }
    @IBAction func uiKey6(sender: UIButton) {
        calcKeyIn("6")
    }
    @IBAction func uiKey7(sender: UIButton) {
        calcKeyIn("7")
    }
    @IBAction func uiKey8(sender: UIButton) {
        calcKeyIn("8")
    }
    @IBAction func uiKey9(sender: UIButton) {
        calcKeyIn("9")
    }
    @IBAction func uiKey0(sender: UIButton) {
        calcKeyIn("0")
    }
    @IBAction func uiKeyPoint(sender: UIButton) {
        calcKeyIn(".")
    }
    @IBAction func uiKeyClear(sender: UIButton) {
        calcKeyIn("C")
    }
    @IBAction func uiKeyPlus(sender: UIButton) {
        calcKeyIn("+")
    }
    @IBAction func uiKeyMinus(sender: UIButton) {
        calcKeyIn("-")
    }
    @IBAction func uiKeyMutiply(sender: UIButton) {
        calcKeyIn("*")
    }
    @IBAction func uiKeyDivide(sender: UIButton) {
        calcKeyIn("/")
    }
    @IBAction func uiKeyEqual(sender: UIButton) {
        calcKeyIn("=")
    }
    @IBAction func uiKeySquareRoot(sender: UIButton) {
        calcKeyIn("SR")
    }
    @IBAction func uiKeyCubeRoot(sender: UIButton) {
        calcKeyIn("CR")
    }
    @IBAction func uiKeyMPlus(sender: UIButton) {
        calcKeyIn("m+")
    }
    @IBAction func uiKeyMMinus(sender: UIButton) {
        calcKeyIn("m-")
    }
    @IBAction func uiKeyMRecall(sender: UIButton) {
        calcKeyIn("mr")
    }
    @IBAction func uiKeyMClear(sender: UIButton) {
        calcKeyIn("mc")
    }

    @IBAction func uiKeyBack(sender: UIButton) {
        calcKeyIn("back")
    }


}

