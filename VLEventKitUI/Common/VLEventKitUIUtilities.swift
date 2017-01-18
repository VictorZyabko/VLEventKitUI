//
// VLEventKitUIUtilities.swift
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

class VLEventKitUIUtilities: NSObject {
	
	// MARK: - Public interface
	
	class func stringFromRecurrenceRule(_ recurrenceRule: EKRecurrenceRule?) -> String {
		var result = ""
		if let recurrenceRule = recurrenceRule {
			let frequency = recurrenceRule.frequency
			let interval = recurrenceRule.interval
			if (frequency == EKRecurrenceFrequency.daily) {
				if (interval == 1) {
					result = "Daily"
				} else {
					result = String(format: "Every %d days", interval)
				}
			} else if (frequency == EKRecurrenceFrequency.weekly) {
				if (interval == 1) {
					result = "Weekly"
				} else {
					result = String(format: "Every %d weeks", interval)
				}
			} else if (frequency == EKRecurrenceFrequency.monthly) {
				if (interval == 1) {
					result = "Monthly"
				} else {
					result = String(format: "Every %d months", interval)
				}
			} else if (frequency == EKRecurrenceFrequency.yearly) {
				if (interval == 1) {
					result = "Yearly"
				} else {
					result = String(format: "Every %d years", interval)
				}
			}
			if (recurrenceRule.daysOfTheWeek != nil && recurrenceRule.daysOfTheWeek!.count > 0
				|| recurrenceRule.daysOfTheMonth != nil && recurrenceRule.daysOfTheMonth!.count > 0
				|| recurrenceRule.daysOfTheYear != nil && recurrenceRule.daysOfTheYear!.count > 0
				|| recurrenceRule.weeksOfTheYear != nil && recurrenceRule.weeksOfTheYear!.count > 0
				|| recurrenceRule.monthsOfTheYear != nil && recurrenceRule.monthsOfTheYear!.count > 0) {
				result = result + " on..."
			}
		} else {
			result = "Never"
		}
		return result
	}
	
	class func stringFromRecurrenceEnd(_ recurrenceEnd: EKRecurrenceEnd?) -> String {
		var result = ""
		if let recurrenceEnd = recurrenceEnd {
			if let date = recurrenceEnd.endDate {
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = DateFormatter.Style.medium
				dateFormatter.timeStyle = DateFormatter.Style.none
				result = dateFormatter.string(from: date)
			}
		} else {
			result = "Never"
		}
		return result
	}
	
	static let daysOfWeek: [String] = {
		return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	} ()
	
	class func weekdayFromNumber(_ weekNumber: Int) -> EKWeekday {
		var result = EKWeekday.sunday
		switch (weekNumber) {
			case 1:
				result = EKWeekday.sunday
			case 2:
				result = EKWeekday.monday
			case 3:
				result = EKWeekday.tuesday
			case 4:
				result = EKWeekday.wednesday
			case 5:
				result = EKWeekday.thursday
			case 6:
				result = EKWeekday.friday
			case 7:
				result = EKWeekday.saturday
			default:
				result = EKWeekday.sunday
		}
		return result
	}
	
	class func numberFromWeekday(_ weekday: EKWeekday) -> Int {
		var result = -1
		switch (weekday) {
			case EKWeekday.sunday:
				result = 1
			case EKWeekday.monday:
				result = 2
			case EKWeekday.tuesday:
				result = 3
			case EKWeekday.wednesday:
				result = 4
			case EKWeekday.thursday:
				result = 5
			case EKWeekday.friday:
				result = 6
			case EKWeekday.saturday:
				result = 7
		}
		return result
	}
	
	static let daysOfMonth: [String] = {
		var result = [String]()
		for i in 1...31 {
			result.append(String(format: "%d", i))
		}
		return result
	} ()
	
	static let monthsOfYearShort: [String] = {
		return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	} ()
	
	static let recurrenceRuleSetPositions: [String] = {
		return ["first", "second", "third", "fourth", "fifth", "last"]
	} ()
	
	class func alarmWithLocationFromReminder(_ reminder: EKReminder) -> EKAlarm? {
		var result: EKAlarm? = nil
		if let alarms = reminder.alarms {
			for alarm in alarms {
				if (alarm.structuredLocation != nil) {
					result = alarm
					break
				}
			}
		}
		return result
	}
	
