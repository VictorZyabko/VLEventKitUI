//
// VLReminderTextLineTableCell.swift
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

class VLReminderTextLineTableCell: VLReminderBaseTableCell {

	let labelTitle = UILabel()
	let labelText = UILabel()
	let labelFullText = UILabel()
	
	private var _isTitleHighlighted = false
	private var _isTextHighlighted = false
	private var _isFullTextHighlighted = false
	private var _isFullTextDestructive = false
	private var _isTextOnBottom = false
	private var _activityIndicator: UIActivityIndicatorView? = nil
	
	override init() {
		super.init()
		self.contentView.addSubview(labelTitle)
		labelText.textColor = self.textColorGrayed()
		labelText.textAlignment = NSTextAlignment.right
		self.contentView.addSubview(labelText)
		self.updateFullTextColor()
		labelFullText.textAlignment = NSTextAlignment.center
		self.contentView.addSubview(labelFullText)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let rcCont = UIEdgeInsetsInsetRect(self.contentView.bounds, self.contentInsets())
		var rcTitle = rcCont
		var rcText = rcCont
		var rcFullText = rcCont
		if (_isTextOnBottom) {
			rcTitle.size.height = ceil("A".size(attributes: [NSFontAttributeName: labelTitle.font]).height)
			rcText.size.height = ceil("A".size(attributes: [NSFontAttributeName: labelText.font]).height)
			rcTitle.origin.y = rcCont.midY - (rcTitle.size.height + rcText.size.height) / 2.0
			rcText.origin.y = rcTitle.maxY
		}
		if let ind = _activityIndicator {
			var rcInd = rcCont
			rcInd.size = ind.sizeThatFits(rcInd.size)
			rcInd.origin.x = rcCont.maxX - rcInd.size.width
			rcInd.origin.y = rcCont.midY - rcInd.size.height / 2.0
			ind.frame = rcInd
			let distX: CGFloat = 2.0
			rcTitle.size.width = rcInd.origin.x - distX - rcTitle.origin.x
			rcText.size.width = rcInd.origin.x - distX - rcText.origin.x
			rcFullText.size.width = rcInd.origin.x - distX - rcFullText.origin.x
		}
		labelTitle.frame = rcTitle
		labelText.frame = rcText
		labelFullText.frame = rcFullText
	}
	
	private func updateFullTextColor() {
		var color = self.textColorDefault()
		if (_isFullTextHighlighted) {
			color = self.textColorHighlighted()
		} else if (_isFullTextDestructive) {
			color = self.textColorDestructive()
		}
		labelFullText.textColor = color
	}
	
	var isTitleHighlighted: Bool {
		get {
			return _isTitleHighlighted
		}
		set {
			if (_isTitleHighlighted != newValue) {
				_isTitleHighlighted = newValue
				labelTitle.textColor = _isTitleHighlighted ? self.textColorHighlighted() : self.textColorDefault()
			}
		}
	}
	
	var isTextHighlighted: Bool {
		get {
			return _isTextHighlighted
		}
		set {
			if (_isTextHighlighted != newValue) {
				_isTextHighlighted = newValue
				labelText.textColor = _isTextHighlighted ? self.textColorHighlighted() : self.textColorGrayed()
			}
		}
	}
	
	var isFullTextHighlighted: Bool {
		get {
			return _isFullTextHighlighted
		}
		set {
			if (_isFullTextHighlighted != newValue) {
				_isFullTextHighlighted = newValue
				self.updateFullTextColor()
			}
		}
	}
	
	var isFullTextDestructive: Bool {
		get {
			return _isFullTextDestructive
		}
		set {
			if (_isFullTextDestructive != newValue) {
				_isFullTextDestructive = newValue
				self.updateFullTextColor()
			}
		}
	}
	
	var isTextOnBottom: Bool {
		get {
			return _isTextOnBottom
		}
		set {
			if (_isTextOnBottom != newValue) {
				_isTextOnBottom = newValue
				labelText.textAlignment = _isTextOnBottom ? NSTextAlignment.left : NSTextAlignment.center
				self.setNeedsLayout()
			}
		}
	}
	
	var isActivityIndicatorStarted: Bool {
		get {
			return _activityIndicator != nil && !_activityIndicator!.isHidden
		}
	}
	
	func startActivityIndicator() {
		if (!self.isActivityIndicatorStarted) {
			if (_activityIndicator == nil) {
				_activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
				self.contentView.addSubview(_activityIndicator!)
			}
			if (_activityIndicator!.isHidden) {
				_activityIndicator!.isHidden = false
				_activityIndicator!.startAnimating()
			}
			self.setNeedsLayout()
		}
	}
	
	func stopActivityIndicator() {
		if (self.isActivityIndicatorStarted) {
			if (_activityIndicator != nil) {
				if (!_activityIndicator!.isHidden) {
					_activityIndicator!.stopAnimating()
					_activityIndicator!.isHidden = true
				}
				_activityIndicator!.removeFromSuperview()
				_activityIndicator = nil
			}
			self.setNeedsLayout()
		}
	}
	
	override func optimalHeight() -> CGFloat {
		var result = super.optimalHeight()
		if (_isTextOnBottom) {
			result = ceil(result * 1.5)
		}
		return result
	}

}
