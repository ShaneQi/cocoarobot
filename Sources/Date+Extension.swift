//
//  Date+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation

extension Date {

	func toString(withFormat format: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		return dateFormatter.string(from: self)
	}

}
