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

    override func canBecomeFirstResponder() -> Bool {
        return true
    }


    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(NSObject.copy(_:)) {
            return true
        }
        if action == #selector(NSObject.paste(_:)) {
            if let t = UIPasteboard.generalPasteboard().string {
                if let _ = Double(t) {
                    return true
                }
            }
        }
        return false
    }

    override func copy(sender: AnyObject?) {
        Delegate?.copyLabel()
    }

    override func paste(sender: AnyObject?) {
        if let t = UIPasteboard.generalPasteboard().string {
            Delegate?.pasteLabel(withString: t)
        }
        let menu = UIMenuController.sharedMenuController()
        menu.setMenuVisible(false, animated: true)
    }
}
