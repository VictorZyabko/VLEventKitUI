//
// VLReminderLocationViewController.swift
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
import MapKit
import CoreLocation
import Contacts


protocol VLReminderLocationViewDelegate : NSObjectProtocol {
	
	func reminderLocationViewController(_ controller: VLReminderLocationViewController, didDataChange param: AnyObject?)
	
}


class VLReminderLocationViewController: UIViewController {
	
	// MARK: - Declarations
	
	private let _originalAlarmWithLocation: EKAlarm?
	private let _locationManager: CLLocationManager?

	// MARK: - Initialize
	
	required init(originalAlarmWithLocation: EKAlarm?, locationManager: CLLocationManager?) {
		_originalAlarmWithLocation = originalAlarmWithLocation
		_locationManager = locationManager
		super.init(nibName: nil, bundle: nil)
		self.edgesForExtendedLayout = []
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.title = "Location"
	}
	
	// MARK: - Private
	
	private func locationView() -> VLReminderLocationView {
		return self.view as! VLReminderLocationView
	}
	
	// MARK: - Overridable
	
	override func loadView() {
		let view = VLReminderLocationView(originalAlarmWithLocation: _originalAlarmWithLocation, locationManager: _locationManager)
		view.reminderLocationViewController = self
		self.view = view
	}
	
	// MARK: - class VLReminderLocationView
	
	class VLReminderLocationView: UIView, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
		
		// MARK: - Declarations
		
		private let _originalAlarmWithLocation: EKAlarm?
		private let _locationManager: CLLocationManager?
		private var _selectedAlarmWithLocation: EKAlarm?
		private let _backView = UIView()
		private let _searchBar = UISearchBar()
		private let _searchingIndicator = UIActivityIndicatorView()
		private var _cells = [VLReminderTextLineTableCell]()
		private var _cellsSearched = [VLReminderTextLineTableCell]()
		private var _locationsSearched = [EKStructuredLocation]()
		private let _cellCurLocation = VLReminderTextLineTableCell()
		private var _isCurrentLocationSelected = false
		private var _isOriginaltLocationSelected = false
		private let _cellOriginalLocation = VLReminderTextLineTableCell()
		private let _tableView = UITableView(frame: CGRect(), style: UITableViewStyle.plain)
		
		private let _switchArriveLeave = UISegmentedControl()
		private let _labelRadius = UILabel()
		private let _switchRadius = UISegmentedControl()
		private let _labelRadiusValue = UILabel()
		private let _sliderRadius = UISlider()
		private let _minRadius: Double = 1.0
		private let _maxRadius: Double = 1000000.0
		
		private var _searchingTicket = 0
		private var _searchingCounter = 0
		
		private var _searchingCurLocationCounter = 0
		private var _curLocaion: EKStructuredLocation? = nil
		private var _curLocationError: NSError? = nil
		
		// MARK: - Initialize
		
