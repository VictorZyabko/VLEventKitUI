//
// VLReminderRepeatEndViewController.swift
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


protocol VLReminderRepeatEndViewDelegate : NSObjectProtocol {
	
	func reminderRepeatEndViewController(_ controller: VLReminderRepeatEndViewController, didDataChange param: AnyObject?)
	
}


class VLReminderRepeatEndViewController: UITableViewController {
	
	// MARK: - Declarations
	
	private var _recurrenceEnd: EKRecurrenceEnd? = nil
	private var _cellSections = [[VLReminderBaseTableCell]]()
	private let _cellForever = VLReminderTextLineTableCell()
	private let _cellEndDate = VLReminderTextLineTableCell()
	private let _cellEndDatePicker = VLReminderDatePickerTableCell()
	
	// MARK: - Initialize
	
	convenience init(recurrenceEnd: EKRecurrenceEnd?) {
		self.init(style: UITableViewStyle.grouped)
		if (recurrenceEnd != nil) {
			if (recurrenceEnd!.endDate != nil) {
				_recurrenceEnd = EKRecurrenceEnd(end: recurrenceEnd!.endDate!)
			} else {
				_recurrenceEnd = EKRecurrenceEnd(occurrenceCount: recurrenceEnd!.occurrenceCount)
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "End Repeat"
		
		_cellForever.labelTitle.text = "Repeat Forever"
		_cellEndDate.labelTitle.text = "End Repeat Date"
		_cellEndDatePicker.datePicker.datePickerMode = UIDatePickerMode.date
		_cellEndDatePicker.datePicker.minuteInterval = 5
		_cellEndDatePicker.selectionStyle = UITableViewCellSelectionStyle.none
		_cellEndDatePicker.datePicker.addTarget(self, action: #selector(onDatePickerDidValueChange), for: UIControlEvents.valueChanged)
		
		self.tableView.dataSource = self
		self.tableView.delegate = self
		
		self.updateViewFromData()
	}
	
	// MARK: - Private
	
	private func updateViewFromData() {
		var cellSections = [[VLReminderBaseTableCell]]()
		
		var cells = [VLReminderBaseTableCell]()
		if let recurrenceEnd = _recurrenceEnd {
			_cellForever.accessoryType = UITableViewCellAccessoryType.none
			cells.append(_cellForever)
			_cellEndDate.accessoryType = UITableViewCellAccessoryType.checkmark
			cells.append(_cellEndDate)
			if let endDate = recurrenceEnd.endDate {
				_cellEndDatePicker.datePicker.date = endDate
			}
			cells.append(_cellEndDatePicker)
		} else {
			_cellForever.accessoryType = UITableViewCellAccessoryType.checkmark
			cells.append(_cellForever)
			_cellEndDate.accessoryType = UITableViewCellAccessoryType.none
			cells.append(_cellEndDate)
		}
		cellSections.append(cells)
		
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
			self.tableView.reloadData()
		}
	}
	
	private func updateDataFromView() {
		if (_cellForever.accessoryType == UITableViewCellAccessoryType.checkmark) {
			_recurrenceEnd = nil
		} else {
			let date = _cellEndDatePicker.datePicker.date
			_recurrenceEnd = EKRecurrenceEnd(end: date)
		}
		self.processDataChanged()
	}
	
	private func processDataChanged() {
		self.delegate?.reminderRepeatEndViewController(self, didDataChange: nil)
	}
	
	// MARK: - UITableViewDataSource
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return _cellSections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _cellSections[section].count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return _cellSections[indexPath.section][indexPath.row]
	}
	
	// MARK: - UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let cell = _cellSections[indexPath.section][indexPath.row]
		return cell.optimalHeight()
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let cell = _cellSections[indexPath.section][indexPath.row]
		if (cell == _cellForever) {
			_cellForever.accessoryType = UITableViewCellAccessoryType.checkmark
			_cellEndDate.accessoryType = UITableViewCellAccessoryType.none
		} else if (cell == _cellEndDate) {
			_cellForever.accessoryType = UITableViewCellAccessoryType.none
			_cellEndDate.accessoryType = UITableViewCellAccessoryType.checkmark
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - Event handlers
	
	func onDatePickerDidValueChange() {
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - Public interface
	
	weak var delegate: VLReminderRepeatEndViewDelegate?
	
	var recurrenceEnd: EKRecurrenceEnd? {
		get {
			return _recurrenceEnd
		}
	}
	
	// MARK: -

}
