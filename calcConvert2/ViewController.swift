//
//  ViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/21.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol pasteLabelDelegate: class {
    func pasteLabel(withString pasteString: String)
    func copyLabel(isUIOutput:Bool)
}


class ViewController: UIViewController, tableViewDelegate, pasteLabelDelegate {

    let precisionLong:String   = "16"
    let precisionShort:String  = "9"
    let maxUnitLong:Int = 6     //直幅最多可顯示的單位數
    var calc:calcConvert = calcConvert()
    var isPad:Bool = false


    @IBOutlet weak var uiOutput: pasteboardLabel!
    @IBOutlet weak var uiMemory: UILabel!
    @IBOutlet weak var uiUnits: UISegmentedControl!
    @IBOutlet weak var uiHistory: pasteboardLabel!
    @IBOutlet weak var uiHistoryScrollView: UIScrollView!
    @IBOutlet weak var uiHistoryContentView: UIView!

    let buildNo:String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    let versionNo:String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    var versionNow:String = ""
    var versionLast:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        versionNow = versionNo + (buildNo <= "1" ? "" : "(\(buildNo))")
        if let ver = defaults.string(forKey: "version") {
            versionLast = ver
        }
        if versionLast < "2.6(2)" {
            defaults.removeObject(forKey: "currencyTime")
            defaults.removeObject(forKey: "rateSource")
            defaults.removeObject(forKey: "exchangeRate")
        }
        defaults.set(versionNow,      forKey: "version")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)

        if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            isPad = true
        }

        // Initialize the output labels.
        uiOutput.adjustsFontSizeToFitWidth=true //數字太長時會自動縮小字級
        uiMemory.adjustsFontSizeToFitWidth=true
        uiOutput.text="0"
        uiMemory.text=""
        uiHistory.text=""

        if (UIDevice.current.orientation.isLandscape) {
            calc.setPrecisionForOutput (withPrecision: precisionLong)
        } else {
            calc.setPrecisionForOutput (withPrecision: precisionShort)
        }

//        calc.loadExchangeRate()

        //啟始category度量種類
