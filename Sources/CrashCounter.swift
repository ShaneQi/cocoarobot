//
//  CrashCounter.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation
import MySQL

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
			if let count = row[0] as? Int,
				let dateString = row[1] as? String,
				let date = Date.from(string: dateString, withFormat: dateFormat) {
				result = CrashCounter(count: count, date: date)
			} else {
				dump(row[0])
				dump(row[1])
			}
		}
		return result
	}
	
}
