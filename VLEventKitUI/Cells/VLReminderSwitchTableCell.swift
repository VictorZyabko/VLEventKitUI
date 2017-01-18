//
// VLReminderSwitchTableCell.swift
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

class VLReminderSwitchTableCell: VLReminderBaseTableCell {

	let labelTitle = UILabel()
	let switchView = UISwitch()
	
	override init() {
		super.init()
		self.selectionStyle = UITableViewCellSelectionStyle.none
		self.contentView.addSubview(labelTitle)
		self.contentView.addSubview(switchView)
		switchView.addTarget(self, action: #selector(onSwitchDidValueChange), for: UIControlEvents.valueChanged)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let rcCont = UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentInsets())
		labelTitle.frame = rcCont
		var rcSwith = rcCont
		rcSwith.size = switchView.sizeThatFits(rcSwith.size)
		rcSwith.origin.x = rcCont.maxX - rcSwith.size.width
		rcSwith.origin.y = rcCont.midY - rcSwith.size.height / 2.0
		switchView.frame = rcSwith
	}
	
	func onSwitchDidValueChange() {
		self.delegate?.reminderBaseTableCell?(self, didValueChange: nil)
	}

}
