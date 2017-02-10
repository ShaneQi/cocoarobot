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
						CrashCounter.self,
						Product.self])
var crashCounter = (try! CrashCounter.get(primaryKeyValue: Date().toString(withFormat: CrashCounter.dateFormat), from: db)) ?? CrashCounter(count: 0, date: Date())

bot.run(with: {
	update, bot in
	
	guard let message = update.message else { return }
	
	guard (message.chat.type == .GROUP || message.chat.username?.lowercased() == "shaneqi") else {
		bot.send(message: "❌ Services only available in group.", to: message.chat)
		return
	}
	
	if let newChatMemeber = message.new_chat_member {
		var text = "Welcome to iOS/macOS/watchOS/tvOS developers group."
		if let username = newChatMemeber.username {
			text = [username.usernameWrapped,text].joined(separator: " ")
		}
		bot.send(message: text, to: message.chat)
	}
	
	message.entities?.forEach({ entity in
		switch entity.type {
		case .BOT_COMMAND:
			guard var text = message.text else { break }
			let command = text.subed(fromIndex: entity.offset, length: entity.length)
			switch command.lowercased() {
			case "/about", "/about@cocoarobot":
				bot.send(
					message: "Cocoa Robot is a pure Swift project, powered by [Perfect](https://github.com/PerfectlySoft/Perfect) and [ZEGBot](https://github.com/ShaneQi/ZEGBot), maintained by @ShaneQi. Submitting issues and pull requests on >> [GitHub](https://github.com/ShaneQi/cocoarobot) <<.",
					to: message,
					parseMode: .MARKDOWN,
					disableWebPagePreview: true)
			case "/crash", "/crash@cocoarobot":
				crashCounter.increase()
				try? crashCounter.replace(into: db)
				let count = crashCounter.count
				bot.send(
					message: "Xcode has crashed *\(count)* \("time".pluralize(count: count)) so far today.",
					to: message,
					parseMode: .MARKDOWN)
			case "/apps", "/apps@cocoarobot":
				guard let products = try? Product.getAll(from: db) else { break }
				var productsDictionary = products.categorise({ $0.developer })
				var messageText = productsDictionary.map() { developer, products in
					products.reduce(developer.usernameWrapped + "\n" ) { return $0 + " \($1.title) [[LINK](\($1.link))]\n" }
					}.joined(separator: "\n")
				if messageText == "" { messageText = "❌ No App Found" }
				bot.send(
					message: messageText,
					to: message.chat,
					parseMode: .MARKDOWN,
					disableWebPagePreview: true)
			default:
				break
			}
		default:
			break
		}
	})
	
})
