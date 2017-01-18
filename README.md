# VLEventKitUI

An addition to the standard iOS EventKitUI, allows view/create/edit/delete reminders.


## Requirements

- iOS 8+ / tvOS 9+
- Xcode 8+


## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/vleventkitui). (Tag `vleventkitui`)
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/vleventkitui).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.


## Installation

Just copy VLEventKitUI directory to your project


## Usage

...
	private let _eventStore = EKEventStore()
...
	private var _locationManager: CLLocationManager? = CLLocationManager() // Location manager is oprional. Used to create 'Arrive/Leave' reminders.
...
	let reminder = EKReminder(eventStore: _eventStore)
	reminder.calendar = _eventStore.defaultCalendarForNewReminders()
	let controller = VLReminderEditViewController(reminder: reminder, eventStore: _eventStore, locationManager: _locationManager /*optional*/, showDeleteOption: false)
	controller.editViewDelegate = self
	self.present(controller, animated: true, completion: nil)
...
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
...


## Demo

See ExampleUI. Although VLRemindersViewController is not part of VLEventKitUI library, you can use it in your project.


## License

`VLEventKitUI` is available under the MIT license. See the LICENSE file for more info.