		required init(originalAlarmWithLocation: EKAlarm?, locationManager: CLLocationManager?) {
			if (originalAlarmWithLocation != nil) {
				_originalAlarmWithLocation = EKAlarm()
				_originalAlarmWithLocation!.relativeOffset = originalAlarmWithLocation!.relativeOffset
				_originalAlarmWithLocation!.absoluteDate = originalAlarmWithLocation!.absoluteDate
				_originalAlarmWithLocation!.structuredLocation = originalAlarmWithLocation!.structuredLocation
				_originalAlarmWithLocation!.proximity = originalAlarmWithLocation!.proximity
				_selectedAlarmWithLocation = _originalAlarmWithLocation
				_isOriginaltLocationSelected = true
			} else {
				_originalAlarmWithLocation = originalAlarmWithLocation
			}
			_locationManager = locationManager
			super.init(frame: CGRect())
			self.backgroundColor = UIColor.white
			_backView.backgroundColor = self.backgroundColor
			self.addSubview(_backView)
			
			_searchBar.placeholder = "Search or Enter Address"
			_searchBar.delegate = self
			_searchBar.text = ""
			self.addSubview(_searchBar)
			
			_searchingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
			_searchingIndicator.isHidden = true
			self.addSubview(_searchingIndicator)
			
			_cellCurLocation.labelTitle.text = "Current Location"
			_cellCurLocation.isTextOnBottom = true
			
			_tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
			_tableView.dataSource = self
			_tableView.delegate = self
			self.addSubview(_tableView)
			
			_switchArriveLeave.insertSegment(withTitle: "When I Arrive", at: _switchArriveLeave.numberOfSegments, animated: false)
			_switchArriveLeave.insertSegment(withTitle: "When I Leave", at: _switchArriveLeave.numberOfSegments, animated: false)
			_switchArriveLeave.addTarget(self, action: #selector(onSwitchArriveLeaveDidValueChange), for: UIControlEvents.valueChanged)
			self.addSubview(_switchArriveLeave)
			
			_labelRadius.numberOfLines = 0;
			_labelRadius.text = "A minimum distance from the core location that would trigger the reminder:"
			self.addSubview(_labelRadius)
			
			_switchRadius.insertSegment(withTitle: "Default", at: _switchArriveLeave.numberOfSegments, animated: false)
			_switchRadius.insertSegment(withTitle: "Custom", at: _switchArriveLeave.numberOfSegments, animated: false)
			_switchRadius.addTarget(self, action: #selector(onSwitchRadiusDidValueChange), for: UIControlEvents.valueChanged)
			self.addSubview(_switchRadius)
			
			_labelRadiusValue.textAlignment = NSTextAlignment.right
			_labelRadiusValue.text = "... meters"
			self.addSubview(_labelRadiusValue)
			
			_sliderRadius.value = self.sliderPositionFromRadius(100.0)
			_sliderRadius.addTarget(self, action: #selector(onSliderRadiusDidValueChange), for: UIControlEvents.valueChanged)
			self.addSubview(_sliderRadius)
			
			self.startSearchCurrentLocation()
			
			self.updateViewFromData()
		}
		
		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		// MARK: - Private
		
		private func updateViewFromData() {
			var cells = [VLReminderTextLineTableCell]()
			
			if (_locationManager != nil) {
				if (_searchingCurLocationCounter > 0) {
					_cellCurLocation.labelText.text = "Searching..."
				} else {
					if let curLocation = _curLocaion {
						_cellCurLocation.labelText.text = curLocation.title
					} else {
						if let error = _curLocationError {
							_cellCurLocation.labelText.text = error.localizedDescription
						} else {
							_cellCurLocation.labelText.text = ""
						}
					}
				}
				cells.append(_cellCurLocation)
			}
			if (_searchingCurLocationCounter > 0) {
				_cellCurLocation.startActivityIndicator()
			} else {
				_cellCurLocation.stopActivityIndicator()
			}
			
			if (_originalAlarmWithLocation != nil) {
				if let location = _originalAlarmWithLocation?.structuredLocation {
					_cellOriginalLocation.labelTitle.text = location.title
				} else {
					_cellOriginalLocation.labelTitle.text = ""
				}
				cells.append(_cellOriginalLocation)
			}
			cells.append(contentsOf: _cellsSearched)
			
			if (_cells != cells) {
				_cells = cells
				_tableView.reloadData()
			}
			
			if (_searchingCounter > 0) {
				if (_searchingIndicator.isHidden) {
					_searchingIndicator.isHidden = false
					_searchingIndicator.startAnimating()
				}
			} else {
				if (!_searchingIndicator.isHidden) {
					_searchingIndicator.stopAnimating()
					_searchingIndicator.isHidden = true
				}
			}
			
			let locationSelected = _selectedAlarmWithLocation?.structuredLocation
			
			// Update selected cell
			for (index, cell) in _cells.enumerated() {
				let indexPath = IndexPath(row: index, section: 0)
				if (cell == _cellCurLocation) {
					if (_isCurrentLocationSelected) {
						_tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
					} else {
						_tableView.deselectRow(at: indexPath, animated: false)
					}
				} else if (cell == _cellOriginalLocation) {
					if (_isOriginaltLocationSelected) {
						_tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
					} else {
						_tableView.deselectRow(at: indexPath, animated: false)
					}
				} else {
					let location = _locationsSearched[_cellsSearched.index(of: cell)!]
					if (!_isCurrentLocationSelected && !_isOriginaltLocationSelected && VLEventKitUIUtilities.isLocationsEqual(location1: locationSelected, location2: location)) {
						_tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
					} else {
						_tableView.deselectRow(at: indexPath, animated: false)
					}
				}
			}
			
			if let alarm = _selectedAlarmWithLocation {
				_switchArriveLeave.selectedSegmentIndex = alarm.proximity == EKAlarmProximity.enter ? 0 : 1
			} else {
				_switchArriveLeave.selectedSegmentIndex = 0
			}
			
			if (locationSelected != nil) {
				_switchArriveLeave.isHidden = false
				_labelRadius.isHidden = false
				_switchRadius.isHidden = false
				let radius: Double = locationSelected!.radius
				if (radius == 0) {
					_switchRadius.selectedSegmentIndex = 0
					_sliderRadius.isHidden = true
					_labelRadiusValue.isHidden = true
				} else {
					_switchRadius.selectedSegmentIndex = 1
					_labelRadiusValue.text = VLEventKitUIUtilities.stringFromLocationRadius(Int(round(radius)))
					_sliderRadius.value = self.sliderPositionFromRadius(radius)
					_sliderRadius.isHidden = false
					_labelRadiusValue.isHidden = false
				}
			} else {
				_switchArriveLeave.isHidden = true
				_labelRadius.isHidden = true
				_switchRadius.isHidden = true
				_switchRadius.selectedSegmentIndex = 0
				_sliderRadius.isHidden = true
				_labelRadiusValue.isHidden = true
			}
			
			self.setNeedsLayout()
		}
		
		private func updateDataFromView() {
			if (_selectedAlarmWithLocation != nil) {
				let location = _selectedAlarmWithLocation?.structuredLocation
				_selectedAlarmWithLocation = EKAlarm()
				_selectedAlarmWithLocation?.structuredLocation = location
			}
			if let alarm = _selectedAlarmWithLocation {
				alarm.proximity = _switchArriveLeave.selectedSegmentIndex == 0 ? EKAlarmProximity.enter : EKAlarmProximity.leave
				if let location = _selectedAlarmWithLocation?.structuredLocation {
					if (_switchRadius.selectedSegmentIndex == 0) {
						location.radius = 0
					} else if (_switchRadius.selectedSegmentIndex == 1) {
						let position = _sliderRadius.value
						let radius = self.radiusFromSliderPosition(position)
						location.radius = radius
					}
				}
			}
			self.processDataChanged()
		}
		
		private func processDataChanged() {
			self.delegate?.reminderLocationViewController(self.reminderLocationViewController!, didDataChange: nil)
		}
		
		private func sliderPositionFromRadius(_ radius: Double) -> Float {
			var radius = Double(radius)
			radius = min(max(radius, _minRadius), _maxRadius)
			var position = pow(radius - _minRadius, 1.0 / 5.0) / pow(_maxRadius - _minRadius, 1.0 / 5.0)
			position = min(max(position, 0.0), 1.0)
			return Float(position)
		}
		
		private func radiusFromSliderPosition(_ position: Float) -> Double {
			var position = Double(position)
			position = min(max(position, 0.0), 1.0)
			let radius = _minRadius + pow(position * pow((_maxRadius - _minRadius), 1.0 / 5.0), 5.0)
			return radius
		}
		
		private func locationFromPlacemark(_ placemark: CLPlacemark) -> EKStructuredLocation {
			let address = CNMutablePostalAddress()
			
			address.street = (placemark.subThoroughfare ?? "") + " " + (placemark.thoroughfare ?? "")
			address.city = placemark.locality ?? ""
			address.state = placemark.administrativeArea ?? ""
			address.postalCode = placemark.postalCode ?? ""
			address.country = placemark.country ?? ""
			
			let addressFormatter = CNPostalAddressFormatter()
			let addressString = addressFormatter.string(from: address)
			var localizedAddress = addressString.replacingOccurrences(of: "\n", with: ", ")
			for _ in 1..<5 {
				localizedAddress = localizedAddress.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
				localizedAddress = localizedAddress.replacingOccurrences(of: ", , ", with: ", ")
				if (localizedAddress.characters.count >= 2
					&& localizedAddress[localizedAddress.index(localizedAddress.startIndex, offsetBy: 0)] == ","
					&& localizedAddress[localizedAddress.index(localizedAddress.startIndex, offsetBy: 1)] == " ") {
					let start = localizedAddress.startIndex // Start at the string's start index
					let end = localizedAddress.index(localizedAddress.startIndex, offsetBy: 2) // Take start index and advance 2 characters forward
					let range: Range<String.Index> = start ..< end
					localizedAddress = localizedAddress.replacingCharacters(in: range, with: "")
				}
			}
			
			let location = EKStructuredLocation()
			location.title = localizedAddress
			location.geoLocation = placemark.location
			return location
		}
		
		private func startSearchCurrentLocation() {
			if let locationManager = _locationManager {
				if let location = locationManager.location {
					let geocoder = CLGeocoder()
					_searchingCurLocationCounter += 1
					geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
						self._searchingCurLocationCounter -= 1
						if let placemark = placemarks?.first {
							let location = self.locationFromPlacemark(placemark)
							self._curLocaion = location
						}
						if (self._curLocaion != nil) {
							self._curLocationError = nil
						} else {
							if (error != nil) {
								self._curLocationError = error! as NSError
							} else {
								self._curLocationError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get current location"])
							}
						}
						self.updateViewFromData()
					})
				} else {
					_curLocationError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get current location"])
					self.updateViewFromData()
				}
			}
		}
		
		private func startSearchWithText(_ text: String) {
			if (text.characters.count <= 0) {
				return
			}
			_searchingTicket += 1
			let searchingTicket = _searchingTicket
			_searchingCounter += 1
			self.updateViewFromData()
			let geocoder = CLGeocoder()
			geocoder.geocodeAddressString(text, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
				self._searchingCounter -= 1
				self.updateViewFromData()
				if (searchingTicket != self._searchingTicket) {
					return
				}
				var locations = [EKStructuredLocation]()
				for placemark in placemarks ?? [CLPlacemark]() {
					let location = self.locationFromPlacemark(placemark)
					locations.append(location)
				}
				self._cellsSearched.removeAll()
				self._locationsSearched.removeAll()
				self._locationsSearched.append(contentsOf: locations)
				self._locationsSearched.sort(by: { (obj1: EKStructuredLocation, obj2: EKStructuredLocation) -> Bool in
					return obj1.title.caseInsensitiveCompare(obj2.title) == ComparisonResult.orderedAscending
				})
				for loction in self._locationsSearched {
					let cell = VLReminderTextLineTableCell()
					cell.labelTitle.text = loction.title
					self._cellsSearched.append(cell)
				}
				self.updateViewFromData()
			})
		}
		
