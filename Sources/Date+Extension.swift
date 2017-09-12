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
	
	static func from(string: String, withFormat format: String) -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		return dateFormatter.date(from: string)
	}

	func stringComponentsCountingDown(to date: Date) -> [String] {
		let interval = Int(Date(timeIntervalSince1970: 1505235600).timeIntervalSince(Date()))
		let day = interval / 86400
		let hour = interval / 3600 % 24
		let min = interval % 3600 / 60
		var components: [String] = []
		if day > 0 { components.append("\(day) 天") }
		if hour > 0 { components.append("\(hour) 小时") }
		if min > 0 { components.append("\(min) 分钟") }
		return components
	} 

}
