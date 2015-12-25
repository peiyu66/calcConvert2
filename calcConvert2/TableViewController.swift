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
}

class TableViewController: UITableViewController ,cellDelegate {

    var calc:calcConvert?
    var lastSelectedIndexPath:NSIndexPath?
    var lastPriceSwitchStatus:Bool=false
    var lastHistorySwitchStatus:Bool=false
    var viewDelegate:tableViewDelegate?
    var uiPriceConverting:UISwitch?
    var currencyTime:String=""

    @IBOutlet weak var uiMessage: UITextView!

    let helpMessage:String = "使用單價換算：先選公克再輸入1，代表每公克單價1元，然後切換至公斤得每公斤1000元。這就是單價換算的操作方式。\n\n"


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        checkCurrencyTime()

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
        if (lastSelectedIndexPath?.row != calc!.categoryIndex) ||  lastPriceSwitchStatus != calc!.priceConverting {
            //只要category變了必須帶動刷新PriceConverting（顯示是否帶單價符號的單位名稱），所以不必重複叫
            if (lastSelectedIndexPath?.row != calc!.categoryIndex) {
                viewDelegate?.changeCategory(withCategory:(lastSelectedIndexPath?.row)!, priceConverting:lastPriceSwitchStatus)
            } else {
                viewDelegate?.changePriceConverting(withSwitch: lastPriceSwitchStatus)
            }
         }
        if lastHistorySwitchStatus != calc!.historySwitch {
            viewDelegate?.changeHistorySwitch(withSwitch: lastHistorySwitchStatus)
        }

    }


    func checkCurrencyTime () {
        //檢查匯率查詢時間，在說明欄顯示
        if let _=calc!.currencyTime {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd hh:mm a"
            dateFormatter.locale = NSLocale(localeIdentifier: "us")
            uiMessage.text=helpMessage+"Yahoo!匯率查詢時間："+dateFormatter.stringFromDate(calc!.currencyTime!)+" \n\n為了消除換算誤差，匯率將以美金為基準。例如台幣換日圓是台幣對美金價格再換成日幣，而不是採市場的台幣對日幣價格。"
        } else {
            uiMessage.text=helpMessage+"還在等候連網取得匯率查詢，成功時度量種類才會出現匯兌選項。"
        }

    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if calc!.category.count == (calc!.categoryList.count + 1) {
                checkCurrencyTime ()
            }
            return calc!.category.count
        } else {
            return 2
        }
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("cellCategory", forIndexPath: indexPath)
            cell.textLabel!.text = calc!.category[indexPath.row]
            if indexPath.row == calc!.categoryIndex {
                cell.accessoryType = .Checkmark
                lastSelectedIndexPath=indexPath
            } else {
                cell.accessoryType = .None
            }
            return cell
        } else {
//        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("cellSwitch", forIndexPath: indexPath) as! cellSwitch
            cell.tableCellDelegate=self
            if indexPath.row == 1 {
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                lastPriceSwitchStatus=calc!.priceConverting
                cell.uiSwitch.on=lastPriceSwitchStatus
                cell.uiSwitchLabel.text="單價換算"
                if calc!.categoryIndex == 3 {
                    cell.uiSwitch.enabled = false
                } else {
                    cell.uiSwitch.enabled = true
                }
                uiPriceConverting=cell.uiSwitch
            } else {
                lastHistorySwitchStatus=calc!.historySwitch
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.uiSwitch.on=lastHistorySwitchStatus
                cell.uiSwitchLabel.text="計算歷程"
            }
            return cell
        }
   }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row != lastSelectedIndexPath?.row {
                if let lastSelectedIndexPath = lastSelectedIndexPath {
                    let oldCell = tableView.cellForRowAtIndexPath(lastSelectedIndexPath)
                    oldCell?.accessoryType = .None
                }
                if indexPath.row == 3 {
                    uiPriceConverting?.on = false
                    uiPriceConverting?.enabled = false
                    lastPriceSwitchStatus = false
                } else {
                    uiPriceConverting?.enabled = true
                }
                let newCell = tableView.cellForRowAtIndexPath(indexPath)
                newCell?.accessoryType = .Checkmark
                lastSelectedIndexPath = indexPath
            }
        }
    }


    func cellSwitchChanged(withStatus status:Bool?,cellSwitch:UITableViewCell?) {
        let indexPath = self.tableView.indexPathForCell(cellSwitch!)
        if indexPath!.row == 1 {
            lastPriceSwitchStatus=status!
        } else {
            lastHistorySwitchStatus=status!
        }

    }

}
