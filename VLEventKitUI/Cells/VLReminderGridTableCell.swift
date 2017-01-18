//
// VLReminderGridTableCell.swift
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

class VLReminderGridTableCell: VLReminderBaseTableCell {
	
	private var _itemSize = CGSize(width: 32, height: 32)
	private var _labels = [UILabel]()
	private let _itemBackColor = UIColor.white
	private let _itemBackSelectedColor = UIColor.blue
	private let _itemBorderColor = UIColor.lightGray
	private let _tap = UITapGestureRecognizer();
	private var _selectedItems = Set<String>()
	private var _previousSelectedItems = Set<String>()

	required init(itemTitles: [String], itemSize: CGSize) {
		super.init()
		self.selectionStyle = UITableViewCellSelectionStyle.none
		self.contentMode = UIViewContentMode.redraw
		for title in itemTitles {
			let label = UILabel()
			label.baselineAdjustment = UIBaselineAdjustment.alignCenters
			label.textAlignment = NSTextAlignment.center
			label.text = title
			self.contentView.addSubview(label)
			_labels.append(label)
		}
		_itemSize = itemSize
		
		_tap.addTarget(self, action: #selector(onTap(tap:)))
		self.contentView.addGestureRecognizer(_tap)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let rcCont = self.contentView.bounds
		let count = _labels.count
		if (count == 0) {
			return
		}
		let itemsPerWidth = Int(round(rcCont.size.width / _itemSize.width))
		if (itemsPerWidth == 0) {
			return
		}
		let itemWidth = rcCont.size.width / CGFloat(itemsPerWidth)
		let itemHeight = _itemSize.height
		for (index, label) in _labels.enumerated() {
			var rcItem = rcCont
			rcItem.size.width = itemWidth
			rcItem.size.height = itemHeight
			let nRow = index / itemsPerWidth
			let nCol = index - nRow * itemsPerWidth
			rcItem.origin.x = rcCont.origin.x + itemWidth * CGFloat(nCol)
			rcItem.origin.y = rcCont.origin.y + itemHeight * CGFloat(nRow)
			label.frame = rcItem
		}
	}
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		let ctx = UIGraphicsGetCurrentContext()!
		for label in _labels {
			let rcItem = label.frame
			let title = label.text ?? ""
			if (_selectedItems.contains(title)) {
				_itemBackSelectedColor.setFill()
			} else {
				_itemBackColor.setFill()
			}
			ctx.fill(rcItem)
		}
		_itemBorderColor.setStroke()
		ctx.setLineWidth(0.5)
		for label in _labels {
			let rcItem = label.frame
			ctx.move(to: rcItem.origin)
			ctx.addLine(to: CGPoint(x: rcItem.maxX, y: rcItem.origin.y))
			ctx.addLine(to: CGPoint(x: rcItem.maxX, y: rcItem.maxY))
			ctx.addLine(to: CGPoint(x: rcItem.origin.x, y: rcItem.maxY))
		}
		ctx.strokePath()
	}
	
	func onTap(tap: UITapGestureRecognizer) {
		if (tap.state == UIGestureRecognizerState.ended) {
			let point = tap.location(in: self.contentView)
			for label in _labels {
				let rcItem = label.frame
				if (rcItem.contains(point)) {
					let title = label.text ?? ""
					if (_selectedItems.contains(title)) {
						_previousSelectedItems = _selectedItems
						_selectedItems.remove(title)
					} else {
						_previousSelectedItems = _selectedItems
						_selectedItems.insert(title)
					}
					self.setNeedsDisplay()
					self.delegate?.reminderBaseTableCell?(self, didValueChange: nil)
					break
				}
			}
		}
	}
	
	func optimalHeightForWidth(_ width: CGFloat) -> CGFloat {
		let count = _labels.count
		if (count > 0) {
			let itemsPerWidth = Int(round(width / _itemSize.width))
			if (itemsPerWidth > 0) {
				let itemsPerHeight = Int(ceil(CGFloat(count) / CGFloat(itemsPerWidth)))
				return CGFloat(itemsPerHeight) * _itemSize.height
			}
		}
		return 100.0
	}
	
	var selectedItems: Set<String> {
		get {
			return _selectedItems
		}
		set {
			if (_selectedItems != newValue) {
				_previousSelectedItems = _selectedItems
				_selectedItems = newValue
				self.setNeedsDisplay()
			}
		}
	}
	
	var previousSelectedItems: Set<String> {
		get {
			return _previousSelectedItems
		}
	}

}
