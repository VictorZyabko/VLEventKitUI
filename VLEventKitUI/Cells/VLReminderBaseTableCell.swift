//
// VLReminderBaseTableCell.swift
//
// Copyright (c) 2015 Victor Zyabko (https://github.com/VictorZyabko/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit


@objc
protocol VLReminderBaseTableCellDelegate: NSObjectProtocol {
	
	@objc optional func reminderBaseTableCell(_ cell: VLReminderBaseTableCell, didValueChange param: AnyObject?)
	
}


class VLReminderBaseTableCell: UITableViewCell {

	weak var delegate: VLReminderBaseTableCellDelegate?
	
	init() {
		super.init(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.clipsToBounds = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func contentInsets() -> UIEdgeInsets {
		return UIEdgeInsetsMake(2, 8, 2, 8)
	}
	
	func optimalHeight() -> CGFloat {
		return 44.0
	}
	
	func textColorDefault() -> UIColor {
		return UIColor.black
	}
	
	func textColorGrayed() -> UIColor {
		return UIColor.gray
	}
	
	func textColorHighlighted() -> UIColor {
		return UIColor.blue
	}
	
	func textColorDestructive() -> UIColor {
		return UIColor.red
	}

}
