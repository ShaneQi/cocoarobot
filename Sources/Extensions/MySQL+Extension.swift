//
//  MySQL+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 7/29/17.
//
//

import PerfectMySQL

struct MySQLError: Error {

	let code: UInt32
	let message: String

	init(mySQL: MySQL) {
		code = mySQL.errorCode()
		message = mySQL.errorMessage()
	}

}

extension MySQLStmt {

	func prepare(statement query: String, inDatabase database: MySQL) throws {
		guard prepare(statement: query) else {
			throw MySQLError(mySQL: database)
		}
	}

	func execute(inDatabase database: MySQL) throws {
		guard execute() else {
			throw MySQLError(mySQL: database)
		}
	}

}
