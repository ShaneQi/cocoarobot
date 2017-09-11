//
//  main.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

import ZEGBot
import MySQL
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

bot.run { update, bot in

	let timeStamp = Date().timeIntervalSince1970

	guard let message = update.message else { return }
	
	guard (message.chat.type == .supergroup || message.chat.username?.lowercased() == "shaneqi") else {
		bot.send(message: "❌ Services only available in group.", to: message.chat)
		return
	}
	
	if let newChatMemeber = message.newChatMember,
		timeStamp - welcomeTime > 60 * 5 {

        welcomeTime = timeStamp
        
		var text = [welcome + "\n",
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
			guard var text = message.text else { break }
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
      case "/iphonex", "/iphonex@cocoarobot":
        let interval = Int(Date(timeIntervalSince1970: 1505235600).timeIntervalSince(Date()))
        let day = interval / 86400
        let hour = interval / 3600 % 24
        let min = interval % 3600 / 60
        var timeComponents: [String] = []
        if day > 0 { timeComponents.append("\(day) 天") }
        if hour > 0 { timeComponents.append("\(hour) 小时") }
        if min > 0 { timeComponents.append("\(min) 分钟") }
        guard timeComponents.count > 0 else { break }
				bot.send(
					message: "现在距离 [Steve Jobs Theater 亮相](https://www.apple.com/apple-events/september-2017/) 还有 \(timeComponents.joined(separator: " ")).",
					to: message,
					parseMode: .markdown,
					disableWebPagePreview: true)
			default:
				break
			}
		default:
			break
		}
	})
}

