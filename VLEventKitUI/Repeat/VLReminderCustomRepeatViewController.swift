//
// VLReminderCustomRepeatViewController.swift
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


protocol VLReminderCustomRepeatViewDelegate : NSObjectProtocol {
	
	func reminderCustomRepeatViewController(_ controller: VLReminderCustomRepeatViewController, didDataChange param: AnyObject?)
	
}


class VLReminderCustomRepeatViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, VLReminderBaseTableCellDelegate {
	
	// MARK: - Declarations
	
	private var _recurrenceRule: EKRecurrenceRule?
	private var _cellSections = [[VLReminderBaseTableCell]]()
	private let _cellFrequency = VLReminderTextLineTableCell()
	private let _cellFrequencyPicker = VLReminderPickerTableCell()
	private var _cellFrequencyPickerExpanded = false
	private let _cellEvery = VLReminderTextLineTableCell()
	private let _cellEveryPicker = VLReminderPickerTableCell()
	private var _cellEveryPickerExpanded = false
	
	private var _cellsWeekdays = [VLReminderTextLineTableCell]()
	
	private let _cellEach = VLReminderTextLineTableCell()
	private let _cellOnThe = VLReminderTextLineTableCell()
	private let _cellMonthDays = VLReminderGridTableCell(itemTitles: VLEventKitUIUtilities.daysOfMonth, itemSize: CGSize(width: 45, height: 45))
	
	private let _cellYearMonths = VLReminderGridTableCell(itemTitles: VLEventKitUIUtilities.monthsOfYearShort, itemSize: CGSize(width: 80, height: 50))
	
	private let _cellDaysOfWeekPicker = VLReminderPickerTableCell()
	private var _cellDaysOfWeekPickerHasPosition = false
	private var _cellDaysOfWeekPickerHasDayOfWeek = false
	private var _cachedSetPositions: [NSNumber]?
	
	private let _cellYearDaysOfWeek = VLReminderSwitchTableCell()
	
	// MARK: - Initialize
	
	convenience init() {
		self.init(style: UITableViewStyle.grouped)
		
		_cellFrequency.labelTitle.text = "Frequency"
		_cellFrequencyPicker.pickerView.dataSource = self
		_cellFrequencyPicker.pickerView.delegate = self
		_cellEvery.labelTitle.text = "Every"
		_cellEveryPicker.pickerView.dataSource = self
		_cellEveryPicker.pickerView.delegate = self
		
		let daysOfWeek = VLEventKitUIUtilities.daysOfWeek
		for i in 0..<daysOfWeek.count {
			let cell = VLReminderTextLineTableCell()
			cell.labelTitle.text = daysOfWeek[i]
			_cellsWeekdays.append(cell)
		}
		
		_cellEach.labelTitle.text = "Each"
		_cellOnThe.labelTitle.text = "On the..."
		_cellMonthDays.delegate = self
		
		_cellYearMonths.delegate = self
		
		_cellDaysOfWeekPicker.pickerView.dataSource = self
		_cellDaysOfWeekPicker.pickerView.delegate = self
		
		_cellYearDaysOfWeek.labelTitle.text = "Days of week"
		_cellYearDaysOfWeek.delegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.title = "Custom"
		
		self.tableView.dataSource = self
		self.tableView.delegate = self
	}
	
	// MARK: - Private
	
