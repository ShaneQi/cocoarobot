//
//  Session.swift
//  cocoarobot
//
//  Created by Shane Qi on 6/6/17.
//
//

import SQLite
import Foundation

struct Session: CustomStringConvertible {

	var title: String
	var url: String

	var description: String { return "[\(title)](\(url))" }

}

extension Session: DatabaseManaged, Gettable, Settable, Removable {

	static var tableCreatingStatement: String = "CREATE TABLE IF NOT EXISTS `wwdc_sessions` (`title` TEXT, `url` TEXT);"

	static func getAll(from database: SQLite) throws -> [Session] {
		var sessions = [Session]()
		try database.forEachRow(statement: "SELECT * FROM wwdc_sessions;") {
			statement, _ in
			sessions.append(Session(
				title: statement.columnText(position: 0),
				url: statement.columnText(position: 1)
			))
		}
		return sessions
	}

	static func get(primaryKeyValue: String, from database: SQLite) throws -> Session? {
		fatalError("Not implemented.")
	}

	func replace(into database: SQLite) throws {
		try database.execute(
			statement: "REPLACE INTO wwdc_sessions VALUES (:1, :2);",
			doBindings: { statement in
				try statement.bind(position: 1, title)
				try statement.bind(position: 2, url)
		})
	}

	static func remove(from database: SQLite, where column: String, equals value: String) throws {
		switch column {
		case "title":
			try database.execute(
				statement: "DELETE FROM wwdc_sessions WHERE title = :1;",
				doBindings: { statement in
					try statement.bind(position: 1, value)
			})
		default:
			throw DBError()
		}
	}

}
