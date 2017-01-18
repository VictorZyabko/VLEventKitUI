//
// VLReminderEditViewController.swift
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
import EventKitUI
import MapKit


@objc
enum VLReminderEditViewAction : Int {
	
	case cancel
	case doneWithChanges
	case doneWithNoChanges
	case delete
	
}


@objc
protocol VLReminderEditViewDelegate : NSObjectProtocol {
	
	func reminderEditViewController(_ controller: VLReminderEditViewController, didCompleteWithAction action: VLReminderEditViewAction)

}


class VLReminderEditViewController: UINavigationController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate,
	VLReminderBaseTableCellDelegate, VLReminderLocationViewDelegate, VLReminderRepeatEndViewDelegate, VLReminderRepeatViewDelegate {
	
	// MARK: - Declarations
	
	private let _reminder: EKReminder
	private let _eventStore: EKEventStore
	private let _locationManager: CLLocationManager?
	
	private var _dataChanged = false
	private var _mainController = UITableViewController(style: UITableViewStyle.grouped)
	private var _cellSections = [[VLReminderBaseTableCell]]()
	private let _cellTitle = VLReminderTextFieldTableCell()
	private let _cellRemindOnDay = VLReminderSwitchTableCell()
	private let _cellAlarm = VLReminderTextLineTableCell()
	private let _cellAlarmDatePicker = VLReminderDatePickerTableCell()
	private var _cellAlarmExpanded = false
	private let _cellRepeat = VLReminderTextLineTableCell()
	private let _cellRepeatEnd = VLReminderTextLineTableCell()
	
	private let _cellLocationOn = VLReminderSwitchTableCell()
	private let _cellLocation = VLReminderTextLineTableCell()
	
	private let _cellPriority = VLReminderPriorityTableCell()
	private let _cellNotes = VLReminderTextViewTableCell()
	
	private let _showDeleteOption: Bool
	private let _cellDelete = VLReminderTextLineTableCell()
	
	private let _originalTitle: String
	private let _originalNotes: String?
	private let _originalStartDateComponents: DateComponents?
	private let _originalDueDateComponents: DateComponents?
	private let _originalAlarms: [EKAlarm]?
	private let _originalRecurrenceRules: [EKRecurrenceRule]?
	private let _originalPriority: Int
	
	// MARK: - Initialize
	
	required init(reminder: EKReminder, eventStore: EKEventStore, locationManager: CLLocationManager?, showDeleteOption: Bool) {
		_reminder = reminder
		_eventStore = eventStore
		_locationManager = locationManager
		_showDeleteOption = showDeleteOption
		
		_originalTitle = _reminder.title
		_originalNotes = _reminder.notes
		_originalStartDateComponents = _reminder.startDateComponents
		_originalDueDateComponents = _reminder.dueDateComponents
		_originalAlarms = _reminder.alarms
		_originalRecurrenceRules = _reminder.recurrenceRules
		_originalPriority = _reminder.priority
		
		super.init(nibName: nil, bundle: nil)
		
		_cellTitle.textField.placeholder = "Title"
		_cellTitle.textField.delegate = self
		
		_cellRemindOnDay.labelTitle.text = "Remind me on a day"
		_cellRemindOnDay.delegate = self
		_cellAlarm.isFullTextHighlighted = true
		_cellAlarm.labelTitle.text = "Alarm"
		_cellAlarmDatePicker.datePicker.datePickerMode = UIDatePickerMode.dateAndTime
		_cellAlarmDatePicker.datePicker.minuteInterval = 5
		_cellAlarmDatePicker.datePicker.addTarget(self, action: #selector(onAlarmDatePickerDidValueChange), for: UIControlEvents.valueChanged)
		_cellRepeat.labelTitle.text = "Repeat"
		_cellRepeat.labelText.text = "Never"
		_cellRepeat.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
		_cellRepeatEnd.labelTitle.text = "End Repeat"
		_cellRepeatEnd.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
		
		_cellLocationOn.labelTitle.text = "Remind me at a location"
		_cellLocationOn.delegate = self
		_cellLocation.labelTitle.text = "Location"
		_cellLocation.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
		_cellLocation.isTextOnBottom = true
		
		_cellPriority.delegate = self
		_cellNotes.labelTitle.text = "Notes"
		_cellNotes.textView.delegate = self
		
		_cellDelete.isFullTextDestructive = true
		_cellDelete.labelFullText.text = "Delete Reminder"
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		_mainController.navigationItem.title = "Details"
		_mainController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(VLReminderEditViewController.onDidCancel))
		_mainController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(VLReminderEditViewController.onDidDone))
		self.pushViewController(_mainController, animated: false)
		
		_mainController.tableView.dataSource = self
		_mainController.tableView.delegate = self
		_mainController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
		
		self.updateViewFromData()
	}
	
	// MARK: - Private
	
	private func updateViewFromData() {
		var cellSections = [[VLReminderBaseTableCell]]()
		
		_cellTitle.textField.text = _reminder.title
		cellSections.append([_cellTitle])
		
		var cellsRemind = [VLReminderBaseTableCell]()
		cellsRemind.append(_cellRemindOnDay)
		
		let dueDateComponents = _reminder.dueDateComponents
		if let dueDateComponents = dueDateComponents {
			_cellRemindOnDay.switchView.isOn = true
			if let date = dueDateComponents.date {
				cellsRemind.append(_cellAlarm)
				if (_cellAlarmExpanded) {
					_cellAlarmDatePicker.datePicker.date = date
					cellsRemind.append(_cellAlarmDatePicker)
				}
				if (_cellAlarmExpanded) {
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = DateFormatter.Style.long
					dateFormatter.timeStyle = DateFormatter.Style.short
					_cellAlarm.labelTitle.text = ""
					_cellAlarm.labelText.text = ""
					_cellAlarm.labelFullText.text = dateFormatter.string(from: date)
				} else {
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = DateFormatter.Style.medium
					dateFormatter.timeStyle = DateFormatter.Style.short
					_cellAlarm.labelTitle.text = "Alarm"
					_cellAlarm.labelText.text = dateFormatter.string(from: date)
					_cellAlarm.labelFullText.text = ""
				}
			}
			cellsRemind.append(_cellRepeat)
			if let recurrenceRule = _reminder.recurrenceRules?.first {
				_cellRepeat.labelText.text = VLEventKitUIUtilities.stringFromRecurrenceRule(recurrenceRule)
				_cellRepeatEnd.labelText.text = VLEventKitUIUtilities.stringFromRecurrenceEnd(recurrenceRule.recurrenceEnd)
				cellsRemind.append(_cellRepeatEnd)
			} else {
				_cellRepeat.labelText.text = VLEventKitUIUtilities.stringFromRecurrenceRule(nil)
				_cellRepeatEnd.labelText.text = VLEventKitUIUtilities.stringFromRecurrenceEnd(nil)
			}
		} else {
			_cellRemindOnDay.switchView.isOn = false
			_cellAlarmExpanded = false
		}
		cellSections.append(cellsRemind)
		
		var cellsLocation = [VLReminderBaseTableCell]()
		cellsLocation.append(_cellLocationOn)
		
		let location: EKStructuredLocation? = VLEventKitUIUtilities.locationFromReminder(_reminder)
		if (location != nil) {
			_cellLocationOn.switchView.isOn = true
			_cellLocation.labelText.text = location!.title
		} else {
			_cellLocation.labelText.text = "None"
		}
		if (_cellLocationOn.switchView.isOn) {
			cellsLocation.append(_cellLocation)
		}
		cellSections.append(cellsLocation)
		
		_cellPriority.priority = _reminder.priority
		_cellNotes.textView.text = _reminder.notes
		cellSections.append([_cellPriority, _cellNotes])
		
		if (_showDeleteOption) {
			cellSections.append([_cellDelete])
		}
		
		var equal = true
		if (_cellSections.count != cellSections.count) {
			equal = false
		} else {
			for i in 0..<_cellSections.count {
				if (_cellSections[i] != cellSections[i]) {
					equal = false
					break
				}
			}
		}
		if (!equal) {
			_cellSections = cellSections
			_mainController.tableView.reloadData()
		}
	}
	
	private func updateDataFromView() {
		
		_reminder.title = _cellTitle.textField.text ?? ""
		
		if (_cellRemindOnDay.switchView.isOn) {
			let date = _cellAlarmDatePicker.datePicker.date
			if (_reminder.dueDateComponents == nil) {
				let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
				let units: Set<Calendar.Component> = [.hour, .minute, .day, .month, .year, .era]
				var dueDateComponents = calendar.dateComponents(units, from: date)
				dueDateComponents.calendar = calendar
				_reminder.dueDateComponents = dueDateComponents
			}
		} else {
			_reminder.dueDateComponents = nil
			_reminder.startDateComponents = nil
			_reminder.recurrenceRules = nil
		}
		
		let alarmWithLocation: EKAlarm? = VLEventKitUIUtilities.alarmWithLocationFromReminder(_reminder)
		if (_cellLocationOn.switchView.isOn) {
			//
		} else {
			if (alarmWithLocation != nil) {
				_reminder.removeAlarm(alarmWithLocation!)
			}
		}
		
		_reminder.priority = _cellPriority.priority
		
		_reminder.notes = _cellNotes.textView.text
		
		_dataChanged = true
	}
	
	// MARK: - Overridable

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return _cellSections.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _cellSections[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return _cellSections[indexPath.section][indexPath.row]
	}
	
	// MARK: - UITableViewDelegate
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let cell = _cellSections[indexPath.section][indexPath.row]
		return cell.optimalHeight()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let cell = _cellSections[indexPath.section][indexPath.row]
		if (cell === _cellAlarm) {
			_cellAlarmExpanded = !_cellAlarmExpanded
			self.updateViewFromData()
		} else if (cell === _cellRepeat) {
			let repeatViewController = VLReminderRepeatViewController(recurrenceRule: _reminder.recurrenceRules?.first)
			repeatViewController.delegate = self
			self.pushViewController(repeatViewController, animated: true)
		} else if (cell === _cellRepeatEnd) {
			let repeatEndViewController = VLReminderRepeatEndViewController(recurrenceEnd: _reminder.recurrenceRules?.first?.recurrenceEnd)
			repeatEndViewController.delegate = self
			self.pushViewController(repeatEndViewController, animated: true)
		} else if (cell === _cellLocation) {
			let locationViewController = VLReminderLocationViewController(originalAlarmWithLocation: VLEventKitUIUtilities.alarmWithLocationFromReminder(_reminder), locationManager: _locationManager)
			locationViewController.delegate = self
			self.pushViewController(locationViewController, animated: true)
		} else if (cell === _cellDelete) {
			self.editViewDelegate?.reminderEditViewController(self, didCompleteWithAction: VLReminderEditViewAction.delete)
		}
	}
	
	// MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return false
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - UITextViewDelegate
	
	func textViewDidEndEditing(_ textView: UITextView) {
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - VLReminderBaseTableCellDelegate
	
	func reminderBaseTableCell(_ cell: VLReminderBaseTableCell, didValueChange param: AnyObject?) {
		if (cell == _cellRemindOnDay) {
			if (_cellRemindOnDay.switchView.isOn) {
				_reminder.dueDateComponents = nil
				// Round to next Hour
				var date = _cellAlarmDatePicker.datePicker.date
				date = Date(timeIntervalSince1970: Double(Int64(ceil(date.timeIntervalSince1970 / 3600)) * 3600)) as Date
				_cellAlarmDatePicker.datePicker.date = date
			}
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - VLReminderLocationViewDelegate
	
	func reminderLocationViewController(_ controller: VLReminderLocationViewController, didDataChange param: AnyObject?) {
		_dataChanged = true
		while let alarm = VLEventKitUIUtilities.alarmWithLocationFromReminder(_reminder) {
			_reminder.removeAlarm(alarm)
		}
		if let alarm = controller.selectedAlarmWithLocation {
			_reminder.addAlarm(alarm)
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - VLReminderRepeatEndViewDelegate
	
	func reminderRepeatEndViewController(_ controller: VLReminderRepeatEndViewController, didDataChange param: AnyObject?) {
		_dataChanged = true
		if let recurrenceRule = _reminder.recurrenceRules?.first {
			recurrenceRule.recurrenceEnd = controller.recurrenceEnd
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - VLReminderRepeatViewDelegate
	
	func reminderRepeatViewController(_ controller: VLReminderRepeatViewController, didDataChange param: AnyObject?) {
		_dataChanged = true
		if let recurrenceRule = controller.recurrenceRule {
			_reminder.recurrenceRules = [recurrenceRule]
		} else {
			_reminder.recurrenceRules = nil
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - Event handlers
	
	func onAlarmDatePickerDidValueChange() {
		_reminder.dueDateComponents = nil
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	func onDidCancel() {
		if (_dataChanged) {
			_reminder.title = _originalTitle
			_reminder.notes = _originalNotes
			_reminder.startDateComponents = _originalStartDateComponents
			_reminder.dueDateComponents = _originalDueDateComponents
			_reminder.alarms = _originalAlarms
			_reminder.recurrenceRules = _originalRecurrenceRules
			_reminder.priority = _originalPriority
		}
		self.editViewDelegate?.reminderEditViewController(self, didCompleteWithAction: VLReminderEditViewAction.cancel)
	}
	
	func onDidDone() {
		if (_cellTitle.textField.isFirstResponder) {
			_cellTitle.textField.resignFirstResponder()
		}
		if (_cellNotes.textView.isFirstResponder) {
			_cellNotes.textView.resignFirstResponder()
		}
		let sError = ""
		if (!sError.isEmpty) {
			let alert = UIAlertController(title: "Error", message: sError, preferredStyle: UIAlertControllerStyle.alert)
			alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
			return
		}
		self.editViewDelegate?.reminderEditViewController(self, didCompleteWithAction:
			_dataChanged ? VLReminderEditViewAction.doneWithChanges : VLReminderEditViewAction.doneWithNoChanges)
	}
	
	// MARK: - Public interface
	
	weak var editViewDelegate: VLReminderEditViewDelegate?
	
	var reminder: EKReminder {
		get {
			return _reminder
		}
	}
	
	// MARK: -

}
