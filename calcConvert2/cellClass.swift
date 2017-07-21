//
//  TableViewCell.swift
//  calcConvert2
//
//  Created by peiyu on 2015/12/22.
//  Copyright © 2015年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol cellSwitchDelegate: class {
    func cellSwitchChanged(withStatus status:Bool?,cellSwitch:UITableViewCell?)

}

class cellSwitch: UITableViewCell {

    var tableCellDelegate:cellSwitchDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }


    @IBOutlet weak var uiSwitchLabel: UILabel!
    @IBOutlet weak var uiSwitch: UISwitch!

    @IBAction func uiChangedSwitchStatus(_ sender: UISwitch) {
        
        tableCellDelegate?.cellSwitchChanged(withStatus: sender.isOn,cellSwitch:self)
    }

}

protocol cellStepperDelegate: class {
    func cellStepperValueChanged(withCell cell: cellStepper?)

}

class cellStepper: UITableViewCell {

    var tableCellDelegate:cellStepperDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var uiStepperLabel: UILabel!
    @IBOutlet weak var uiStepper: UIStepper!


    @IBAction func uiValueChanged(_ sender: UIStepper) {
        tableCellDelegate?.cellStepperValueChanged(withCell: self)
    }


}
