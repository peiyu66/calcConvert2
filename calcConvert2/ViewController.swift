//
//  ViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/21.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

class ViewController: UIViewController, tableViewDelegate, pasteLabelDelegate {

    let precisionLong:String   = "16"
    let precisionShort:String  = "9"
    var calc:calcConvert = calcConvert()


    @IBOutlet weak var uiOutput: pasteboardLabel!
    @IBOutlet weak var uiMemory: UILabel!
    @IBOutlet weak var uiUnits: UISegmentedControl!
    @IBOutlet weak var uiHistory: UILabel!
    @IBOutlet weak var uiHistoryScrollView: UIScrollView!
    @IBOutlet weak var uiHistoryContentView: UIView!


    override func viewDidLoad() {
        super.viewDidLoad()


        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "applicationDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)



        // Initialize the output labels.
        uiOutput.adjustsFontSizeToFitWidth=true //數字太長時會自動縮小字級
        uiMemory.adjustsFontSizeToFitWidth=true
        uiOutput.text="0"
        uiMemory.text=""
        uiHistory.text=""

        if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
            calc.setPrecisionForOutput (withPrecision: precisionLong)
        } else {
            calc.setPrecisionForOutput (withPrecision: precisionShort)
        }

        //啟始category度量種類
        populateSegmentUnits(calc.categoryIndex)    //重新建立度量單位的選項
        calc.getUserPreference ()   //這會帶動setPriceConvertingOnly在historyText顯示第一個度量單位名稱
        changeHistorySwitch(withSwitch: calc.historySwitch)     //這會顯示或隱藏historyText
        showPriceConvert(withSwitch: calc.showPriceConvertButton)     //這會顯示或隱藏單價換算開關

        uiOutput.Delegate = self

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //進入畫面時，檢查匯率查詢，例如從設定畫面切回到主畫面就會檢查一次
        calc.getExchangeRate()  //上次查詢超過30分鐘再重新查詢匯率
     }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func applicationDidBecomeActive(notification: NSNotification) {
        calc.getExchangeRate()  //上次查詢超過30分鐘再重新查詢匯率
    }

    deinit {
         NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    @IBOutlet weak var uiPriceConverting: UIButton!

    @IBAction func uiPriceConvertingSwitch(sender: UIButton) {
        if sender == uiPriceConverting {
            uiHistory.text = calc.setPriceConverting(withSwitch: !calc.priceConverting) //開就關、關就開
            sender.setTitle("單價換算 "+(calc.priceConverting ? "ON" : "OFF"), forState: UIControlState.Normal)
            sender.setTitleColor((calc.priceConverting ? UIColor.orangeColor() : UIColor.lightGrayColor()) , forState: UIControlState.Normal)
            navigationItem.title = calc.categoryTitle
        }
    }


    //啟始或變換category度量種類
    func changeCategory(withCategory categoryIndex: Int) {
        uiHistory.text = calc.setCategory(withCategory: categoryIndex)   //這會帶動將unit初始為第1個度量單位
        populateSegmentUnits(categoryIndex)  //度量種類改變時，重新建立度量單位的選項
        navigationItem.title = calc.categoryTitle
        outputToDisplay ()  //還沒等號時換度量會先算=的結果，所以不能輸出結果
    }

    //啟始或變換單價換算開關
    func showPriceConvert(withSwitch show:Bool) {
        uiHistory.text = calc.showPriceConvertButton(withSwitch: show)
        uiPriceConverting.hidden = !show
        uiPriceConverting.setTitle("單價換算 "+(calc.priceConverting ? "ON" : "OFF"), forState: UIControlState.Normal)
        uiPriceConverting.setTitleColor((calc.priceConverting ? UIColor.orangeColor() : UIColor.lightGrayColor()) , forState: UIControlState.Normal)
        navigationItem.title = calc.categoryTitle
    }

    //啟始或變換計算歷程的顯示開關
    func changeHistorySwitch(withSwitch historySwitch:Bool) {
        calc.setHistorySwitch(withSwitch:historySwitch)
        uiHistoryScrollView.hidden = (calc.historySwitch ? false : true)
    }

    //啟始或變換限制小數位數開關
    func changeRoundingSwitch(withScale decimalScale:Double, roundingDisplay:Bool, roundingCalculation:Bool) {
        calc.setRounding(withScale:decimalScale, roundingDisplay:roundingDisplay,roundingCalculation:roundingCalculation)
        outputToDisplay ()
     }


    //產生units選單
    func populateSegmentUnits (catalogIndex:IntegerLiteralType) {
        //自定函數用來做出度量單位選項
        uiUnits.removeAllSegments()
        for tx in calc.unit[catalogIndex] {
            uiUnits.insertSegmentWithTitle(tx, atIndex: uiUnits.numberOfSegments, animated: false)
        }
        uiUnits.selectedSegmentIndex=calc.unitIndex  //起始應為第1個度量單位
     }



    //機體旋轉時，改變精度
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
            calc.setPrecisionForOutput (withPrecision: precisionLong)
        } else {
            calc.setPrecisionForOutput (withPrecision: precisionShort)
        }
        outputToDisplay () //重新輸出數值
    }

    //將要進入設定畫面時，帶入calc物件、清除back按鈕的名稱（太長了難看）
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segueTableView" {
            if let destViewController = segue.destinationViewController as? TableViewController {
                destViewController.viewDelegate=self
                destViewController.calc = calc
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
            }
        }

    }

    //uiHistory更新時會改變scrollView的layout，這時做自動捲動
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //捲動位置是historyText的長度減去scrollView的寬度，也就是靠右顯示
        var cg = CGPointMake((uiHistoryScrollView.contentSize.width - uiHistoryScrollView.bounds.size.width), self.uiHistoryScrollView.contentOffset.y)
        //雖然說layout更新了，不知為什麼有時不會馬上刷新historyText的寬度，所以捲動的程式指派給非同步的系統排程去執行
        dispatch_async(dispatch_get_main_queue(), {
            //這一行就是捲動
            self.uiHistoryScrollView.setContentOffset(cg, animated: true)

            //不知為什麼即使非同步，有時還是沒來得及刷新historyText的寬度，所以再檢查一次
            cg = CGPointMake((self.uiHistoryScrollView.contentSize.width - self.uiHistoryScrollView.bounds.size.width), self.uiHistoryScrollView.contentOffset.y)
            //如果沒來得及刷新也沒關係，再捲一次就會到位了
            if cg.x != self.uiHistoryScrollView.contentOffset.x {
                self.uiHistoryScrollView.setContentOffset(cg, animated: true)
            }
        })

    }


    //***** 用手指變動小數位數 *****
    var factor:(originScale:Int,movingScale:Int) = (0,0) //原始的位數，和移動中的位數
    var beginX:Int = 0                                   //這次開始移動時的位數

    @IBOutlet var uiPanGesture: UIPanGestureRecognizer!

    @IBAction func uiPanGestureRecognized(sender: UIPanGestureRecognizer) {

        if sender.state == UIGestureRecognizerState.Began {
            //移動開始時
            factor = calc.startScaling()
            beginX = factor.movingScale //這次開始移動前的位數
        }

        if sender.state == UIGestureRecognizerState.Changed {
            //每次移動中
            let transX = uiPanGesture.translationInView(uiOutput).x //移動的x軸向量，負數向左增加位數，正數向右減少位數
            let movedX:Int = Int(round(transX/50))      //換算成每移動50點才變動1個小數位
            if factor.originScale > 0 {                 //原始數值有小數位才處理
                factor.movingScale = beginX - movedX    //這次移動的位數，必須介於0和原始位數之間（轉正負所以用減）
                factor.movingScale = (factor.movingScale < 0 ? 0 : (factor.movingScale > factor.originScale ? factor.originScale : factor.movingScale))
                calc.onScaling(factor.movingScale)      //用移動位數更新暫存值
                outputToDisplay ()                      //，並回饋到畫面上

            }
        }
    }