	private func updateViewFromData() {
		if let recurrenceRule = _recurrenceRule {
			
			_cellFrequencyPicker.pickerView.reloadAllComponents()
			_cellEveryPicker.pickerView.reloadAllComponents()
			_cellDaysOfWeekPicker.pickerView.reloadAllComponents()
			
			var cellSections = [[VLReminderBaseTableCell]]()
			
			var cells = [VLReminderBaseTableCell]()
			cells.append(_cellFrequency)
			if (_cellFrequencyPickerExpanded) {
				cells.append(_cellFrequencyPicker)
			}
			cells.append(_cellEvery)
			if (_cellEveryPickerExpanded) {
				cells.append(_cellEveryPicker)
			}

			let frequency = recurrenceRule.frequency
			let interval = recurrenceRule.interval
			if (frequency == EKRecurrenceFrequency.daily) {
				_cellFrequency.labelText.text = "Daily"
				if (interval == 1) {
					_cellEvery.labelText.text = "Day"
				} else {
					_cellEvery.labelText.text = String(format: "%d days", interval)
				}
				_cellFrequencyPicker.pickerView.selectRow(0, inComponent: 0, animated: false)
			} else if (frequency == EKRecurrenceFrequency.weekly) {
				_cellFrequency.labelText.text = "Weekly"
				if (interval == 1) {
					_cellEvery.labelText.text = "Week"
				} else {
					_cellEvery.labelText.text = String(format: "%d weeks", interval)
				}
				_cellFrequencyPicker.pickerView.selectRow(1, inComponent: 0, animated: false)
			} else if (frequency == EKRecurrenceFrequency.monthly) {
				_cellFrequency.labelText.text = "Monthly"
				if (interval == 1) {
					_cellEvery.labelText.text = "Month"
				} else {
					_cellEvery.labelText.text = String(format: "%d months", interval)
				}
				_cellFrequencyPicker.pickerView.selectRow(2, inComponent: 0, animated: false)
			} else if (frequency == EKRecurrenceFrequency.yearly) {
				_cellFrequency.labelText.text = "Yearly"
				if (interval == 1) {
					_cellEvery.labelText.text = "Year"
				} else {
					_cellEvery.labelText.text = String(format: "%d years", interval)
				}
				_cellFrequencyPicker.pickerView.selectRow(3, inComponent: 0, animated: false)
			}

			cellSections.append(cells)
			
			if (frequency == EKRecurrenceFrequency.weekly) {
				cellSections.append(_cellsWeekdays)
			}
			if let daysOfTheWeek = recurrenceRule.daysOfTheWeek {
				for (index, cell) in _cellsWeekdays.enumerated() {
					let weekday = VLEventKitUIUtilities.weekdayFromNumber(index + 1)
					if (daysOfTheWeek.contains(EKRecurrenceDayOfWeek(weekday))) {
						cell.accessoryType = UITableViewCellAccessoryType.checkmark
					} else {
						cell.accessoryType = UITableViewCellAccessoryType.none
					}
				}
			} else {
				for cell in _cellsWeekdays {
					cell.accessoryType = UITableViewCellAccessoryType.none
				}
			}
			
			if (recurrenceRule.setPositions != nil) {
				_cachedSetPositions = recurrenceRule.setPositions
			}
			let setPositions = recurrenceRule.setPositions ?? [NSNumber]()
			let numPosition: NSNumber? = setPositions.count > 0 ? setPositions[0] : nil
			if (numPosition != nil) {
				var iPos = numPosition!.intValue - 1
				let count = _cellDaysOfWeekPicker.pickerView.numberOfRows(inComponent: 0)
				if (iPos < 0) {
					iPos = count - 1
				}
				if (iPos >= 0 && iPos < count) {
					_cellDaysOfWeekPickerHasPosition = true
					_cellDaysOfWeekPicker.pickerView.selectRow(iPos, inComponent: 0, animated: false)
				}
				let daysOfTheWeek = recurrenceRule.daysOfTheWeek ?? [EKRecurrenceDayOfWeek]()
				if (daysOfTheWeek.count > 0) {
					_cellDaysOfWeekPickerHasDayOfWeek = true
					let dayOfWeek = daysOfTheWeek[0]
					let iDay = VLEventKitUIUtilities.numberFromWeekday(dayOfWeek.dayOfTheWeek) - 1
					let count = _cellDaysOfWeekPicker.pickerView.numberOfRows(inComponent: 1)
					if (iDay >= 0 && iDay < count) {
						_cellDaysOfWeekPicker.pickerView.selectRow(iDay, inComponent: 1, animated: false)
					}
				} else {
					_cellDaysOfWeekPickerHasDayOfWeek = false
				}
			} else {
				_cellDaysOfWeekPickerHasPosition = false
				_cellDaysOfWeekPickerHasDayOfWeek = false
			}
			
			if (frequency == EKRecurrenceFrequency.monthly) {
				var cells = [VLReminderBaseTableCell]()
				cells.append(_cellEach)
				cells.append(_cellOnThe)
				if (numPosition != nil) {
					cells.append(_cellDaysOfWeekPicker)
					_cellEach.accessoryType = UITableViewCellAccessoryType.none
					_cellOnThe.accessoryType = UITableViewCellAccessoryType.checkmark
				} else {
					cells.append(_cellMonthDays)
					_cellEach.accessoryType = UITableViewCellAccessoryType.checkmark
					_cellOnThe.accessoryType = UITableViewCellAccessoryType.none
				}
				cellSections.append(cells)
			}
			let daysOfTheMonth = recurrenceRule.daysOfTheMonth ?? [NSNumber]()
			let sDaysOfMonthAll = VLEventKitUIUtilities.daysOfMonth
			var sDaysOfTheMonth = Set<String>()
			for num in daysOfTheMonth {
				let iVal = num.intValue - 1
				if (iVal >= 0 && iVal < sDaysOfMonthAll.count) {
					sDaysOfTheMonth.insert(sDaysOfMonthAll[iVal])
				}
			}
			_cellMonthDays.selectedItems = sDaysOfTheMonth
			
			if (frequency == EKRecurrenceFrequency.yearly) {
				var selectedItems = Set<String>()
				let monthsOfYearShort = VLEventKitUIUtilities.monthsOfYearShort
				let monthsOfTheYear = recurrenceRule.monthsOfTheYear ?? [NSNumber]()
				for num in monthsOfTheYear {
					let iVal = num.intValue - 1
					if (iVal >= 0 && iVal < monthsOfYearShort.count) {
						selectedItems.insert(monthsOfYearShort[iVal])
					}
				}
				_cellYearMonths.selectedItems = selectedItems
				var cells = [VLReminderBaseTableCell]()
				cells.append(_cellYearMonths)
				cellSections.append(cells)
				
				cells = [VLReminderBaseTableCell]()
				cells.append(_cellYearDaysOfWeek)
				if let _ = recurrenceRule.daysOfTheWeek {
					_cellYearDaysOfWeek.switchView.isOn = true
					cells.append(_cellDaysOfWeekPicker)
				} else {
					_cellYearDaysOfWeek.switchView.isOn = false
				}
				cellSections.append(cells)
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
				self.tableView.reloadData()
			}
			
			_cellEveryPicker.pickerView.reloadAllComponents()
		}
	}
	