	class func locationFromReminder(_ reminder: EKReminder) -> EKStructuredLocation? {
		var location: EKStructuredLocation? = nil
		if let alarm = self.alarmWithLocationFromReminder(reminder) {
			if (alarm.structuredLocation != nil) {
				location = alarm.structuredLocation
			}
		}
		return location
	}
	
	class func alarmWithNoLocationFromReminder(_ reminder: EKReminder) -> EKAlarm? {
		var result: EKAlarm? = nil
		if let alarms = reminder.alarms {
			for alarm in alarms {
				if (alarm.structuredLocation == nil && alarm.absoluteDate != nil) {
					result = alarm
					break
				}
			}
		}
		return result
	}
	
	class func stringFromLocationRadius(_ radiusInMeters: Int) -> String {
		var result = ""
		if (radiusInMeters >= 100000) {
			let kms = radiusInMeters / 1000
			result = String(format: "%d kilometers", kms)
		} else if (radiusInMeters >= 10000) {
			let kms = radiusInMeters / 1000
			let hundredsMeters = (radiusInMeters - kms * 1000) / 100
			if (hundredsMeters > 0) {
				result = String(format: "%d,%d", kms, hundredsMeters)
				while (result.characters.count > 0 && result[result.index(result.startIndex, offsetBy: result.characters.count - 1)] == "0") {
					result = result.substring(to: result.index(result.startIndex, offsetBy: result.characters.count - 1))
				}
				result = result + " kilometers"
			} else {
				result = String(format: "%d kilometers", kms)
			}
		} else if (radiusInMeters >= 1000) {
			let kms = radiusInMeters / 1000
			let tensMeters = (radiusInMeters - kms * 1000) / 10
			if (tensMeters > 0) {
				result = String(format: "%d,%02d", kms, tensMeters)
				while (result.characters.count > 0 && result[result.index(result.startIndex, offsetBy: result.characters.count - 1)] == "0") {
					result = result.substring(to: result.index(result.startIndex, offsetBy: result.characters.count - 1))
				}
				result = result + " kilometers"
			} else {
				if (kms == 1) {
					result = String(format: "%d kilometer", kms)
				} else {
					result = String(format: "%d kilometers", kms)
				}
			}
		} else {
			if (radiusInMeters == 1) {
				result = String(format: "%d meter", radiusInMeters)
			} else {
				result = String(format: "%d meters", radiusInMeters)
			}
		}
		return result
	}
	
	class func isLocationsEqual(location1: EKStructuredLocation?, location2: EKStructuredLocation?) -> Bool {
		if (location1 == nil && location2 == nil) {
			return true
		}
		if ((location1 != nil) != (location2 != nil)) {
			return false
		}
		if (location1!.title == location2!.title
			&& location1!.geoLocation == location2!.geoLocation
			&& location1!.radius == location2!.radius) {
			return true
		}
		return false
	}
	
	class func dateFromReminder(_ reminder: EKReminder) -> Date? {
		let date: Date? = reminder.dueDateComponents?.date
		return date
	}
	
	class func isToday(date: Date) -> Bool {
		let dateNow = Date()
		let secondsPerDay: Int64 = 86400
		let timeZone = TimeZone.current
		let secondsFromGMT = TimeInterval(timeZone.secondsFromGMT())
		let secondsNow = Int64(dateNow.timeIntervalSince1970 + secondsFromGMT) / secondsPerDay * secondsPerDay
		let secondsDate = Int64(date.timeIntervalSince1970 + secondsFromGMT) / secondsPerDay * secondsPerDay
		let dSeconds = secondsDate - secondsNow
		return (dSeconds == 0)
	}
	
	class func isTomorrow(date: Date) -> Bool {
		let dateNow = Date()
		let secondsPerDay: Int64 = 86400
		let timeZone = TimeZone.current
		let secondsFromGMT = TimeInterval(timeZone.secondsFromGMT())
		let secondsNow = Int64(dateNow.timeIntervalSince1970 + secondsFromGMT) / secondsPerDay * secondsPerDay
		let secondsDate = Int64(date.timeIntervalSince1970 + secondsFromGMT) / secondsPerDay * secondsPerDay
		let dSeconds = secondsDate - secondsNow
		return (dSeconds == secondsPerDay)
	}
	
	// MARK: -

}
