//
//  CrashCounter.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation
import PerfectMySQL

struct CrashCounter: Codable {

	var count: Int
	var date: Date

	init(count: Int, date: Date) {
		self.count = count
		self.date = date.firstMomentOfToday
	}

}
