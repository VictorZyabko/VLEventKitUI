//
// VLReminderPriorityTableCell.swift
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

class VLReminderPriorityTableCell: VLReminderBaseTableCell {

	private let _labelTitle = UILabel()
	private let _switchView = UISegmentedControl()
	private var _priority = 0
	
	override init() {
		super.init()
		self.selectionStyle = UITableViewCellSelectionStyle.none
		_labelTitle.text = "Priority"
		self.contentView.addSubview(_labelTitle)
		self.contentView.addSubview(_switchView)
		/*!
		@property   priority
		@abstract   The priority of the reminder.
		@discussion Priorities run from 1 (highest) to 9 (lowest).  A priority of 0 means no priority.
		Saving a reminder with any other priority will fail.
		Per RFC 5545, priorities of 1-4 are considered "high," a priority of 5 is "medium," and priorities of 6-9 are "low."
		*/
		_switchView.insertSegment(withTitle: "None", at: _switchView.numberOfSegments, animated: false)
		_switchView.insertSegment(withTitle: "!", at: _switchView.numberOfSegments, animated: false)
		_switchView.insertSegment(withTitle: "!!", at: _switchView.numberOfSegments, animated: false)
		_switchView.insertSegment(withTitle: "!!!", at: _switchView.numberOfSegments, animated: false)
		_switchView.addTarget(self, action: #selector(onSwitchDidValueChange), for: UIControlEvents.valueChanged)
		self.updateViewFromData()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func updateViewFromData() {
		if (_priority >= 1 && _priority <= 4) {
			_switchView.selectedSegmentIndex = 3
		} else if (_priority >= 5 && _priority <= 5) {
			_switchView.selectedSegmentIndex = 2
		} else if (_priority >= 6 && _priority <= 9) {
			_switchView.selectedSegmentIndex = 1
		} else {
			_switchView.selectedSegmentIndex = 0
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let rcCont = UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentInsets())
		_labelTitle.frame = rcCont
		var rcSwith = rcCont
		rcSwith.size = _switchView.sizeThatFits(rcSwith.size)
		rcSwith.origin.x = rcCont.maxX - rcSwith.size.width
		rcSwith.origin.y = rcCont.midY - rcSwith.size.height / 2.0
		_switchView.frame = rcSwith
	}
	
	func onSwitchDidValueChange() {
		switch (_switchView.selectedSegmentIndex) {
			case 3:
				_priority = 1
			case 2:
				_priority = 5
			case 1:
				_priority = 9
			default:
				_priority = 0
		}
		self.updateViewFromData()
		self.delegate?.reminderBaseTableCell?(self, didValueChange: nil)
	}
	
	var priority: Int {
		get {
			return _priority
		}
		set {
			if (_priority != newValue) {
				_priority = newValue
				self.updateViewFromData()
			}
		}
	}

}
