//
//  Product.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/9/17.
//
//

import SQLite

import Foundation

struct Product {
	
	var title: String
	var developer: String
	var link: String
  var platform: Platform

  enum Platform: String {
    case iOS      = "0"
    case macOS    = "1"  
    case tvOS     = "2"
    case watchOS  = "3"
  }
	
}

extension Product: DatabaseManaged, Gettable {

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

}
