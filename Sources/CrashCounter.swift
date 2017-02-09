//
//  CrashCounter.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import Foundation
import SQLite

struct CrashCounter {
	
	static let dateFormat = "MM/dd/yyyy"
	
	var count: Int
	var date: Date
	
	mutating func increase() {
		if !Calendar.current.isDate(date, inSameDayAs: Date()) { count = 1 }
		else { count += 1 }
	}
	
}

extension CrashCounter: DatabaseManaged, Gettable, Settable {
	
	static var tableCreatingStatement: String = "CREATE TABLE IF NOT EXISTS `crash_count` (`date` TEXT PRIMARY KEY, `count` INTEGER);"
	
	func replace(into database: SQLite) throws {
		try database.execute(
			statement: "REPLACE INTO crash_count VALUES (:1, :2);",
			doBindings: { statement in
				try statement.bind(position: 1, date.toString(withFormat: CrashCounter.dateFormat))
				try statement.bind(position: 2, count)
		})
	}
	
	static func getAll(from database: SQLite) throws -> [CrashCounter] {
		fatalError("Not implemented.")
	}
	
	static func get(primaryKeyValue: String, from database: SQLite) throws -> CrashCounter? {
		var result: CrashCounter?
		try database.forEachRow(
			statement: "SELECT * FROM crash_count WHERE date = :1;",
			doBindings: { statement in
				try statement.bind(position: 1, primaryKeyValue)
		},
			handleRow: { statement, index in
				guard let date = Date.from(string: statement.columnText(position: 0), withFormat: dateFormat) else { return }
				let count = statement.columnInt(position: 1)
				result = CrashCounter(count: count, date: date)
		})
		return result
	}
	
}
