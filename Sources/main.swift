//
//  main.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

import ZEGBot
import PerfectMySQL
import Foundation

let bot = ZEGBot(token: token)
let db = MySQL()
let connected = db.connect(host: dbHost, user: dbUser, password: dbPassword, db: dbName, port: dbPort)
if !connected {
	dump(MySQLError(mySQL: db))
	exit(9)
}

var crashCounter = (try! CrashCounter.get(primaryKeyValue: Date().toString(withFormat: CrashCounter.dateFormat), from: db)) ?? CrashCounter(count: 0, date: Date())

var welcomeTime = Date().timeIntervalSince1970

bot.run { updateResult, bot in

	guard case .success(let update) = updateResult else { return }

	let timeStamp = Date().timeIntervalSince1970

	guard let message = update.message else { return }
	
	guard (message.chat.type == .supergroup || message.chat.username?.lowercased() == "shaneqi") else {
		bot.send(message: "❌ Services only available in group.", to: message.chat)
		return
	}
	
	if message.newChatMember != nil,
		timeStamp - welcomeTime > 60 * 5 {

        welcomeTime = timeStamp
        
		let text = [welcome + "\n",
		            about + "\n",
		            commandList
			].joined(separator: "\n")
        
		bot.send(message: text,
		         to: message.chat,
		         parseMode: .markdown,
		         disableWebPagePreview: true)
	}
	
	message.entities?.forEach({ entity in
		switch entity.type {
		case .botCommand:
			guard let text = message.text else { break }
			let command = text.subed(fromIndex: entity.offset, length: entity.length)
			switch command.lowercased() {
			case "/about", "/about@cocoarobot":
				bot.send(
					message: about,
					to: message,
					parseMode: .markdown,
					disableWebPagePreview: true)
			case "/crash", "/crash@cocoarobot":
				crashCounter.increase()
				try? crashCounter.replace(into: db)
				let count = crashCounter.count
				bot.send(
					message: "Xcode 今日已崩溃 *\(count)* 次。",
					to: message,
					parseMode: .markdown)
			default:
				break
			}
		default:
			break
		}
	})
}

