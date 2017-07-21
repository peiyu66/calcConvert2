//
//  pastboardLabel.swift
//  calcConvert2
//
//  Created by peiyu on 2016/2/13.
//  Copyright © 2016年 unLock.com.tw. All rights reserved.
//

import UIKit

protocol pasteLabelDelegate: class {
    func pasteLabel(withString pasteString: String)
    func copyLabel()

}

class pasteboardLabel: UILabel {

    var Delegate:pasteLabelDelegate?

    override var canBecomeFirstResponder : Bool {
        return true
    }


    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action ==  #selector(copy(_:)) {
            return true
        }
        if action == #selector(paste(_:)) {
            if let t = UIPasteboard.general.string {
                if let _ = Double(t) {
                    return true
                }
            }
        }
        return false
    }

    override func copy(_ sender: Any?) {
        Delegate?.copyLabel()
    }

    override func paste(_ sender: Any?) {
        if let t = UIPasteboard.general.string {
            Delegate?.pasteLabel(withString: t)
        }
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
}
