//
// VLReminderRepeatViewController.swift
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


protocol VLReminderRepeatViewDelegate : NSObjectProtocol {
	
	func reminderRepeatViewController(_ controller: VLReminderRepeatViewController, didDataChange param: AnyObject?)
	
}


class VLReminderRepeatViewController: UITableViewController, VLReminderCustomRepeatViewDelegate {
	
	// MARK: - Declarations
	
	private var _recurrenceRule: EKRecurrenceRule?
	private var _cellSections = [[VLReminderTextLineTableCell]]()
	private var _cellsEvery = [VLReminderTextLineTableCell]()
	private let _cellNever = VLReminderTextLineTableCell()
	private let _cellEveryDay = VLReminderTextLineTableCell()
	private let _cellEveryWeek = VLReminderTextLineTableCell()
	private let _cellEvery2Weeks = VLReminderTextLineTableCell()
	private let _cellEveryMonth = VLReminderTextLineTableCell()
	private let _cellEveryYear = VLReminderTextLineTableCell()
	private let _cellCustom = VLReminderTextLineTableCell()
	
	// MARK: - Initialize
	
	convenience init(recurrenceRule: EKRecurrenceRule?) {
		self.init(style: UITableViewStyle.grouped)
		if (recurrenceRule != nil) {
			var recurrenceEndNew: EKRecurrenceEnd? = nil
			if let recurrenceEnd = recurrenceRule!.recurrenceEnd {
				if (recurrenceEnd.endDate != nil) {
					recurrenceEndNew = EKRecurrenceEnd(end: recurrenceEnd.endDate!)
				} else {
					recurrenceEndNew = EKRecurrenceEnd(occurrenceCount: recurrenceEnd.occurrenceCount)
				}
			}
			_recurrenceRule = EKRecurrenceRule(recurrenceWith: recurrenceRule!.frequency,
			                                   interval: recurrenceRule!.interval,
			                                   daysOfTheWeek: recurrenceRule!.daysOfTheWeek,
			                                   daysOfTheMonth: recurrenceRule!.daysOfTheMonth,
			                                   monthsOfTheYear: recurrenceRule!.monthsOfTheYear,
			                                   weeksOfTheYear: recurrenceRule!.weeksOfTheYear,
			                                   daysOfTheYear: recurrenceRule!.daysOfTheYear,
			                                   setPositions: recurrenceRule!.setPositions,
			                                   end: recurrenceEndNew)
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = "Repeat"
		
		_cellNever.labelTitle.text = "Never"
		_cellsEvery.append(_cellNever)
		_cellEveryDay.labelTitle.text = "Every Day"
		_cellsEvery.append(_cellEveryDay)
		_cellEveryWeek.labelTitle.text = "Every Week"
		_cellsEvery.append(_cellEveryWeek)
		_cellEvery2Weeks.labelTitle.text = "Every 2 Weeks"
		_cellsEvery.append(_cellEvery2Weeks)
		_cellEveryMonth.labelTitle.text = "Every Month"
		_cellsEvery.append(_cellEveryMonth)
		_cellEveryYear.labelTitle.text = "Every Year"
		_cellsEvery.append(_cellEveryYear)
		_cellSections.append(_cellsEvery)
		
		_cellCustom.labelTitle.text = "Custom"
		_cellCustom.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
		_cellSections.append([_cellCustom])
		
		self.tableView.dataSource = self
		self.tableView.delegate = self
		
		self.updateViewFromData()
	}
	
	// MARK: - Private
	
	private func updateViewFromData() {
		self.tableView.reloadData()
		if let recurrenceRule = _recurrenceRule {
			let frequency = recurrenceRule.frequency
			let interval = recurrenceRule.interval
			var cellChecked: UITableViewCell? = _cellCustom
			if (frequency == EKRecurrenceFrequency.daily) {
				if (interval == 1) {
					cellChecked = _cellEveryDay
				}
			} else if (frequency == EKRecurrenceFrequency.weekly) {
				if (recurrenceRule.daysOfTheWeek != nil && recurrenceRule.daysOfTheWeek!.count == 0) {
					if (interval == 1) {
						cellChecked = _cellEveryWeek
					} else if (interval == 2) {
						cellChecked = _cellEvery2Weeks
					}
				}
			} else if (frequency == EKRecurrenceFrequency.monthly) {
				if (recurrenceRule.daysOfTheWeek != nil && recurrenceRule.daysOfTheWeek!.count == 0
					&& recurrenceRule.daysOfTheMonth != nil && recurrenceRule.daysOfTheMonth!.count == 0) {
					if (interval == 1) {
						cellChecked = _cellEveryMonth
					}
				}
			} else if (frequency == EKRecurrenceFrequency.yearly) {
				if (recurrenceRule.monthsOfTheYear != nil && recurrenceRule.monthsOfTheYear!.count == 0) {
					if (interval == 1) {
						cellChecked = _cellEveryYear
					}
				}
			}
			for cells in _cellSections {
				for cell in cells {
					if (cell == cellChecked) {
						if (cell.accessoryType == UITableViewCellAccessoryType.disclosureIndicator) {
							cell.isTitleHighlighted = true
						} else {
							cell.accessoryType = UITableViewCellAccessoryType.checkmark
						}
					} else {
						if (cell.accessoryType == UITableViewCellAccessoryType.disclosureIndicator) {
							cell.isTitleHighlighted = false
						} else {
							cell.accessoryType = UITableViewCellAccessoryType.none
						}
					}
				}
			}
		} else {
			for cells in _cellSections {
				for cell in cells {
					if (cell.accessoryType == UITableViewCellAccessoryType.disclosureIndicator) {
						cell.isTitleHighlighted = false
					} else {
						if (cell == _cellNever) {
							cell.accessoryType = UITableViewCellAccessoryType.checkmark
						} else {
							cell.accessoryType = UITableViewCellAccessoryType.none
						}
					}
				}
			}
		}
	}
	
	private func processDataChanged() {
		self.delegate?.reminderRepeatViewController(self, didDataChange: nil)
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
		if (cell == _cellCustom) {
			let customRepeatViewController = VLReminderCustomRepeatViewController()
			customRepeatViewController.delegate = self
			customRepeatViewController.recurrenceRule = _recurrenceRule ?? EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.daily, interval: 1, end: nil)
			self.navigationController!.pushViewController(customRepeatViewController, animated: true)
			return
		}
		var frequency = EKRecurrenceFrequency.daily
		var interval = 0
		if (cell == _cellNever) {
			frequency = EKRecurrenceFrequency.daily
			interval = -1
		} else if (cell == _cellEveryDay) {
			frequency = EKRecurrenceFrequency.daily
			interval = 1
		} else if (cell == _cellEveryWeek) {
			frequency = EKRecurrenceFrequency.weekly
			interval = 1
		} else if (cell == _cellEvery2Weeks) {
			frequency = EKRecurrenceFrequency.weekly
			interval = 2
		} else if (cell == _cellEveryMonth) {
			frequency = EKRecurrenceFrequency.monthly
			interval = 1
		} else if (cell == _cellEveryYear) {
			frequency = EKRecurrenceFrequency.yearly
			interval = 1
		}
		var recurrenceRuleNew = _recurrenceRule
		if (interval > 0) {
			recurrenceRuleNew = EKRecurrenceRule(recurrenceWith: frequency, interval: interval, end: nil)
		} else if (interval == -1) {
			recurrenceRuleNew = nil
		}
		if (_recurrenceRule !== recurrenceRuleNew) {
			_recurrenceRule = recurrenceRuleNew
			self.updateViewFromData()
			self.processDataChanged()
		}
	}
	
	// MARK: - VLReminderCustomRepeatViewDelegate
	
	func reminderCustomRepeatViewController(_ controller: VLReminderCustomRepeatViewController, didDataChange param: AnyObject?) {
		_recurrenceRule = controller.recurrenceRule
		self.updateViewFromData()
		self.processDataChanged()
	}
	
	// MARK: - Public interface
	
	weak var delegate: VLReminderRepeatViewDelegate?
	
	var recurrenceRule: EKRecurrenceRule? {
		get {
			return _recurrenceRule
		}
	}
	
	// MARK: -

}