	private func updateDataFromView() {
		var frequency = EKRecurrenceFrequency.daily
		switch (_cellFrequencyPicker.pickerView.selectedRow(inComponent: 0)) {
			case 0:
				frequency = EKRecurrenceFrequency.daily
			case 1:
				frequency = EKRecurrenceFrequency.weekly
			case 2:
				frequency = EKRecurrenceFrequency.monthly
			case 3:
				frequency = EKRecurrenceFrequency.yearly
			default:
				frequency = EKRecurrenceFrequency.daily
		}
		
		let interval = _cellEveryPicker.pickerView.selectedRow(inComponent: 0) + 1
		
		var daysOfTheWeek = [EKRecurrenceDayOfWeek]()
		if (frequency == EKRecurrenceFrequency.weekly) {
			for (index, cell) in _cellsWeekdays.enumerated() {
				if (cell.accessoryType == UITableViewCellAccessoryType.checkmark) {
					let weekday = VLEventKitUIUtilities.weekdayFromNumber(index + 1)
					daysOfTheWeek.append(EKRecurrenceDayOfWeek(weekday))
				}
			}
		} else if (frequency == EKRecurrenceFrequency.monthly) {
			if (_cellEach.accessoryType == UITableViewCellAccessoryType.checkmark) {
				
			} else if (_cellOnThe.accessoryType == UITableViewCellAccessoryType.checkmark) {
				let index = _cellDaysOfWeekPicker.pickerView.selectedRow(inComponent: 1)
				let weekday = VLEventKitUIUtilities.weekdayFromNumber(index + 1)
				daysOfTheWeek.append(EKRecurrenceDayOfWeek(weekday))
			}
		}
		
		var setPositions: [NSNumber]? = nil
		if (_recurrenceRule != nil) {
			setPositions = _recurrenceRule!.setPositions
		}
		if (frequency == EKRecurrenceFrequency.monthly) {
			if (_cellOnThe.accessoryType == UITableViewCellAccessoryType.checkmark) {
				let index = _cellDaysOfWeekPicker.pickerView.selectedRow(inComponent: 0)
				let recurrenceRuleSetPositions = VLEventKitUIUtilities.recurrenceRuleSetPositions
				if (index >= 0 && index < recurrenceRuleSetPositions.count) {
					setPositions = [NSNumber]()
					if (index == recurrenceRuleSetPositions.count - 1) {
						setPositions!.append(NSNumber(value: -1))
					} else {
						setPositions!.append(NSNumber(value: index + 1))
					}
				}
			}
		}
		
		var daysOfTheMonth = [NSNumber]()
		if (frequency == EKRecurrenceFrequency.monthly) {
			if (_cellEach.accessoryType == UITableViewCellAccessoryType.checkmark) {
				let allItems = VLEventKitUIUtilities.daysOfMonth
				var selectedItems = _cellMonthDays.selectedItems
				if (selectedItems.count == 0) {
					selectedItems.insert(allItems[0])
					_cellMonthDays.selectedItems = selectedItems
				}
				for (index, sItem) in allItems.enumerated() {
					if (selectedItems.contains(sItem)) {
						daysOfTheMonth.append(NSNumber(value: index + 1))
					}
				}
				setPositions = nil
			}
		}
		
		var monthsOfTheYear = [NSNumber]()
		if (frequency == EKRecurrenceFrequency.yearly) {
			let allItems = VLEventKitUIUtilities.monthsOfYearShort
			var selectedItems = _cellYearMonths.selectedItems
			if (selectedItems.count == 0) {
				selectedItems.insert(allItems[0])
				_cellYearMonths.selectedItems = selectedItems
			}
			for (index, sItem) in allItems.enumerated() {
				if (selectedItems.contains(sItem)) {
					monthsOfTheYear.append(NSNumber(value: index + 1))
				}
			}
			if (_cellYearDaysOfWeek.switchView.isOn) {
				daysOfTheWeek = [EKRecurrenceDayOfWeek]()
				let index1 = _cellDaysOfWeekPicker.pickerView.selectedRow(inComponent: 1)
				let weekday = VLEventKitUIUtilities.weekdayFromNumber(index1 + 1)
				daysOfTheWeek.append(EKRecurrenceDayOfWeek(weekday))
				
				let index0 = _cellDaysOfWeekPicker.pickerView.selectedRow(inComponent: 0)
				let recurrenceRuleSetPositions = VLEventKitUIUtilities.recurrenceRuleSetPositions
				if (index0 >= 0 && index0 < recurrenceRuleSetPositions.count) {
					setPositions = [NSNumber]()
					if (index0 == recurrenceRuleSetPositions.count - 1) {
						setPositions!.append(NSNumber(value: -1))
					} else {
						setPositions!.append(NSNumber(value: index0 + 1))
					}
				}
			}
		}
		
		var recurrenceEnd: EKRecurrenceEnd? = nil
		if (_recurrenceRule != nil) {
			recurrenceEnd = _recurrenceRule!.recurrenceEnd
		}
		
		_recurrenceRule = EKRecurrenceRule(recurrenceWith: frequency,
		                                   interval: interval,
		                                   daysOfTheWeek: daysOfTheWeek.count > 0 ? daysOfTheWeek : nil,
		                                   daysOfTheMonth: daysOfTheMonth.count > 0 ? daysOfTheMonth : nil,
		                                   monthsOfTheYear: monthsOfTheYear.count > 0 ? monthsOfTheYear : nil,
		                                   weeksOfTheYear: nil,
		                                   daysOfTheYear: nil,
		                                   setPositions: setPositions,
		                                   end: recurrenceEnd)
		
		self.processDataChanged()
	}
	
