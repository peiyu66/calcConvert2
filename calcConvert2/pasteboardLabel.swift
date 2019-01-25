//
//  pastboardLabel.swift
//  calcConvert2
//
//  Created by peiyu on 2016/2/13.
//  Copyright © 2016年 unLock.com.tw. All rights reserved.
//

import UIKit


class pasteboardLabel: UILabel {

    var delegate:pasteLabelDelegate?
    var isUIOutput:Bool = false

    override var canBecomeFirstResponder : Bool {
        return true
    }


    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action ==  #selector(copy(_:)) {
            return true
        }
        if action == #selector(paste(_:)) && isUIOutput  {
            if let t = UIPasteboard.general.string {
                if let _ = Double(t) {
                    return true
                }
            }
        }
        return false
    }

    override func copy(_ sender: Any?) {
        delegate?.copyLabel(isUIOutput:isUIOutput)
    }

    override func paste(_ sender: Any?) {
        if let t = UIPasteboard.general.string {
            delegate?.pasteLabel(withString: t)
        }
    }
}