		// MARK: - Layout
		
		override func layoutSubviews() {
			super.layoutSubviews()
			let rcBnds = self.bounds
			var rcBack = rcBnds
			rcBack.origin.y -= 100.0
			rcBack.size.height += 200.0
			_backView.frame = rcBack
			
			var rcBar = rcBnds
			rcBar.size.height = _searchBar.sizeThatFits(rcBar.size).height
			
			var rcInd = rcBar
			rcInd.size.width = rcInd.size.height
			_searchingIndicator.frame = rcInd
			
			let bottomInset: CGFloat = 12.0
			let distX: CGFloat = 4.0
			let distY: CGFloat = 4.0
			
			var rcSlider = rcBnds
			rcSlider.size.height = !_sliderRadius.isHidden ? _sliderRadius.sizeThatFits(rcSlider.size).height : 0.0
			rcSlider.origin.x += distX
			rcSlider.size.width -= distX * 2
			rcSlider.origin.x += rcSlider.size.height / 2.0
			rcSlider.size.width -= rcSlider.size.height
			rcSlider.origin.y = rcBnds.maxY - bottomInset - rcSlider.size.height
			
			var rcRadiusValue = rcBnds
			rcRadiusValue.size.height = !_labelRadiusValue.isHidden ? ceil("A".size(attributes: [NSFontAttributeName: _labelRadiusValue.font]).height) : 0.0
			rcRadiusValue.origin.x += distX
			rcRadiusValue.size.width -= distX * 2
			rcRadiusValue.origin.y = rcSlider.origin.y - distY - rcRadiusValue.size.height
			
			var rcSwitchRadius = rcBnds
			rcSwitchRadius.size.height = !_switchRadius.isHidden ? _switchRadius.sizeThatFits(rcSwitchRadius.size).height : 0.0
			rcSwitchRadius.origin.x += distX
			rcSwitchRadius.size.width -= distX * 2
			rcSwitchRadius.origin.x += rcSwitchRadius.size.height / 2.0
			rcSwitchRadius.size.width -= rcSwitchRadius.size.height
			rcSwitchRadius.origin.y = rcRadiusValue.origin.y - distY - rcSwitchRadius.size.height
			
			var rcLabelRadius = rcBnds
			rcLabelRadius.size.height = !_labelRadius.isHidden ? _labelRadius.sizeThatFits(rcLabelRadius.size).height : 0.0
			rcLabelRadius.origin.x += distX
			rcLabelRadius.size.width -= distX * 2
			rcLabelRadius.origin.y = rcSwitchRadius.origin.y - distY - rcLabelRadius.size.height
			
			var rcSwitch = rcBnds
			rcSwitch.size.height = !_switchArriveLeave.isHidden ? _switchArriveLeave.sizeThatFits(rcSwitch.size).height : 0.0
			rcSwitch.origin.x += distX
			rcSwitch.size.width -= distX * 2
			rcSwitch.origin.y = rcLabelRadius.origin.y - distY - rcSwitch.size.height
			
			var rcTable = rcBnds
			rcTable.origin.y = rcBar.maxY
			rcTable.size.height = rcSwitch.origin.y - distY - rcTable.origin.y
			
			_searchBar.frame = rcBar
			_tableView.frame = rcTable
			_switchArriveLeave.frame = rcSwitch
			_labelRadius.frame = rcLabelRadius
			_switchRadius.frame = rcSwitchRadius
			_sliderRadius.frame = rcSlider
			_labelRadiusValue.frame = rcRadiusValue
		}
		
