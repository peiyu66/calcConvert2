//
//  TableViewCell.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/22.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol cellDelegate: class {
    func priceConvertingChanged(withStatus status:Bool?)
}

class cellPriceConverting: UITableViewCell {

    var tableCellDelegate:cellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }


    @IBOutlet weak var uiPriceConverting: UISwitch!

    @IBAction func uiChangedPriceConverting(sender: UISwitch) {
        
        tableCellDelegate?.priceConvertingChanged(withStatus: sender.on)
    }

}
