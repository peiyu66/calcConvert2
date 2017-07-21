//
//  TableViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/22.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol tableViewDelegate: class {
    func changeCategory(withCategory categoryIndex: Int)
    func showPriceConvert(withSwitch show:Bool)
    func changeHistorySwitch(withSwitch historySwitch:Bool)
    func changeRoundingSwitch(withScale scale:Double, roundingDisplay:Bool, roundingCalculation:Bool)
}

class TableViewController: UITableViewController ,cellSwitchDelegate, cellStepperDelegate {

    var calc:calcConvert?
    
    var lastSelectedCategoryIndex:Int=0
    var lastPriceSwitchStatus:Bool=false
    var lastPriceSwitchEnabled:Bool=true
    var lastHistorySwitchStatus:Bool=false

    var lastRoundingDisplay:Bool=false
    var lastRoundingCalculation:Bool=false
    var lastDecimalScale:Double=4    //四捨五入的小數位,10000是4位數

    var viewDelegate:tableViewDelegate?
    var currencyTime:String=""



    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        lastSelectedCategoryIndex=calc!.categoryIndex
        lastRoundingDisplay=calc!.roundingDisplay
        lastRoundingCalculation=calc!.rounding
        lastPriceSwitchStatus=calc!.showPriceConvertButton
        lastHistorySwitchStatus=calc!.historySwitch
        lastDecimalScale=calc!.decimalScale

        //checkCurrencyTime()

    }

//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//     }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    override func viewWillDisappear(animated: Bool) {
//        super.viewWillDisappear(animated)
//    }

    func setPreference () {
        if (lastSelectedCategoryIndex != calc!.categoryIndex) {
            viewDelegate!.changeCategory(withCategory:lastSelectedCategoryIndex)
        }
        if (lastPriceSwitchStatus != calc!.showPriceConvertButton) {
            viewDelegate!.showPriceConvert(withSwitch: lastPriceSwitchStatus)
        }
        if lastHistorySwitchStatus != calc!.historySwitch {
            viewDelegate!.changeHistorySwitch(withSwitch: lastHistorySwitchStatus)
        }
        if lastRoundingDisplay != calc!.roundingDisplay || lastRoundingCalculation != calc!.rounding || lastDecimalScale != calc!.decimalScale {
            viewDelegate!.changeRoundingSwitch(withScale:lastDecimalScale, roundingDisplay:lastRoundingDisplay, roundingCalculation:lastRoundingCalculation)
        }

    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4    //度量種類、小數位數、單價換算、計算歷程
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: //度量種類有幾條row?
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: //度量種類header
            return "度量種類"
        case 1:
            return "小數位數"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: //度量種類footer 顯示匯率查詢時間及計算說明
            return checkCurrencyTime ()
        case 2: //單價換算
            if lastSelectedCategoryIndex == 3 { //貨幣不能使用單價換算
                return "貨幣不能使用單價換算。"
            } else {
                return "單價換算切到ON，先選公克再輸入1，代表每公克單價1元，然後切換至公斤得每公斤1000元。"
            }
        default:
            return ""
        }
    }

            func checkCurrencyTime () ->String {
                //檢查匯率查詢時間，在section footer顯示
                var footer:String=""
                if let _=calc!.currencyTime {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy/MM/dd hh:mm a"
                    dateFormatter.locale = Locale(identifier: "en_US")
                    if calc!.rateSource == "台灣銀行" {
                        footer=calc!.rateSource+"(即期賣出)掛牌時間："
                    } else if calc!.rateSource == "Yahoo!" {
                        footer=calc!.rateSource+"匯率查詢時間："
                    } else {
                        footer="匯率查詢時間："
                    }
                    footer = footer + dateFormatter.string(from: calc!.currencyTime! as Date)+" \n\n貨幣換算以台幣為基準。例如美元換日圓是美元對台幣價格再換成日圓。"
                } else {
                    footer="等候連網查詢匯率....成功時才會出現「貨幣」選項。"
                }

                return footer
            }



    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: //度量種類的cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellCategory", for: indexPath)
            cell.textLabel!.text = calc!.category[indexPath.row]
            if indexPath.row == lastSelectedCategoryIndex {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        case 1: //section 1 小數位數
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cellSwitch", for: indexPath) as! cellSwitch
                cell.tableCellDelegate=self
                cell.uiSwitch.isOn=lastRoundingDisplay
                cell.uiSwitchLabel.text="顯示數值時固定小數位數"
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cellSwitch", for: indexPath) as! cellSwitch
                cell.tableCellDelegate=self
                cell.uiSwitch.isOn=lastRoundingCalculation
                cell.uiSwitchLabel.text="計算時也要捨入到此位數"
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cellStepper", for: indexPath) as! cellStepper
                cell.tableCellDelegate=self
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.uiStepper.value = lastDecimalScale
                cell.uiStepperLabel.text="小數位數 = "+String(format:"%.0f",cell.uiStepper.value)
                return cell
            default:
                break
            }
        case 2: //section 2 單價換算
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellSwitch", for: indexPath) as! cellSwitch
            cell.tableCellDelegate=self
            cell.uiSwitch.isOn=lastPriceSwitchStatus
            if lastSelectedCategoryIndex == 3 {   //貨幣時不能使用單價換算
                lastPriceSwitchEnabled = false
            } else {
                lastPriceSwitchEnabled = true
            }
            cell.uiSwitch.isEnabled=lastPriceSwitchEnabled
            cell.uiSwitchLabel.text="單價換算開關"
            cell.selectionStyle = UITableViewCellSelectionStyle.none

            return cell
        case 3: //section 3 計算歷程
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellSwitch", for: indexPath) as! cellSwitch
            cell.tableCellDelegate=self
            cell.uiSwitch.isOn = lastHistorySwitchStatus
            cell.uiSwitchLabel.text="計算歷程"
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        default:
            break
        }
        //數錯section數目，否則不應該跑到這裡
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCategory", for: indexPath)
        cell.textLabel!.text = "unknown section?"
        return cell

   }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            //這裡只處理度量種類的選擇，其他設定項目不允許選到row（UITableViewCellSelectionStyle.None）
            if indexPath.row != lastSelectedCategoryIndex {
                let oldCell = tableView.cellForRow(at: IndexPath(row: lastSelectedCategoryIndex, section: 0))
                oldCell!.accessoryType = .none
                let newCell = tableView.cellForRow(at: indexPath)
                newCell!.accessoryType = .checkmark
                lastSelectedCategoryIndex = indexPath.row
                if lastSelectedCategoryIndex == 3 { //貨幣時不能使用單價換算
                    lastPriceSwitchEnabled = false
                    lastPriceSwitchStatus = false
                } else {
                    lastPriceSwitchEnabled = true
                }
                self.tableView.reloadSections(IndexSet(integer: 2), with: UITableViewRowAnimation.automatic)
                setPreference ()
            }
        }
    }


    // cellSwitchDelegate
    func cellSwitchChanged(withStatus status:Bool?,cellSwitch:UITableViewCell?) {
        let indexPath = self.tableView.indexPath(for: cellSwitch!)
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
        setPreference ()
    }

    // cellStepperDelegate
    func cellStepperValueChanged(withCell cell: cellStepper?) {
        let stepper = cell!.uiStepper
        lastDecimalScale = (stepper?.value)!
        cell!.uiStepperLabel.text="小數位數 = "+String(format:"%.0f",(stepper?.value)!)
        setPreference ()
    }

}