		// MARK: - UISearchBarDelegate
		
		func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
			_searchBar.resignFirstResponder()
			_selectedAlarmWithLocation = nil
			self.updateViewFromData()
			self.startSearchWithText(_searchBar.text ?? "")
		}
		
		func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
			_searchBar.resignFirstResponder()
			_searchBar.text = ""
		}
		
		// MARK: - UITableViewDataSource
		
		func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
			return _cells.count
		}
		
		func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
			return _cells[indexPath.row]
		}
		
		// MARK: - UITableViewDelegate
		
		func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
			let cell = _cells[indexPath.row]
			return cell.optimalHeight()
		}
	
		func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
			let cell = _cells[indexPath.row]
			if (cell == _cellCurLocation) {
				if (_curLocaion == nil) {
					return nil
				}
			}
			return indexPath
		}
		
		func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
			let cell = _cells[indexPath.row]
			if (cell == _cellCurLocation) {
				if let location = _curLocaion {
					_selectedAlarmWithLocation = EKAlarm()
					_selectedAlarmWithLocation!.structuredLocation = location
					_isCurrentLocationSelected = true
					_isOriginaltLocationSelected = false
				}
			} else if (cell == _cellOriginalLocation) {
				_selectedAlarmWithLocation = _originalAlarmWithLocation
				_isCurrentLocationSelected = false
				_isOriginaltLocationSelected = true
			} else {
				let location = _locationsSearched[_cellsSearched.index(of: cell)!]
				_selectedAlarmWithLocation = EKAlarm()
				_selectedAlarmWithLocation!.structuredLocation = location
				_isCurrentLocationSelected = false
				_isOriginaltLocationSelected = false
			}
			self.updateDataFromView()
			self.updateViewFromData()
		}
		
		// MARK: - Event handlers
		
		func onSwitchArriveLeaveDidValueChange() {
			self.updateDataFromView()
			self.updateViewFromData()
		}
		
		func onSwitchRadiusDidValueChange() {
			if (_switchRadius.selectedSegmentIndex == 1) {
				let position = _sliderRadius.value
				let radius = Int(ceil(self.radiusFromSliderPosition(position)))
				if (radius == 0) {
					_sliderRadius.value = self.sliderPositionFromRadius(100.0)
				}
			}
			self.updateDataFromView()
			self.updateViewFromData()
		}
		
		func onSliderRadiusDidValueChange() {
			self.updateDataFromView()
			self.updateViewFromData()
		}
		
		// MARK: - Public interface
		
		weak var reminderLocationViewController: VLReminderLocationViewController?
		
		weak var delegate: VLReminderLocationViewDelegate?
		
		var selectedAlarmWithLocation: EKAlarm? {
			get {
				return _selectedAlarmWithLocation
			}
		}
		
		// MARK: -
		
	}
	
	// MARK: - Public interface
	
	var delegate: VLReminderLocationViewDelegate? {
		get {
			return self.locationView().delegate
		}
		set {
			self.locationView().delegate = newValue
		}
	}
	
	var selectedAlarmWithLocation: EKAlarm? {
		get {
			return self.locationView().selectedAlarmWithLocation
		}
	}
	
	// MARK: -

}