	private func processDataChanged() {
		self.delegate?.reminderCustomRepeatViewController(self, didDataChange: nil)
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
		if let cellGrid = cell as? VLReminderGridTableCell {
			return cellGrid.optimalHeightForWidth(tableView.frame.size.width)
		}
		return cell.optimalHeight()
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let cell = _cellSections[indexPath.section][indexPath.row]
		let cellTextLine = cell as? VLReminderTextLineTableCell
		if (cell == _cellFrequency) {
			_cellFrequencyPickerExpanded = !_cellFrequencyPickerExpanded
			_cellEveryPickerExpanded = false
		} else if (cell == _cellEvery) {
			_cellFrequencyPickerExpanded = false
			_cellEveryPickerExpanded = !_cellEveryPickerExpanded
		} else if (cellTextLine != nil && _cellsWeekdays.contains(cellTextLine!)) {
			if (cell.accessoryType == UITableViewCellAccessoryType.checkmark) {
				cell.accessoryType = UITableViewCellAccessoryType.none
			} else if (cell.accessoryType == UITableViewCellAccessoryType.none) {
				cell.accessoryType = UITableViewCellAccessoryType.checkmark
			}
			var count = 0
			for obj in _cellsWeekdays {
				if (obj.accessoryType == UITableViewCellAccessoryType.checkmark) {
					count += 1
				}
			}
			if (count == 0) {
				cell.accessoryType = UITableViewCellAccessoryType.checkmark
			}
		} else if (cell == _cellEach) {
			_cellEach.accessoryType = UITableViewCellAccessoryType.checkmark
			_cellOnThe.accessoryType = UITableViewCellAccessoryType.none
			if (_cellMonthDays.selectedItems.count == 0) {
				_cellMonthDays.selectedItems = [VLEventKitUIUtilities.daysOfMonth[0]]
			}
		} else if (cell == _cellOnThe) {
			_cellEach.accessoryType = UITableViewCellAccessoryType.none
			_cellOnThe.accessoryType = UITableViewCellAccessoryType.checkmark
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - UIPickerViewDataSource
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		if (pickerView == _cellFrequencyPicker.pickerView) {
			return 1
		} else if (pickerView == _cellEveryPicker.pickerView) {
			return 2
		} else if (pickerView == _cellDaysOfWeekPicker.pickerView) {
			return 2
		}
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if (component == 0) {
			if (pickerView == _cellFrequencyPicker.pickerView) {
				return 4
			} else if (pickerView == _cellEveryPicker.pickerView) {
				return 999
			} else if (pickerView == _cellDaysOfWeekPicker.pickerView) {
				return VLEventKitUIUtilities.recurrenceRuleSetPositions.count
			}
		} else if (component == 1) {
			if (pickerView == _cellEveryPicker.pickerView) {
				return 1
			} else if (pickerView == _cellDaysOfWeekPicker.pickerView) {
				return VLEventKitUIUtilities.daysOfWeek.count
			}
		}
		return 0
	}
	
	// MARK: - UIPickerViewDelegate
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		if (component == 0) {
			if (pickerView == _cellFrequencyPicker.pickerView) {
				return ["Daily", "Weekly", "Monthly", "Yearly"][row]
			} else if (pickerView == _cellEveryPicker.pickerView) {
				return String(format: "%d", row + 1)
			} else if (pickerView == _cellDaysOfWeekPicker.pickerView) {
				return VLEventKitUIUtilities.recurrenceRuleSetPositions[row]
			}
		} else if (component == 1) {
			if (pickerView == _cellEveryPicker.pickerView) {
				let index = _cellFrequencyPicker.pickerView.selectedRow(inComponent: 0)
				let count = _cellEveryPicker.pickerView.selectedRow(inComponent: 0) + 1
				if (index == 0) {
					return (count == 1) ? "day" : "days"
				} else if (index == 1) {
					return (count == 1) ? "week" : "weeks"
				} else if (index == 2) {
					return (count == 1) ? "month" : "months"
				} else if (index == 3) {
					return (count == 1) ? "year" : "years"
				}
			} else if (pickerView == _cellDaysOfWeekPicker.pickerView) {
				return VLEventKitUIUtilities.daysOfWeek[row]
			}
		}
		return ""
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if (pickerView == _cellFrequencyPicker.pickerView) {
			if (row == 1) {
				var count = 0
				for cell in _cellsWeekdays {
					if (cell.accessoryType == UITableViewCellAccessoryType.checkmark) {
						count += 1
					}
				}
				if (count == 0) {
					_cellsWeekdays[0].accessoryType = UITableViewCellAccessoryType.checkmark
				}
			} else if (row == 2) {
				if (_cellMonthDays.selectedItems.count == 0) {
					_cellMonthDays.selectedItems = [VLEventKitUIUtilities.daysOfMonth[0]]
				}
				if (_cellEach.accessoryType == UITableViewCellAccessoryType.none
					&& _cellOnThe.accessoryType == UITableViewCellAccessoryType.none) {
					_cellEach.accessoryType = UITableViewCellAccessoryType.checkmark
				}
			} else if (row == 3) {
				if (_cellYearMonths.selectedItems.count == 0) {
					_cellYearMonths.selectedItems = [VLEventKitUIUtilities.monthsOfYearShort[0]]
				}
			}
		}
		self.updateDataFromView()
		self.updateViewFromData()
	}
	
	// MARK: - VLReminderBaseTableCellDelegate
	
	func reminderBaseTableCell(_ cell: VLReminderBaseTableCell, didValueChange param: AnyObject?) {
		if (cell == _cellMonthDays) {
			if (_cellMonthDays.selectedItems.count == 0) {
				_cellMonthDays.selectedItems = _cellMonthDays.previousSelectedItems
			}
			self.updateDataFromView()
			self.updateViewFromData()
		} else if (cell == _cellYearMonths) {
			if (_cellYearMonths.selectedItems.count == 0) {
				_cellYearMonths.selectedItems = _cellYearMonths.previousSelectedItems
			}
			self.updateDataFromView()
			self.updateViewFromData()
		} else if (cell == _cellYearDaysOfWeek) {
			self.updateDataFromView()
			self.updateViewFromData()
		}
	}
	
	// MARK: - Public interface
	
	weak var delegate: VLReminderCustomRepeatViewDelegate?
	
	var recurrenceRule: EKRecurrenceRule? {
		get {
			return _recurrenceRule
		}
		set {
			if (_recurrenceRule !== newValue) {
				_recurrenceRule = newValue
				self.updateViewFromData()
			}
		}
	}
	
	// MARK: -

}