//***** 手指點出複製貼上的選單 *****//
    @IBAction func uiTapGestureRecognized(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            showMenu(uiOutput)
        }
    }

    func showMenu(sender: UILabel) {
        sender.becomeFirstResponder()
        let menu = UIMenuController.sharedMenuController()
        if !menu.menuVisible {
            menu.setTargetRect(sender.frame, inView: sender.superview!)
            menu.setMenuVisible(true, animated: true)
        }
    }

    //uiOutput.Deletage的實作
    func pasteLabel(withString pasteString: String) {
        calc.pastBoard = pasteString
        calcKeyIn("[貼上]")
    }
    
    func copyLabel(){
        let board = UIPasteboard.generalPasteboard()
        board.string = String(format:"%."+precisionLong+"g",calc.valBuffer)
        let menu = UIMenuController.sharedMenuController()
        menu.setMenuVisible(false, animated: true)
    }


    //***** 計算機按鍵的介面 *****

    //轉換unit作換算
    @IBAction func uiUnitValueChanged(sender: UISegmentedControl) {
        //度量單位改變時，傳送=取得計算機結果、轉換並以"→"作運算子、輸出轉換結果
        uiHistory.text = calc.unitConvert(sender.selectedSegmentIndex)
        outputToDisplay ()
    }

    //按鍵和輸出的統一處理
    func calcKeyIn(key: String) {
        uiHistory.text = calc.keyIn(key) //計算和輸出歷程
        outputToDisplay ()

    }

    func outputToDisplay () {
        //顯示計算結果
        uiOutput.text = calc.valueOutput
        //顯示暫存值
        uiMemory.text = calc.memoryOutput
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
        calcKeyIn("[C]")
    }
    @IBAction func uiKeyPlus(sender: UIButton) {
        calcKeyIn("+")
    }
    @IBAction func uiKeyMinus(sender: UIButton) {
        calcKeyIn("-")
    }
    @IBAction func uiKeyMutiply(sender: UIButton) {
        calcKeyIn("x")
    }
    @IBAction func uiKeyDivide(sender: UIButton) {
        calcKeyIn("/")
    }
    @IBAction func uiKeyEqual(sender: UIButton) {
        calcKeyIn("=")
    }
    @IBAction func uiKeySquareRoot(sender: UIButton) {
        calcKeyIn("[sr]")
    }
    @IBAction func uiKeyCubeRoot(sender: UIButton) {
        calcKeyIn("[cr]")
    }
    @IBAction func uiKeyMPlus(sender: UIButton) {
        calcKeyIn("[m+]")
    }
    @IBAction func uiKeyMMinus(sender: UIButton) {
        calcKeyIn("[m-]")
    }
    @IBAction func uiKeyMRecall(sender: UIButton) {
        calcKeyIn("[mr]")
    }
    @IBAction func uiKeyMClear(sender: UIButton) {
        calcKeyIn("[mc]")
    }




}