//        calc.getUserPreference ()   //這會帶動setPriceConvertingOnly在historyText顯示第一個度量單位名稱
        populateSegmentUnits(calc.categoryIndex)    //重新建立度量單位的選項
        changeHistorySwitch(withSwitch: calc.historySwitch)     //這會顯示或隱藏historyText
        showPriceConvert(withSwitch: calc.showPriceConvertButton)     //這會顯示或隱藏單價換算開關

        uiOutput.isUIOutput = true
        uiOutput.delegate = self
        uiHistory.delegate = self

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //進入畫面時，檢查匯率查詢，例如從設定畫面切回到主畫面就會檢查一次
        if calc.categoryIndex == 3 || calc.currencyTime == nil {
            calc.getExchangeRate()  //上次查詢超過？分鐘再重新查詢匯率
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @objc func applicationDidBecomeActive(_ notification: Notification) {
        if calc.categoryIndex == 3 || calc.currencyTime == nil {
            calc.getExchangeRate()  //上次查詢超過？分鐘再重新查詢匯率
        }

    }

    deinit {
         NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @IBOutlet weak var uiPriceConverting: UIButton!

    @IBAction func uiPriceConvertingSwitch(_ sender: UIButton) {
        if sender == uiPriceConverting {
            uiHistory.text = calc.setPriceConverting(withSwitch: !calc.priceConverting) //開就關、關就開
            sender.setTitle("單價換算 "+(calc.priceConverting ? "ON" : "OFF"), for: UIControl.State())
            sender.setTitleColor((calc.priceConverting ? UIColor.orange : UIColor.lightGray) , for: UIControl.State())
            navigationItem.title = calc.categoryTitle
        }
    }


    //啟始或變換category度量種類
    func changeCategory(withCategory categoryIndex: Int) {
        if categoryIndex == 3 {
            self.showPriceConvert(withSwitch: false)
        }
        if calc.valBuffer != 0 || calc.valueOutput != "0" {    //切換度量前，如果有數值應先清掉（留到下個度量沒有意義）
            calcKeyIn("[C]")
        }
        uiHistory.text = calc.setCategory(withCategory: categoryIndex)   //這會帶動將unit初始為第1個度量單位
        populateSegmentUnits(categoryIndex)  //度量種類改變時，重新建立度量單位的選項
        navigationItem.title = calc.categoryTitle
        outputToDisplay ()  //還沒等號時換度量會先算=的結果，所以不能輸出結果
    }

    //啟始或變換單價換算開關
    func showPriceConvert(withSwitch show:Bool) {
        uiHistory.text = calc.showPriceConvertButton(withSwitch: show)
        uiPriceConverting.isHidden = !show
        uiPriceConverting.setTitle("單價換算 "+(calc.priceConverting ? "ON" : "OFF"), for: UIControl.State())
        uiPriceConverting.setTitleColor((calc.priceConverting ? UIColor.orange : UIColor.lightGray) , for: UIControl.State())
        navigationItem.title = calc.categoryTitle
    }

    //啟始或變換計算歷程的顯示開關
    func changeHistorySwitch(withSwitch historySwitch:Bool) {
        calc.setHistorySwitch(withSwitch:historySwitch)
        uiHistoryScrollView.isHidden = (calc.historySwitch ? false : true)
    }

    //啟始或變換限制小數位數開關
    func changeRoundingSwitch(withScale decimalScale:Double, roundingDisplay:Bool, roundingCalculation:Bool) {
        calc.setRounding(withScale:decimalScale, roundingDisplay:roundingDisplay,roundingCalculation:roundingCalculation)
        outputToDisplay ()
     }


    //產生units選單
    func populateSegmentUnits (_ catalogIndex:IntegerLiteralType) {
        //自定函數用來做出度量單位選項
        uiUnits.removeAllSegments()
//        if catalogIndex == 2 {  //面積
//            uiUnits.apportionsSegmentWidthsByContent = true
//        } else {
//            uiUnits.apportionsSegmentWidthsByContent = false
//        }
        for (index,tx) in calc.unit[catalogIndex].enumerated() {
            if UIDevice.current.orientation.isLandscape || index < maxUnitLong {
                uiUnits.insertSegment(withTitle: tx, at: uiUnits.numberOfSegments, animated: false)
            }
        }
        uiUnits.selectedSegmentIndex=calc.unitIndex  //起始應為第1個度量單位
        if isPad {
            let font = UIFont.systemFont(ofSize: 25)
            uiUnits.setTitleTextAttributes([NSAttributedString.Key(rawValue: convertFromNSAttributedStringKey(NSAttributedString.Key.font)): font],
                                           for: .normal)
        }
     }



    //機體旋轉時，改變精度
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        populateSegmentUnits(calc.categoryIndex)
        if UIDevice.current.orientation.isLandscape {
            calc.setPrecisionForOutput (withPrecision: precisionLong)
        } else {
            calc.setPrecisionForOutput (withPrecision: precisionShort)
        }
        outputToDisplay () //重新輸出數值
    }

    //將要進入設定畫面時，帶入calc物件、清除back按鈕的名稱（太長了難看）
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segueTableView" {
            if let destViewController = segue.destination as? TableViewController {
                destViewController.viewDelegate=self
                destViewController.calc = calc
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
            }
        }

    }
    
    func scrollToEnd(x:CGFloat=0) {
        let oX = uiHistoryScrollView.contentSize.width - uiHistoryScrollView.bounds.size.width
        if oX >= 0 {
            if (oX != x || x == 0) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(250), execute: {
                    let offsetX = self.uiHistoryScrollView.contentSize.width - self.uiHistoryScrollView.bounds.size.width
                    let cg = CGPoint(x: offsetX, y: self.uiHistoryScrollView.contentOffset.y)
                    self.uiHistoryScrollView.setContentOffset(cg, animated: true)
                    self.scrollToEnd(x:offsetX)
                })
            }
        } else {
            let cg = CGPoint(x:0, y:0)
            self.uiHistoryScrollView.setContentOffset(cg, animated: true)
        }
    }

//    uiHistory更新時會改變scrollView的layout，這時做自動捲動
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        scrollToEnd()
//        //捲動位置是historyText的長度減去scrollView的寬度，也就是靠右顯示
//        let offsetX = uiHistoryScrollView.contentSize.width - uiHistoryScrollView.bounds.size.width
//        if offsetX > 0 {
//            var cg = CGPoint(x: offsetX, y: self.uiHistoryScrollView.contentOffset.y)
//            //雖然說layout更新了，不知為什麼有時不會馬上刷新historyText的寬度，所以捲動的程式指派給非同步的系統排程去執行
//            self.uiHistoryScrollView.setContentOffset(cg, animated: true)
//            DispatchQueue.main.async(execute: {
//                //這一行就是捲動
//
//                //不知為什麼即使非同步，有時還是沒來得及刷新historyText的寬度，所以再檢查一次
//                cg = CGPoint(x: (self.uiHistoryScrollView.contentSize.width - self.uiHistoryScrollView.bounds.size.width), y: self.uiHistoryScrollView.contentOffset.y)
//                //如果沒來得及刷新也沒關係，再捲一次就會到位了
//
//                if cg.x != self.uiHistoryScrollView.contentOffset.x {
//                    self.uiHistoryScrollView.setContentOffset(cg, animated: true)
//                }
//            })
//        }
//
//    }
    
    @IBAction func uiSwipeCategory(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == UISwipeGestureRecognizer.Direction.left {
            self.previousCategory()
        } else if sender.direction == UISwipeGestureRecognizer.Direction.right {
            self.nextCategory()
        }
    }
    
    func nextCategory() {
        if calc.categoryIndex + 1 >= calc.category.count {
            self.changeCategory(withCategory: 0)
        } else {
            self.changeCategory(withCategory: calc.categoryIndex + 1)
        }
    }
    
    func previousCategory() {
        if calc.categoryIndex < 1 {
            self.changeCategory(withCategory: calc.category.count - 1)
        } else {
            self.changeCategory(withCategory: calc.categoryIndex - 1)
        }
    }
    
    //***** 用手指變動小數位數 *****
    var factor:(originScale:Int,movingScale:Int) = (0,0) //原始的位數，和移動中的位數
    var beginX:Int = 0                                   //這次開始移動時的位數

