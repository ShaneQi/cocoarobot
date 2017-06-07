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
						Session.self])
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
			case "/wwdc", "/wwdc@cocoarobot":
				guard var sessions = try? Session.getAll(from: db) else { break }
				sessions = Array(sessions.suffix(10)).reversed()
				var messageText = sessions.map({ return "\($0)" }).joined(separator: "\n")
				if messageText == "" {
					messageText = "❌ No Session Found"
				} else {
					messageText = "WWDC 2017 Sessions:\n" + messageText
				}
				bot.send(
					message: messageText,
					to: message.chat,
					parseMode: .MARKDOWN,
					disableWebPagePreview: true)
			case "/addss", "/addss@cocoarobot":
				guard message.from?.username?.lowercased() == "shaneqi" else { return }
				var args = Arguements(string: text).makeIterator()
				_ = args.next()
				guard let idString = args.next(),
					let id = Int(idString),
					let title = args.next(),
					let url = args.next() else { return }
				let session = Session(year: 2017, id: id, title: title, url: url)
				do { 
					try session.replace(into: db)
					bot.send(
						message: "✅ \(session)",
						to: message,
						parseMode: .MARKDOWN,
						disableWebPagePreview: true)
				} catch {}
			case "/rmss", "/rmss@cocoarobot":
				guard message.from?.username?.lowercased() == "shaneqi" else { return }
				var args = Arguements(string: text).makeIterator()
				_ = args.next()
				var next = args.next()
				var pairs = [(String, String)]()
				while let unwrappedNext = next {
					let key = unwrappedNext
					if let value = args.next() {
						pairs.append((key, value))
					}
					next = args.next()
				}
				do {
					try Session.remove(from: db, where: pairs)
					bot.send(
						message: "✅ Executed.",
						to: message,
						parseMode: .MARKDOWN)
				} catch {}
			default:
				break
			}
		default:
			break
		}
	})
	
})
