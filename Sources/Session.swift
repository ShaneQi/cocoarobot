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

	var year: Int
	var id: Int
	var title: String
	var url: String

	var description: String { return "\(id). [\(title)](\(url))" }

}

extension Session: DatabaseManaged, Gettable, Settable, Removable {

	static var tableCreatingStatement: String = "CREATE TABLE IF NOT EXISTS `wwdc_sessions` (`year` INTEGER, `id` INTEGER, `title` TEXT, `url` TEXT, PRIMARY KEY (`id`, `year`));"

	static func getAll(from database: SQLite) throws -> [Session] {
		var sessions = [Session]()
		try database.forEachRow(statement: "SELECT * FROM wwdc_sessions;") {
			statement, _ in
			sessions.append(Session(
				year: statement.columnInt(position: 0),
				id: statement.columnInt(position: 1),
				title: statement.columnText(position: 2),
				url: statement.columnText(position: 3)
			))
		}
		return sessions
	}

	static func get(primaryKeyValue: String, from database: SQLite) throws -> Session? {
		fatalError("Not implemented.")
	}

	func replace(into database: SQLite) throws {
		try database.execute(
			statement: "REPLACE INTO wwdc_sessions VALUES (:1, :2, :3, :4);",
			doBindings: { statement in
				try statement.bind(position: 1, year)
				try statement.bind(position: 2, id)
				try statement.bind(position: 3, title)
				try statement.bind(position: 4, url)
		})
	}

	static func remove(from database: SQLite, where pairs: [(String, String)]) throws {
		guard pairs.count > 0 else { return }
		let safePairs = pairs.filter({ $0.0 == "id" || $0.0 == "year" || $0.0 == "title" })
		let whereStatement = pairs.enumerated().map({ return "\($0.element.0) = :\($0.offset + 1)" }).joined(separator: " AND ")
		try database.execute(
			statement: "DELETE FROM wwdc_sessions WHERE " + whereStatement,
			doBindings: { statement in
				try safePairs.enumerated().forEach({ offset, element in
					try statement.bind(position: offset + 1, element.1)
				})
		})
	}

}
