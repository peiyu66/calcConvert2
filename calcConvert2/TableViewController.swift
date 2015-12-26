//
//  TableViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/22.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol tableViewDelegate: class {
    func changeCategory(withCategory categoryIndex: Int, priceConverting:Bool)
    func changePriceConverting(withSwitch priceConverting:Bool)
    func changeHistorySwitch(withSwitch historySwitch:Bool)
    func changeRoundingSwitch(withScale scale:Double, roundingDisplay:Bool, roundingCalculation:Bool)
}

class TableViewController: UITableViewController ,cellSwitchDelegate, cellStepperDelegate {

    var calc:calcConvert?
    var lastSelectedIndexPath:NSIndexPath?
    var lastPriceSwitchStatus:Bool=false
    var lastHistorySwitchStatus:Bool=false
    var lastRoundingDisplay:Bool=false
    var lastRoundingCalculation:Bool=false
    var lastRoundingScale:Double=10000.0    //四捨五入的小數位,10000是4位數
    var viewDelegate:tableViewDelegate?
    var uiPriceConverting:UISwitch?
    var uiRoundingCalculation:UISwitch?
    var currencyTime:String=""



    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        lastRoundingDisplay=calc!.roundingDisplay
        lastRoundingCalculation=calc!.rounding
        lastPriceSwitchStatus=calc!.priceConverting
        lastHistorySwitchStatus=calc!.historySwitch
        lastRoundingScale=calc!.roundingScale

        //checkCurrencyTime()

    }

