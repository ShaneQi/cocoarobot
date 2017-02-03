//
//  SQLite.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import SQLite
import Foundation

private let dbPath = "./cocoadb.db"
private let crashCountDateKeyFormat = "MM/dd/yyyy"

class Database {
	
	init(path: String = dbPath) throws {
		sqlite = try SQLite(path)
		try sqlite.execute(statement: "PRAGMA foreign_keys = ON;")
		try sqlite.execute(statement: "PRAGMA busy_timeout = 3000;")
		
		/* Crash count. */
		try sqlite.execute(statement: "CREATE TABLE IF NOT EXISTS `crash_count` (`date` TEXT PRIMARY KEY, `count` INTEGER);")
	}
	
	private var sqlite: SQLite
	
	func replaceIntoCrashCount(count: Int, date: Date = Date()) throws {
		try sqlite.execute(
			statement: "REPLACE INTO crash_count VALUES (:1, :2);",
			doBindings: { statement in
				try statement.bind(position: 1, date.toString(withFormat: crashCountDateKeyFormat))
				try statement.bind(position: 2, count)
		})
	}
	
	func selectCountFromCrashCount(of date: Date = Date()) -> Int? {
		var count: Int?
		do {
			try sqlite.forEachRow(
				statement: "SELECT count FROM crash_count WHERE date = :1;",
				doBindings: { statement in
					try statement.bind(position: 1, date.toString(withFormat: crashCountDateKeyFormat))
			},
				handleRow: { statement, index in
					count = statement.columnInt(position: 0)
			})
		} catch {}
		return count
	}
	
	
	
}
