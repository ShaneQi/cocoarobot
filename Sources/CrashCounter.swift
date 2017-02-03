//
//  CrashCounter.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation

class CrashCounter {

	static var instance = CrashCounter()
	private init() {
		 count = db.selectCountFromCrashCount() ?? 0
	}
	
	var count: Int {
		didSet {
			if !Calendar.current.isDate(updatedAt, inSameDayAs: Date()) { count -= oldValue }
			try? db.replaceIntoCrashCount(count: count)
		}
	}
	
	var updatedAt: Date = .init()

}
