//
//  TableViewController.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/22.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol tableViewDelegate: class {
    func changedSetting(withIndex index: Int?, priceConverting: Bool?)
}

class TableViewController: UITableViewController ,cellDelegate {

    var calc:calcConvert?
    var lastSelectedIndexPath:NSIndexPath?
    var lastSwitchStatus:Bool=false
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


    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkCurrencyTime()
     }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if (lastSelectedIndexPath?.row != calc!.categoryIndex || lastSwitchStatus != calc!.priceConverting) {

            viewDelegate?.changedSetting(withIndex: lastSelectedIndexPath?.row, priceConverting: lastSwitchStatus)
        }

    }


    func checkCurrencyTime () {
        //檢查匯率查詢時間，在說明欄顯示
        if let _=calc!.currencyTime {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd hh:mm a"
            dateFormatter.locale = NSLocale(localeIdentifier: "us")
            uiMessage.text=helpMessage+"匯率查詢時間："+dateFormatter.stringFromDate(calc!.currencyTime!)
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
        }
        return 1
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
            let cell = tableView.dequeueReusableCellWithIdentifier("cellPriceConverting", forIndexPath: indexPath) as! cellPriceConverting
            cell.tableCellDelegate=self
            lastSwitchStatus=calc!.priceConverting
            cell.uiPriceConverting.on=lastSwitchStatus
            if calc!.categoryIndex == 3 {
                cell.uiPriceConverting.enabled = false
            } else {
                cell.uiPriceConverting.enabled = true
            }
            uiPriceConverting=cell.uiPriceConverting
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
                    lastSwitchStatus = false
                } else {
                    uiPriceConverting?.enabled = true
                }
                let newCell = tableView.cellForRowAtIndexPath(indexPath)
                newCell?.accessoryType = .Checkmark
                lastSelectedIndexPath = indexPath
            }
        }
    }


    func priceConvertingChanged(withStatus status:Bool?) {
        lastSwitchStatus=status!

    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */


    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
}
