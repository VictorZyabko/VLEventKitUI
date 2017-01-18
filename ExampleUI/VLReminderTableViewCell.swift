//
// VLReminderTableViewCell.swift
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
import EventKit


protocol VLReminderTableViewCellDelegate: NSObjectProtocol {
	
	func reminderTableViewCell(_ cell: VLReminderTableViewCell, didReminderCompletionTap param: AnyObject?)
	
}


class VLReminderTableViewCell: UITableViewCell {
	
	// MARK: - Public declarations
	
	weak var delegate: VLReminderTableViewCellDelegate? = nil
	
	// MARK: - Declarations
	
	private let _eventStore: EKEventStore
	private var _reminder: EKReminder? = nil
	private let _backView = UIView()
	private let _switchView = UIImageView()
	private let _labelPriority = UILabel()
	private let _labelTitle = UILabel()
	private let _labelDateFuture = UILabel()
	private let _labelDateOverdue = UILabel()
	private let _labelNotes = UILabel()
	private let _insets = UIEdgeInsetsMake(4, 1, 4, 4)
	private let _distX: CGFloat = 2.0
	private let _tap = UITapGestureRecognizer();
	private var _isHighlighted = false
	
	// MARK: - Initialize
	
	required init(eventStore: EKEventStore, reuseIdentifier: String?) {
		_eventStore = eventStore
		super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
		self.initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/*override func awakeFromNib() {
		super.awakeFromNib()
		self.initialize()
	}*/
	
	func initialize() {
		self.backgroundColor = UIColor.clear
		
		_backView.isHidden = !_isHighlighted
		self.contentView.addSubview(_backView)
		
		_switchView.isUserInteractionEnabled = false
		self.contentView.addSubview(_switchView)
		
		for label in [_labelPriority, _labelTitle, _labelDateFuture, _labelDateOverdue, _labelNotes] {
			label.backgroundColor = UIColor.clear
			label.text = ""
			self.contentView.addSubview(label)
		}
		
		_tap.delegate = self
		_tap.addTarget(self, action: #selector(onTap(tap:)))
		self.addGestureRecognizer(_tap)
		
		let alphaGrayed: CGFloat = 0.75
		_backView.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.03)
		_switchView.alpha = alphaGrayed
		_labelPriority.font = UIFont.systemFont(ofSize: 15)
		_labelPriority.textColor = UIColor(red: 241/255.0, green: 67/255.0, blue: 59/255.0, alpha: 1.0)
		_labelTitle.font = UIFont.systemFont(ofSize: 15)
		_labelTitle.textColor = UIColor(white: 0.0, alpha: 1.0)
		_labelDateFuture.font = UIFont.systemFont(ofSize: 14)
		_labelDateFuture.textColor = UIColor(white: (255 - 193)/255.0, alpha: 1.0)
		_labelDateOverdue.font = UIFont.systemFont(ofSize: 14)
		_labelDateOverdue.textColor = UIColor(red: 241/255.0, green: 67/255.0, blue: 59/255.0, alpha: 1.0)
		_labelNotes.font = UIFont.systemFont(ofSize: 14)
		_labelNotes.textColor = UIColor(white: (255 - 193)/255.0, alpha: 1.0)
		_labelNotes.alpha = alphaGrayed
		
		NotificationCenter.default.addObserver(self, selector: #selector(onEventStoreDidChange(obj:)), name: NSNotification.Name.EKEventStoreChanged, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EKEventStoreChanged, object: nil)
	}
	
	// MARK: - Private
	
	private func updateView() {
		if let reminder = _reminder {
			/*!
			@property   priority
			@abstract   The priority of the reminder.
			@discussion Priorities run from 1 (highest) to 9 (lowest).  A priority of 0 means no priority.
			Saving a reminder with any other priority will fail.
			Per RFC 5545, priorities of 1-4 are considered "high," a priority of 5 is "medium," and priorities of 6-9 are "low."
			*/
			var sPriority = ""
			let priority = reminder.priority
			if (priority >= 1 && priority <= 4) {
				sPriority = "!!!"
			}
			if (priority >= 5 && priority <= 5) {
				sPriority = "!!"
			}
			if (priority >= 6 && priority <= 9) {
				sPriority = "!"
			}
			if (_labelPriority.text != sPriority) {
				_labelPriority.text = sPriority
				self.setNeedsLayout()
			}
			
			let sTitle = reminder.title
			if (_labelTitle.text != sTitle) {
				_labelTitle.text = sTitle
				self.setNeedsLayout()
			}
			// Find date
			var sDate = ""
			if let date = VLEventKitUIUtilities.dateFromReminder(reminder) {
				let isToday = VLEventKitUIUtilities.isToday(date: date)
				let isTomorrow = VLEventKitUIUtilities.isTomorrow(date: date)
				let dateFormatter = DateFormatter()
				if (isToday || isTomorrow) {
					dateFormatter.dateStyle = DateFormatter.Style.none
				} else {
					dateFormatter.dateStyle = DateFormatter.Style.short
				}
				dateFormatter.timeStyle = DateFormatter.Style.short
				sDate = dateFormatter.string(from: date)
				if (isToday) {
					sDate = NSLocalizedString("Today", comment: "") + ", " + sDate
				} else if (isTomorrow) {
					sDate = NSLocalizedString("Tomorrow", comment: "") + ", " + sDate
				}
				if (date.compare(Date()) == ComparisonResult.orderedAscending) {
					_labelDateFuture.isHidden = true
					_labelDateOverdue.isHidden = false
				} else {
					_labelDateFuture.isHidden = false
					_labelDateOverdue.isHidden = true
				}
			}
			
			var sNotes = reminder.notes ?? ""
			if (sNotes.isEmpty) {
				if let location = VLEventKitUIUtilities.locationFromReminder(reminder) {
					sNotes = location.title
				}
			}
			if (_labelDateFuture.text != sDate) {
				_labelDateFuture.text = sDate
				self.setNeedsLayout()
			}
			if (_labelDateOverdue.text != sDate) {
				_labelDateOverdue.text = sDate
				self.setNeedsLayout()
			}
			if (_labelNotes.text != sNotes) {
				_labelNotes.text = sNotes
				self.setNeedsLayout()
			}
			_switchView.image = reminder.isCompleted ? UIImage(named: "reminder_mark_completed") : UIImage(named: "reminder_mark_uncompleted")
			_labelTitle.numberOfLines = (_labelDateFuture.text!.isEmpty && _labelNotes.text!.isEmpty) ? 0 : 1
		}
	}
	
	// MARK: - Layout
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let rcBnds = self.contentView.bounds
		_backView.frame = rcBnds;
		let distX: CGFloat = 4.0
		let rcCtrls = UIEdgeInsetsInsetRect(rcBnds, _insets)
		var rcSwitchFull = rcCtrls
		rcSwitchFull.size.width = rcSwitchFull.size.height
		var rcSwitch = rcSwitchFull
		rcSwitch.size = CGSize(width: 20, height: 20)
		if (rcSwitch.size.width < rcSwitchFull.size.width && rcSwitch.size.height < rcSwitchFull.size.height) {
			rcSwitch.origin.x = rcSwitchFull.midX - rcSwitch.size.width / 2.0
			rcSwitch.origin.y = rcSwitchFull.midY - rcSwitch.size.height / 2.0
		} else {
			rcSwitch = rcSwitchFull
		}
		_switchView.frame = rcSwitch
		var rcTexts = rcCtrls
		rcTexts.origin.x = rcSwitchFull.maxX + _distX
		rcTexts.size.width = rcCtrls.maxX - rcTexts.origin.x
		
		var rcLbTitleLine = rcTexts
		rcLbTitleLine.size.height /= 2.0
		
		var rcDate = rcTexts
		rcDate.origin.y = rcLbTitleLine.maxY
		rcDate.size.height = rcTexts.maxY - rcDate.origin.y
		
		var rcNotes = rcTexts
		rcNotes.origin.y = rcLbTitleLine.maxY
		rcNotes.size.height = rcTexts.maxY - rcNotes.origin.y
		
		if (!_labelDateFuture.text!.isEmpty && !_labelNotes.text!.isEmpty) {
			rcDate.size.width = _labelDateFuture.sizeThatFits(rcDate.size).width
			rcNotes.origin.x = rcDate.maxX + distX
			rcNotes.size.width = rcTexts.maxX - rcNotes.origin.x
		}
		
		if (_labelDateFuture.text!.isEmpty && _labelNotes.text!.isEmpty) {
			rcLbTitleLine.size.height = rcNotes.maxY - rcLbTitleLine.origin.y
			rcNotes.size.height = 0.0
		}
		
		var rcLbPriority = rcLbTitleLine
		rcLbPriority.size.width = 0.0
		var rcLbTitle = rcLbTitleLine
		if (!_labelPriority.text!.isEmpty) {
			rcLbPriority.size.width = ceil(_labelPriority.sizeThatFits(rcLbPriority.size).width)
			rcLbTitle.origin.x = ceil(rcLbPriority.maxX + distX)
			rcLbTitle.size.width = rcLbTitleLine.maxX - rcLbTitle.origin.x
		}
		
		_labelPriority.frame = rcLbPriority
		_labelTitle.frame = rcLbTitle
		_labelDateFuture.frame = rcDate
		_labelDateOverdue.frame = rcDate
		_labelNotes.frame = rcNotes
	}
	
	// MARK: - UIGestureRecognizerDelegate
	
	override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let point = gestureRecognizer.location(in: self)
		var rect = _switchView.frame
		rect.origin.x -= _insets.left
		rect.origin.y -= _insets.top
		rect.size.width += _insets.left + _distX
		rect.size.height += _insets.top + _insets.bottom
		if (rect.contains(point)) {
			if (gestureRecognizer == _tap) {
				return true
			} else {
				return false
			}
		} else {
			if (gestureRecognizer == _tap) {
				return false
			} else {
				return true
			}
		}
	}
	
	// MARK: - Events
	
	func onEventStoreDidChange(obj: AnyObject?) {
		self.updateView()
	}
	
	func onTap(tap: UITapGestureRecognizer) {
		if (tap.state == UIGestureRecognizerState.ended) {
			self.delegate?.reminderTableViewCell(self, didReminderCompletionTap: nil)
		}
	}
	
	// MARK: - Public
	
	var reminder: EKReminder? {
		get {
			return _reminder
		}
		set {
			if (_reminder != newValue) {
				_reminder = newValue
				self.updateView()
			}
		}
	}
	
	// MARK: -

}