//    @IBOutlet var uiPanGesture: UIPanGestureRecognizer!

    @IBAction func uiPanGestureRecognized(_ sender: UIPanGestureRecognizer) {

        if sender.state == UIGestureRecognizer.State.began {
            //移動開始時
            factor = calc.startScaling()
            beginX = factor.movingScale //這次開始移動前的位數
        }

        if sender.state == UIGestureRecognizer.State.changed {
            //每次移動中
            let transX = sender.translation(in: uiOutput).x //移動的x軸向量，負數向左增加位數，正數向右減少位數
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
    @IBAction func uiTapGestureRecognized(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showMenu(uiOutput)
        }
    }

    func showMenu(_ sender: UILabel) {
        sender.becomeFirstResponder()
        let menu = UIMenuController.shared
        if sender == uiHistory {
            menu.arrowDirection = .up
        } else {
            menu.arrowDirection = .down
        }
        if !menu.isMenuVisible {
            menu.setTargetRect(sender.frame, in: sender.superview!)
            menu.setMenuVisible(true, animated: true)
        }
    }

    //uiOutput.Deletage的實作
    func pasteLabel(withString pasteString: String) {
        calc.pastBoard = pasteString
        calcKeyIn("[貼上]")
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
    
    func copyLabel(isUIOutput:Bool){
        let board = UIPasteboard.general
        if isUIOutput {
            board.string = String(format:"%."+precisionLong+"g",calc.valBuffer)
        } else {
            board.string = uiHistory.text
        }
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }

    @IBAction func uiTapHistoryText(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showMenu(uiHistory)
        }
    }
    
    //***** 計算機按鍵的介面 *****

    //轉換unit作換算
    @IBAction func uiUnitValueChanged(_ sender: UISegmentedControl) {
        //度量單位改變時，傳送=取得計算機結果、轉換並以"→"作運算子、輸出轉換結果
        uiHistory.text = calc.unitConvert(sender.selectedSegmentIndex)
        outputToDisplay ()
    }

    //按鍵和輸出的統一處理
    func calcKeyIn(_ key: String) {
        uiHistory.text = calc.keyIn(key) //計算和輸出歷程
        outputToDisplay ()
    }

    func outputToDisplay () {
        uiOutput.text = calc.valueOutput    //顯示計算結果
        uiMemory.text = calc.memoryOutput   //顯示暫存值
        scrollToEnd()
    }

    @IBAction func uiKey1(_ sender: UIButton) {
        calcKeyIn("1")
    }
    @IBAction func uiKey2(_ sender: UIButton) {
        calcKeyIn("2")
    }
    @IBAction func uiKey3(_ sender: UIButton) {
        calcKeyIn("3")
    }
    @IBAction func uiKey4(_ sender: UIButton) {
        calcKeyIn("4")
    }
    @IBAction func uiKey5(_ sender: UIButton) {
        calcKeyIn("5")
    }
    @IBAction func uiKey6(_ sender: UIButton) {
        calcKeyIn("6")
    }
    @IBAction func uiKey7(_ sender: UIButton) {
        calcKeyIn("7")
    }
    @IBAction func uiKey8(_ sender: UIButton) {
        calcKeyIn("8")
    }
    @IBAction func uiKey9(_ sender: UIButton) {
        calcKeyIn("9")
    }
    @IBAction func uiKey0(_ sender: UIButton) {
        calcKeyIn("0")
    }
    @IBAction func uiKeyPoint(_ sender: UIButton) {
        calcKeyIn(".")
    }
    @IBAction func uiKeyClear(_ sender: UIButton) {
        calcKeyIn("[C]")
    }
    @IBAction func uiKeyPlus(_ sender: UIButton) {
        calcKeyIn("+")
    }
    @IBAction func uiKeyMinus(_ sender: UIButton) {
        calcKeyIn("-")
    }
    @IBAction func uiKeyMutiply(_ sender: UIButton) {
        calcKeyIn("x")
    }
    @IBAction func uiKeyDivide(_ sender: UIButton) {
        calcKeyIn("/")
    }
    @IBAction func uiKeyEqual(_ sender: UIButton) {
        calcKeyIn("=")
    }
    @IBAction func uiKeySquareRoot(_ sender: UIButton) {
        calcKeyIn("[sr]")
    }
    @IBAction func uiKeyCubeRoot(_ sender: UIButton) {
        calcKeyIn("[cr]")
    }
    @IBAction func uiKeyMPlus(_ sender: UIButton) {
        calcKeyIn("[m+]")
    }
    @IBAction func uiKeyMMinus(_ sender: UIButton) {
        calcKeyIn("[m-]")
    }
    @IBAction func uiKeyMRecall(_ sender: UIButton) {
        calcKeyIn("[mr]")
    }
    @IBAction func uiKeyMClear(_ sender: UIButton) {
        calcKeyIn("[mc]")
    }




}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
