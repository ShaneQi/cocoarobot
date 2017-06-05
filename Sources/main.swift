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
			case "/apps", "/apps@cocoarobot":
				guard let products = try? Product.getAll(from: db) else { break }
				var productsDictionary = products.categorise({ $0.developer })
				var messageText = productsDictionary.map() { developer, products in
					products.reduce("👤 " + developer + "\n" ) { return $0 + "\($1)\n" }
					}.joined(separator: "\n")
				if messageText == "" { messageText = "❌ No App Found" }
				bot.send(
					message: messageText,
					to: message.chat,
					parseMode: .MARKDOWN,
					disableWebPagePreview: true)
			case "/wwdc", "/wwdc@cocoarobot":
				let fifthOfJune = Date(timeIntervalSince1970: 1496638800)
				let interval = fifthOfJune.timeIntervalSince(Date())
				var days = Int(ceil(interval / 60 / 60 / 24))
				if days < 0 { days = 0 }
				bot.send(
					message: "[WWDC17](https://developer.apple.com/wwdc/) 将于 June 5th 开幕，距离现在还有 *\(days)* 天。",
					to: message.chat,
					parseMode: .MARKDOWN)
			case "/addapp", "/addapp@cocoarobot":
				guard message.from?.username?.lowercased() == "shaneqi" else { return }
				var args = Arguements(string: text).makeIterator()
				_ = args.next()
				guard let title = args.next(),
					let developer = args.next(),
					let link = args.next(),
					let platform = args.next() else { return }
				let product = Product(title: title, developer: developer, link: link, platform: Product.Platform(rawValue: platform) ?? .iOS)
				do { 
					try product.replace(into: db) 
					bot.send(
						message: "\(product)",
						to: message,
						parseMode: .MARKDOWN,
						disableWebPagePreview: true)
				} catch {}
			case "/rmapp", "/rmapp@cocoarobot":
				guard message.from?.username?.lowercased() == "shaneqi" else { return }
				var args = Arguements(string: text).makeIterator()
				_ = args.next()
				guard let column = args.next(),
					let value = args.next() else { return }
				do { 
					try Product.remove(from: db, where: column, equals: value) 
					bot.send(
						message: "✅ Executed.",
						to: message,
						parseMode: .MARKDOWN,
						disableWebPagePreview: true)
				} catch {}
			default:
				break
			}
		default:
			break
		}
	})
	
})
