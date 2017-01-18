//
// VLRemindersViewController.swift
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

class VLRemindersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIToolbarDelegate,// UIBarPositioningDelegate,
	VLReminderEditViewDelegate, VLReminderTableViewCellDelegate {
	
	// MARK: - Declarations
	
	private let _locationManager: CLLocationManager?
	
	private let _eventStore = EKEventStore()
	
	private var _reminders = [EKReminder]()
	private var _sectionsDates = [Date]()
	private var _mapSectionsDates = [Date: [EKReminder]]()
	private var _dateNone = Date(timeIntervalSince1970: 0)
	
	private var _showCompletedItems = false
	private var _showItemsWithNoDate = false
	
	private var _loadingRemindersCounter = 0
	private var _loadingRemindersTicket = 0
	
	private var _eventStoreAccessGranted = false

	private let _tableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
	private let _toolbar = UIToolbar()
	private var _accessDeniedView = AccessDeniedView()
	private let _buttonAdd = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: nil, action: nil)
	private let _buttonAll = UIBarButtonItem(title: "Show All", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
	private let _buttonScheduled = UIBarButtonItem(title: "Show Scheduled", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
	private let _buttonShowCompleted = UIBarButtonItem(title: "Show Completed", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
	private let _buttonHideCompleted = UIBarButtonItem(title: "Hide Completed", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
	
	// MARK: - Initialize
	
	required init(locationManager: CLLocationManager?) {
		_locationManager = locationManager
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.white
		
		self.title = "Reminders"
		
		_tableView.rowHeight = 45.0
		_tableView.separatorInset = UIEdgeInsets.zero
		_tableView.layoutMargins = UIEdgeInsets.zero
		_tableView.dataSource = self
		_tableView.delegate = self
		
		self.view.addSubview(_tableView)
		_tableView.translatesAutoresizingMaskIntoConstraints = false
		
		_buttonAdd.target = self
		_buttonAdd.action = #selector(onButtonAddDidTap(sender:))
		_buttonAll.target = self
		_buttonAll.action = #selector(onButtonAllDidTap(sender:))
		_buttonScheduled.target = self
		_buttonScheduled.action = #selector(onButtonScheduledDidTap(sender:))
		_buttonShowCompleted.target = self
		_buttonShowCompleted.action = #selector(onButtonShowCompletedDidTap(sender:))
		_buttonHideCompleted.target = self
		_buttonHideCompleted.action = #selector(onButtonHideCompletedDidTap(sender:))
		
		_toolbar.delegate = self
		self.view.addSubview(_toolbar)
		_toolbar.translatesAutoresizingMaskIntoConstraints = false
		_toolbar.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
		
		_accessDeniedView.isHidden = true
		self.view.addSubview(_accessDeniedView)
		_accessDeniedView.translatesAutoresizingMaskIntoConstraints = false
		
		let tableView_constraint_W = NSLayoutConstraint(item: _tableView,
		                                                attribute: NSLayoutAttribute.width,
		                                                relatedBy: NSLayoutRelation.equal,
		                                                toItem: self.view,
		                                                attribute: NSLayoutAttribute.width,
		                                                multiplier: 1.0,
		                                                constant: 0)
		let tableView_constraint_T = NSLayoutConstraint(item: _tableView,
		                                                attribute: NSLayoutAttribute.top,
		                                                relatedBy: NSLayoutRelation.equal,
		                                                toItem: self.view,
		                                                attribute: NSLayoutAttribute.top,
		                                                multiplier: 1.0,
		                                                constant: 0)
		let tableView_constraint_B = NSLayoutConstraint(item: _tableView,
		                                                attribute: NSLayoutAttribute.bottom,
		                                                relatedBy: NSLayoutRelation.equal,
		                                                toItem: _toolbar,
		                                                attribute: NSLayoutAttribute.top,
		                                                multiplier: 1.0,
		                                                constant: 0)
		self.view.addConstraint(tableView_constraint_W)
		self.view.addConstraint(tableView_constraint_T)
		self.view.addConstraint(tableView_constraint_B)
		
		let toolbar_constraint_W = NSLayoutConstraint(item: _toolbar,
		                                              attribute: NSLayoutAttribute.width,
		                                              relatedBy: NSLayoutRelation.equal,
		                                              toItem: self.view,
		                                              attribute: NSLayoutAttribute.width,
		                                              multiplier: 1.0,
		                                              constant: 0)
		let toolbar_constraint_B = NSLayoutConstraint(item: _toolbar,
		                                                attribute: NSLayoutAttribute.bottom,
		                                                relatedBy: NSLayoutRelation.equal,
		                                                toItem: self.view,
		                                                attribute: NSLayoutAttribute.bottom,
		                                                multiplier: 1.0,
		                                                constant: 0)
		self.view.addConstraint(toolbar_constraint_W)
		self.view.addConstraint(toolbar_constraint_B)
		
		let accessDeniedView_constraint_W = NSLayoutConstraint(item: _accessDeniedView,
		                                              attribute: NSLayoutAttribute.width,
		                                              relatedBy: NSLayoutRelation.equal,
		                                              toItem: self.view,
		                                              attribute: NSLayoutAttribute.width,
		                                              multiplier: 1.0,
		                                              constant: 0)
		let accessDeniedView_constraint_H = NSLayoutConstraint(item: _accessDeniedView,
		                                                       attribute: NSLayoutAttribute.height,
		                                                       relatedBy: NSLayoutRelation.equal,
		                                                       toItem: self.view,
		                                                       attribute: NSLayoutAttribute.height,
		                                                       multiplier: 1.0,
		                                                       constant: 0)
		self.view.addConstraint(accessDeniedView_constraint_W)
		self.view.addConstraint(accessDeniedView_constraint_H)
		
		_eventStore.requestAccess(to: EKEntityType.reminder, completion: { (granted: Bool, error: Error?) in
			DispatchQueue.main.async(execute: { 
				if (error != nil) {
					self.showError(error!)
				}
				self.checkAuthorizationStatus()
			})
		})
		
		NotificationCenter.default.addObserver(self, selector: #selector(onEventStoreDidChange(obj:)), name: NSNotification.Name.EKEventStoreChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidBecomeActive(obj:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
		
		self.checkAuthorizationStatus()
		self.updateView()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		_toolbar.invalidateIntrinsicContentSize()
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EKEventStoreChanged, object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
	}
	
	// MARK: - Private
	
	private func showError(withText errorText: String) {
		NSLog("ERROR: %@", errorText)
		let alert = UIAlertController(title: "Error", message: errorText, preferredStyle: UIAlertControllerStyle.alert)
		alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
	private func showError(_ error: Error) {
		self.showError(withText: error.localizedDescription)
	}
	
	private func startLoadReminders() {
		let dateNow = Date()
		let calendar = Calendar.current
		let timezone = TimeZone.current
		var components = calendar.dateComponents(in: timezone, from: dateNow)
		components.hour = 0
		components.minute = 0
		components.second = 0
		let dateStart = calendar.date(from: components)!
		components.hour = 23
		components.minute = 59
		components.second = 59

		var componentsEnd = DateComponents()
		componentsEnd.day = 10000 // Days to append to end date
		componentsEnd.hour = 23
		componentsEnd.minute = 59
		componentsEnd.second = 59
		let dateEnd = calendar.date(byAdding: componentsEnd, to: dateStart)
		
		let remindersIncompletePredicate =
			_eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: _showItemsWithNoDate ? nil : dateEnd, calendars: nil)
		var remindersIncomplete = [EKReminder]()
		
		let remindersCompletedPredicate =
			_eventStore.predicateForCompletedReminders(withCompletionDateStarting: _showItemsWithNoDate ? nil : dateStart, ending: _showItemsWithNoDate ? nil : dateEnd, calendars: nil)
		var remindersCompleted = [EKReminder]()
		
		var reminders = [EKReminder]()
		
		let dispatchGroup = DispatchGroup()
		
		_loadingRemindersTicket += 1
		let loadingRemindersTicket = _loadingRemindersTicket
		_loadingRemindersCounter += 1
		
		dispatchGroup.enter()
		_eventStore.fetchReminders(matching: remindersIncompletePredicate, completion: { (remindersFetched: [EKReminder]?) in
			DispatchQueue.main.async(execute: {
				self._loadingRemindersCounter -= 1
				if (loadingRemindersTicket != self._loadingRemindersTicket) {
					dispatchGroup.leave()
					return
				}
				let remindersToAdd = remindersFetched ?? [EKReminder]()
				remindersIncomplete.append(contentsOf: remindersToAdd)
				dispatchGroup.leave()
			})
		})
		
		if (_showCompletedItems) {
			dispatchGroup.enter()
			_eventStore.fetchReminders(matching: remindersCompletedPredicate, completion: { (remindersFetched: [EKReminder]?) in
				DispatchQueue.main.async(execute: {
					self._loadingRemindersCounter -= 1
					if (loadingRemindersTicket != self._loadingRemindersTicket) {
						dispatchGroup.leave()
						return
					}
					let remindersToAdd = remindersFetched ?? [EKReminder]()
					remindersCompleted.append(contentsOf: remindersToAdd)
					dispatchGroup.leave()
				})
			})
		}
		
		dispatchGroup.notify(queue: DispatchQueue.main, execute: { 
			if (loadingRemindersTicket != self._loadingRemindersTicket) {
				return
			}
			reminders.append(contentsOf: remindersIncomplete)
			reminders.append(contentsOf: remindersCompleted)
			reminders.sort(by: { (reminder1: EKReminder, reminder2: EKReminder) -> Bool in
				let date1 = VLEventKitUIUtilities.dateFromReminder(reminder1)
				let date2 = VLEventKitUIUtilities.dateFromReminder(reminder2)
				if (date1 != nil && date2 != nil) {
					var result = date1!.compare(date2!)
					if (result == ComparisonResult.orderedSame) {
						result = reminder1.title.compare(reminder2.title)
					}
					return result == ComparisonResult.orderedAscending
				} else if (date1 != nil && date2 == nil) {
					return false
				} else if (date1 == nil && date2 != nil) {
					return true
				} else {
					return false
				}
			})
			if (self._reminders != reminders) {
				self._reminders = reminders
				
				// Update _mapSectionsDates
				var sectionsDates = [Date]()
				var mapSectionsDates = [Date: [EKReminder]]()
				for reminder in reminders {
					var date = self._dateNone
					if let dateRem = VLEventKitUIUtilities.dateFromReminder(reminder) {
						let componentsOrig = calendar.dateComponents(in: timezone, from: dateRem)
						var componentsNew = DateComponents()
						componentsNew.calendar = calendar
						componentsNew.year = componentsOrig.year
						componentsNew.month = componentsOrig.month
						componentsNew.day = componentsOrig.day
						date = calendar.date(from: componentsNew) ?? date
					} else {
						date = self._dateNone
					}
					if (mapSectionsDates[date] == nil) {
						mapSectionsDates[date] = [EKReminder]()
						sectionsDates.append(date)
					}
					mapSectionsDates[date]!.append(reminder)
				}
				self._sectionsDates = sectionsDates
				self._mapSectionsDates = mapSectionsDates
				
				self._tableView.reloadData()
			}
		})
	}
	
	private func updateView() {
		var toolbarItems = [UIBarButtonItem]()
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil))
		if (_showItemsWithNoDate) {
			toolbarItems.append(_buttonScheduled)
		} else {
			toolbarItems.append(_buttonAll)
		}
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil))
		if (_showCompletedItems) {
			toolbarItems.append(_buttonHideCompleted)
		} else {
			toolbarItems.append(_buttonShowCompleted)
		}
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil))
		toolbarItems.append(_buttonAdd)
		_toolbar.items = toolbarItems
		
		if (_eventStoreAccessGranted) {
			_accessDeniedView.isHidden = true
		} else {
			_accessDeniedView.isHidden = false
		}
	}
	
	private func checkAuthorizationStatus() {
		let authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: EKEntityType.reminder)
		let eventStoreAccessGranted = (authorizationStatus == EKAuthorizationStatus.authorized)
		if (_eventStoreAccessGranted != eventStoreAccessGranted) {
			_eventStoreAccessGranted = eventStoreAccessGranted
			if (_eventStoreAccessGranted) {
				self.startLoadReminders()
			}
			self.updateView()
		}
	}
	
	private func reminderForIndexPath(_ indexPath: IndexPath) -> EKReminder {
		let date = _sectionsDates[indexPath.section]
		return _mapSectionsDates[date]![indexPath.row]
	}
	
	// MARK: - UITableViewDataSource
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return _sectionsDates.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let date = _sectionsDates[section]
		return _mapSectionsDates[date]!.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let reminder = self.reminderForIndexPath(indexPath)
		let reuseId = "Reminder Cell"
		var cell = _tableView.dequeueReusableCell(withIdentifier: reuseId) as? VLReminderTableViewCell
		if (cell == nil) {
			cell = VLReminderTableViewCell(eventStore: _eventStore, reuseIdentifier: reuseId)
			cell?.delegate = self
		}
		cell!.reminder = reminder
		return cell!
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	// MARK: - UITableViewDelegate
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if (_sectionsDates.count <= 1) {
			return 0.0
		}
		let date = _sectionsDates[section]
		if (date == _dateNone) {
			return 0.0
		}
		return TableSectionView.optimalHeight()
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if (_sectionsDates.count <= 1) {
			return nil
		}
		let date = _sectionsDates[section]
		let view = TableSectionView()
		view.date = date
		return view
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let reminder = self.reminderForIndexPath(indexPath)
		let vc = VLReminderEditViewController(reminder: reminder, eventStore: _eventStore, locationManager: _locationManager, showDeleteOption: true)
		vc.editViewDelegate = self
		self.present(vc, animated: true, completion: nil)
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		let reminder = self.reminderForIndexPath(indexPath)
		let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove this reminder?", preferredStyle: UIAlertControllerStyle.alert)
		alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
			do {
				try self._eventStore.remove(reminder, commit: true)
			} catch let error {
				self.showError(error)
			}
			//self.updateViewAsync()
		}))
		alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		self.present(alertController, animated: true, completion: nil)
	}
	
	// MARK: - UIToolbarDelegate
	
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		return UIBarPosition.bottom
	}
	
	// MARK: - VLReminderEditViewDelegate
	
	func reminderEditViewController(_ controller: VLReminderEditViewController, didCompleteWithAction action: VLReminderEditViewAction) {
		let reminder = controller.reminder
		if (action == VLReminderEditViewAction.doneWithChanges) {
			do {
				try _eventStore.save(reminder, commit: true)
				controller.dismiss(animated: true, completion: nil)
			} catch let error {
				self.showError(error)
			}
		} else if (action == VLReminderEditViewAction.doneWithNoChanges) {
			controller.dismiss(animated: true, completion: nil)
		} else if (action == VLReminderEditViewAction.delete) {
			let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove this reminder?", preferredStyle: UIAlertControllerStyle.alert)
			alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
				do {
					try self._eventStore.remove(reminder, commit: true)
					controller.dismiss(animated: true, completion: nil)
				} catch let error {
					self.showError(error)
				}
			}))
			alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
			self.present(alertController, animated: true, completion: nil)
		} else {
			controller.dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: - VLReminderTableViewCellDelegate
	
	func reminderTableViewCell(_ cell: VLReminderTableViewCell, didReminderCompletionTap param: AnyObject?) {
		if let reminder = cell.reminder {
			reminder.isCompleted = !reminder.isCompleted
			do {
				try _eventStore.save(reminder, commit: true)
			} catch let error as NSError {
				self.showError(error)
			}
			self.updateView()
		}
	}
	
	// MARK: - Events
	
	func onEventStoreDidChange(obj: AnyObject?) {
		self.checkAuthorizationStatus()
		self.startLoadReminders()
	}
	
	func onApplicationDidBecomeActive(obj: AnyObject?) {
		self.checkAuthorizationStatus()
		self.startLoadReminders()
	}
	
	func onButtonAddDidTap(sender: UIBarButtonItem) {
		let reminder = EKReminder(eventStore: _eventStore)
		reminder.calendar = _eventStore.defaultCalendarForNewReminders()
		let vc = VLReminderEditViewController(reminder: reminder, eventStore: _eventStore, locationManager: _locationManager, showDeleteOption: false)
		vc.editViewDelegate = self
		self.present(vc, animated: true, completion: nil)
	}
	
	func onButtonAllDidTap(sender: UIBarButtonItem) {
		_showItemsWithNoDate = true
		self.startLoadReminders()
		self.updateView()
	}
	
	func onButtonScheduledDidTap(sender: UIBarButtonItem) {
		_showItemsWithNoDate = false
		self.startLoadReminders()
		self.updateView()
	}
	
	func onButtonShowCompletedDidTap(sender: UIBarButtonItem) {
		_showCompletedItems = true
		self.startLoadReminders()
		self.updateView()
	}
	
	func onButtonHideCompletedDidTap(sender: UIBarButtonItem) {
		_showCompletedItems = false
		self.startLoadReminders()
		self.updateView()
	}
	
	// MARK: - Private class AccessDeniedView
	
	private class AccessDeniedView: UIView {
		
		private let _labelInfo1 = UILabel()
		private let _labelInfo2 = UILabel()
		
		init() {
			super.init(frame: CGRect.zero)
			self.backgroundColor = UIColor.white
			for label in [_labelInfo1, _labelInfo2] {
				label.backgroundColor = UIColor.clear
				label.baselineAdjustment = UIBaselineAdjustment.alignCenters
				label.textAlignment = NSTextAlignment.center
				label.numberOfLines = 0
				label.textColor = UIColor(white: 0.0, alpha: 1.0)
				self.addSubview(label)
			}
			_labelInfo1.font = UIFont.systemFont(ofSize: 18)
			_labelInfo2.font = UIFont.systemFont(ofSize: 15)
			_labelInfo1.text = "This app does not have access to your reminders."
			_labelInfo2.text = "You can enable access in Privacy Settings."
		}
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		override func layoutSubviews() {
			super.layoutSubviews()
			let rcBnds = self.bounds
			let insets = UIEdgeInsetsMake(16, 16, 16, 16)
			let rcCtrls = UIEdgeInsetsInsetRect(rcBnds, insets)
			var rcLb1 = rcCtrls
			rcLb1.size.height = rcCtrls.size.height / 2.0
			_labelInfo1.frame = rcLb1
			var rcLb2 = rcCtrls
			rcLb2.origin.y = rcLb1.maxY
			rcLb2.size.height = rcCtrls.maxY - rcLb2.origin.y
			_labelInfo2.frame = rcLb2
		}
		
	}
	
	// MARK: - Private class TableSectionView
	
	private class TableSectionView : UIView {
		
		// MARK: - Declarations
		
		private var _date: Date? = nil
		private let _labelTitle = UILabel()
		
		// MARK: - Initialize
		
		init() {
			super.init(frame: CGRect.zero)
			self.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 0.75)
			_labelTitle.backgroundColor = UIColor.clear
			_labelTitle.baselineAdjustment = UIBaselineAdjustment.alignCenters
			_labelTitle.font = UIFont.systemFont(ofSize: TableSectionView.fontTitleSize())
			_labelTitle.textColor = UIColor(red: 241/255.0, green: 67/255.0, blue: 59/255.0, alpha: 1.0)
			_labelTitle.text = ""
			self.addSubview(_labelTitle)
		}
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		// MARK: - Private functions
		
		private class func fontTitleSize() -> CGFloat {
			return 16
		}
		
		private class func titleTextHeight() -> CGFloat {
			return ceil(self.fontTitleSize() * 1.2)
		}
		
		// MARK: - Layout
		
		private class func insets() -> UIEdgeInsets {
			return UIEdgeInsetsMake(2, 8, 2, 8)
		}
		
		override func layoutSubviews() {
			super.layoutSubviews()
			let rcBnds = self.bounds
			let insets = TableSectionView.insets()
			let rcCtrls = UIEdgeInsetsInsetRect(rcBnds, insets)
			let rcLbTitle = rcCtrls
			_labelTitle.frame = rcLbTitle
		}
		
		// MARK: - Public interface
		
		class func optimalHeight() -> CGFloat {
			let insets = self.insets()
			let titleTextHeight = self.titleTextHeight()
			let result = insets.top + titleTextHeight + insets.bottom
			return result
		}
		
		var date: Date? {
			get {
				return _date
			}
			set {
				if (_date != newValue) {
					_date = newValue
					var sDate = ""
					if let date = _date {
						if (VLEventKitUIUtilities.isToday(date: date)) {
							sDate = NSLocalizedString("Today", comment: "")
						} else if (VLEventKitUIUtilities.isTomorrow(date: date)) {
							sDate = NSLocalizedString("Tomorrow", comment: "")
						} else {
							let dateFormatter = DateFormatter()
							dateFormatter.dateStyle = DateFormatter.Style.long
							dateFormatter.timeStyle = DateFormatter.Style.none
							sDate = dateFormatter.string(from: date)
						}
					}
					_labelTitle.text = sDate
				}
			}
		}
		
		// MARK: -
		
	}
	
	// MARK: -

}


