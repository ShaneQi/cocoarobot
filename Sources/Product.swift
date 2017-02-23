//
//  Product.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/9/17.
//
//

import SQLite

import Foundation

struct Product: CustomStringConvertible {
	
	var title: String
	var developer: String
	var link: String
	var platform: Platform
	
	enum Platform: String, CustomStringConvertible {
		case iOS      = "0"
		case macOS    = "1"
		case tvOS     = "2"
		case watchOS  = "3"
	
		var description: String {
			switch self {
			case .iOS:
				return "📱"
			case .macOS:
				return "🖥"
			case .watchOS:
				return "⌚️"
			case .tvOS:
				return "📺"
			}
		}
		
	}
	
	var description: String { return "\(platform) \(title) ([LINK](\(link)))" }
	
}

extension Product: DatabaseManaged, Gettable, Settable, Removable {
	
	static var tableCreatingStatement: String = "CREATE TABLE IF NOT EXISTS `products` (`title` TEXT, `developer` TEXT, `link` TEXT);"
	
	static func getAll(from database: SQLite) throws -> [Product] {
		var products = [Product]()
		try database.forEachRow(statement: "SELECT * FROM products;") {
			statement, _ in
			products.append(Product(
				title: statement.columnText(position: 0),
				developer: statement.columnText(position: 1),
				link: statement.columnText(position: 2),
				platform: Platform(rawValue: statement.columnText(position: 3)) ?? .iOS
			))
		}
		return products
	}
	
	static func get(primaryKeyValue: String, from database: SQLite) throws -> Product? {
		fatalError("Not implemented.")
	}

	func replace(into database: SQLite) throws {
		try database.execute(
			statement: "REPLACE INTO products VALUES (:1, :2, :3, :4);",
			doBindings: { statement in
				try statement.bind(position: 1, title)
				try statement.bind(position: 2, developer)
				try statement.bind(position: 3, link)
				try statement.bind(position: 4, platform.rawValue)
			})
	}

	static func remove(from database: SQLite, where column: String, equals value: String) throws {
		switch column {
		case "title":
			try database.execute(
				statement: "DELETE FROM products WHERE title = :1;",
				doBindings: { statement in
					try statement.bind(position: 1, value)
				})
		default:
			throw DBError()
		}
	}

}
