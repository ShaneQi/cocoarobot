//
//  CrashCounter.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation
import PerfectMySQL

struct CrashCounter {
	
	static let dateFormat = "MM/dd/yyyy"
	
	var count: Int
	var date: Date
	
	mutating func increase() {
		if !Calendar.current.isDate(date, inSameDayAs: Date()) { 
			count = 1
			date = Date()
		}
		else { count += 1 }
	}
	
}

extension CrashCounter {
	
	static var tableCreatingStatement: String = "CREATE TABLE IF NOT EXISTS `crash_count` (`date` TEXT PRIMARY KEY, `count` INTEGER);"
	
	func replace(into database: MySQL) throws {
		let statement = MySQLStmt(database)
		try statement.prepare(statement: "REPLACE INTO crash_count VALUES (?, ?);", inDatabase: database)
		statement.bindParam(date.toString(withFormat: CrashCounter.dateFormat))
		statement.bindParam(count)
		try statement.execute(inDatabase: database)
	}
	
	static func get(primaryKeyValue: String, from database: MySQL) throws -> CrashCounter? {
		var result: CrashCounter?
		let statement = MySQLStmt(database)
		try statement.prepare(statement: "SELECT * FROM crash_count WHERE date = ?;", inDatabase: database)
		statement.bindParam(primaryKeyValue)
		try statement.execute(inDatabase: database)
		_ = statement.results().forEachRow { row in
			if let dateString = row[0] as? String,
				let date = Date.from(string: dateString, withFormat: dateFormat),
				let count = row[1] as? Int32 {
				result = CrashCounter(count: Int(count), date: date)
			}
		}
		return result
	}
	
}
