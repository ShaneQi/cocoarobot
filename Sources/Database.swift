//
//  SQLite.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/3/17.
//
//

import SQLite

extension SQLite {

	convenience init(in path: String, managing models: [DatabaseManaged.Type]) throws {
		try self.init(path)
		try execute(statement: "PRAGMA foreign_keys = ON;")
		try execute(statement: "PRAGMA busy_timeout = 3000;")
		try models.forEach({ try execute(statement: $0.tableCreatingStatement) })
	}

}

protocol Gettable {
	
	static func getAll(from database: SQLite) throws -> [Self]

	static func get(primaryKeyValue: String, from database: SQLite) throws -> Self?
	
}

protocol Settable {
	
	func replace(into database: SQLite) throws
	
}

protocol DatabaseManaged {
	
	static var tableCreatingStatement: String { get }
	
}