//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//     }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if (lastSelectedIndexPath!.row != calc!.categoryIndex) ||  lastPriceSwitchStatus != calc!.priceConverting {
            //只要category變了必須帶動刷新PriceConverting（顯示是否帶單價符號的單位名稱），所以不必重複叫
            if (lastSelectedIndexPath!.row != calc!.categoryIndex) {
                viewDelegate!.changeCategory(withCategory:(lastSelectedIndexPath!.row), priceConverting:lastPriceSwitchStatus)
            } else {
                viewDelegate!.changePriceConverting(withSwitch: lastPriceSwitchStatus)
            }
         }
        if lastHistorySwitchStatus != calc!.historySwitch {
            viewDelegate!.changeHistorySwitch(withSwitch: lastHistorySwitchStatus)
        }
        if lastRoundingDisplay != calc!.roundingDisplay || lastRoundingCalculation != calc!.rounding || lastRoundingScale != calc!.roundingScale {
            viewDelegate!.changeRoundingSwitch(withScale:lastRoundingScale, roundingDisplay:lastRoundingDisplay, roundingCalculation:lastRoundingCalculation)
        }

    }




    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4    //度量種類、小數位數、單價換算、計算歷程
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: //度量種類有幾條row?
            if calc!.category.count == (calc!.categoryList.count + 1) {
                checkCurrencyTime ()
            }
            return calc!.category.count
        case 1:
            if lastRoundingDisplay {
                return 3    //限制小數位數、四捨五入、位數
            } else {
                return 1    //限制顯示小數沒有開，就不需要四捨五入和位數
            }
        case 2:
            return 1    //單價換算
        case 3:
            return 1    //計算歷程
        default:
            return 0

        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: //度量種類header
            return "度量種類"
        case 1:
            return "小數位數"
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: //度量種類footer 顯示匯率查詢時間及計算說明
            return checkCurrencyTime ()
        case 2: //單價換算
            return "先選公克再輸入1，代表每公克單價1元，然後切換至公斤得每公斤1000元。這就是單價換算的方式。"
        default:
            return ""
        }
    }

            func checkCurrencyTime () ->String {
                //檢查匯率查詢時間，在section footer顯示
                var footer:String=""
                if let _=calc!.currencyTime {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy/MM/dd hh:mm a"
                    dateFormatter.locale = NSLocale(localeIdentifier: "us")
                    footer="Yahoo!匯率查詢時間："+dateFormatter.stringFromDate(calc!.currencyTime!)+" \n\n匯兌換算以美金為基準。例如台幣換日圓是台幣對美金價格再換成日幣，而不是採市場的台幣對日幣價格。"
                } else {
                    footer="等候連網查詢匯率....成功時才會出現「匯兌」選項。"
                }

                return footer
            }



    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: //度量種類的cell
            let cell = tableView.dequeueReusableCellWithIdentifier("cellCategory", forIndexPath: indexPath)
            cell.textLabel!.text = calc!.category[indexPath.row]
            if indexPath.row == calc!.categoryIndex {
                cell.accessoryType = .Checkmark
                lastSelectedIndexPath=indexPath
            } else {
                cell.accessoryType = .None
            }
            return cell
        case 1: //section 1 小數位數
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("cellSwitch", forIndexPath: indexPath) as! cellSwitch
                cell.tableCellDelegate=self
                cell.uiSwitch.on=lastRoundingDisplay
                cell.uiSwitchLabel.text="顯示數值時固定小數位數"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("cellSwitch", forIndexPath: indexPath) as! cellSwitch
                cell.tableCellDelegate=self
                cell.uiSwitch.on=lastRoundingCalculation
                cell.uiSwitchLabel.text="計算時也要捨入到此位數"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("cellStepper", forIndexPath: indexPath) as! cellStepper
                cell.tableCellDelegate=self
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.uiStepper.value = log10(lastRoundingScale)
                cell.uiStepperLabel.text="小數位數 = "+String(format:"%.0f",cell.uiStepper.value)
                return cell
            default:
                break
            }
        case 2: //section 2 單價換算
            let cell = tableView.dequeueReusableCellWithIdentifier("cellSwitch", forIndexPath: indexPath) as! cellSwitch
            cell.tableCellDelegate=self
            cell.uiSwitch.on=lastPriceSwitchStatus
            cell.uiSwitchLabel.text="單價換算"
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            uiPriceConverting=cell.uiSwitch
            if calc!.categoryIndex == 3 {   //匯兌時不能使用單價換算
                uiPriceConverting!.enabled = false
            } else {
                uiPriceConverting!.enabled = true
            }
            return cell
        case 3: //section 3 計算歷程
            let cell = tableView.dequeueReusableCellWithIdentifier("cellSwitch", forIndexPath: indexPath) as! cellSwitch
            cell.tableCellDelegate=self
            cell.uiSwitch.on = lastHistorySwitchStatus
            cell.uiSwitchLabel.text="計算歷程"
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        default:
            break
        }
        //數錯section數目，否則不應該跑到這裡
        let cell = tableView.dequeueReusableCellWithIdentifier("cellCategory", forIndexPath: indexPath)
        cell.textLabel!.text = "unknown section?"
        return cell

   }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            //這裡只處理度量種類的選擇，其他設定項目不允許選到row（UITableViewCellSelectionStyle.None）
            if indexPath.row != lastSelectedIndexPath!.row {
                let oldCell = tableView.cellForRowAtIndexPath(lastSelectedIndexPath!)
                oldCell!.accessoryType = .None
                if indexPath.row == 3 { //匯兌時不能使用單價換算
                    uiPriceConverting!.on = false
                    uiPriceConverting!.enabled = false
                    lastPriceSwitchStatus = false
                } else {
                    uiPriceConverting!.enabled = true
                }
                let newCell = tableView.cellForRowAtIndexPath(indexPath)
                newCell!.accessoryType = .Checkmark
                lastSelectedIndexPath = indexPath
            }
        }
    }


    // cellSwitchDelegate
    func cellSwitchChanged(withStatus status:Bool?,cellSwitch:UITableViewCell?) {
        let indexPath = self.tableView.indexPathForCell(cellSwitch!)
        switch indexPath!.section {
        case 1:
            switch indexPath!.row {
            case 0: //限制顯示的小數位數
                lastRoundingDisplay=status!
                self.tableView.reloadData()
                if lastRoundingDisplay == false {
                    lastRoundingCalculation = false //不限制顯示位數的時候，也要關閉計算時的捨入開關
                }
            case 1: //計算時即四捨五入
                lastRoundingCalculation=status!
            default:
                break
            }
        case 2: //單價換算
            lastPriceSwitchStatus=status!
        case 3: //計算歷程
            lastHistorySwitchStatus=status!
        default:
            break
        }

    }

    // cellStepperDelegate
    func cellStepperValueChanged(withCell cell: cellStepper?) {
        let stepper = cell!.uiStepper
        lastRoundingScale = pow (10.0, stepper.value)
        cell!.uiStepperLabel.text="小數位數 = "+String(format:"%.0f",stepper.value)

    }

}
