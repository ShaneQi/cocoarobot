//
//  main.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

import ZEGBot
import SQLite
import Foundation

let bot = ZEGBot(token: token)
let db = try! SQLite(in: dbPath,
                     managing: [
						CrashCounter.self])
var crashCounter = (try! CrashCounter.get(primaryKeyValue: Date().toString(withFormat: CrashCounter.dateFormat), from: db)) ?? CrashCounter(count: 0, date: Date())

bot.run(with: {
	update, bot in

	guard let message = update.message else { return }
	
	guard (message.chat.type == .SUPERGROUP || message.chat.username?.lowercased() == "shaneqi") else {
		bot.send(message: "❌ Services only available in group.", to: message.chat)
		return
	}
	
	if let newChatMemeber = message.new_chat_member {
		var text = [welcome + "\n",
		            about + "\n",
		            commandList
			].joined(separator: "\n")
		if let username = newChatMemeber.username {
			text = [username.usernameWrapped,text].joined(separator: " ")
		}
		bot.send(message: text,
		         to: message.chat,
		         parseMode: .MARKDOWN,
		         disableWebPagePreview: true)
	}
	
	message.entities?.forEach({ entity in
		switch entity.type {
		case .BOT_COMMAND:
			guard var text = message.text else { break }
			let command = text.subed(fromIndex: entity.offset, length: entity.length)
			switch command.lowercased() {
			case "/about", "/about@cocoarobot":
				bot.send(
					message: about,
					to: message,
					parseMode: .MARKDOWN,
					disableWebPagePreview: true)
			case "/crash", "/crash@cocoarobot":
				crashCounter.increase()
				try? crashCounter.replace(into: db)
				let count = crashCounter.count
				bot.send(
					message: "Xcode 今日已崩溃 *\(count)* 次。",
					to: message,
					parseMode: .MARKDOWN)
			default:
				break
			}
		default:
			break
		}
	})
	
})
