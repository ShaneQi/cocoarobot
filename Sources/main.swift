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
import PerfectCRUD

let bot = ZEGBot(token: token)

var mysql: Database<MySQLDatabaseConfiguration> {
	return Database(configuration: try! MySQLDatabaseConfiguration(
		database: dbName, host: dbHost, port: dbPort, username: dbUser, password: dbPassword))
}
try! mysql.create(CrashCounter.self, primaryKey: \.date)

var lastWelcomeMessage: (messageId: Int, chatId: Int)?

bot.run { updateResult, bot in

	guard case .success(let update) = updateResult else { return }

	guard let message = update.message else { return }

	guard (message.chat.type == .supergroup || message.chat.username?.lowercased() == "shaneqi") else {
		bot.send(message: "❌ Services only available in group.", to: message.chat)
		return
	}

	if message.newChatMember != nil {

		let text = [welcome + "\n",
		            commandList + "\n",
		            about
			].joined(separator: "\n")

		if let lastWelcomeMessage = lastWelcomeMessage {
			bot.deleteMessage(inChat: lastWelcomeMessage.chatId, messageId: lastWelcomeMessage.messageId)
		}

		if let welcomeMessage = bot.send(
			message: text,
			to: message.chat,
			parseMode: .markdown,
			disableWebPagePreview: true).value {
			lastWelcomeMessage = (welcomeMessage.messageId, welcomeMessage.chatId)
		}

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
				let crashCounter: CrashCounter = {
					let crashCounterTable = mysql.table(CrashCounter.self)
					if let todayCrashCounter = try! crashCounterTable.where(\CrashCounter.date == Date().firstMomentOfToday).first() {
						let counter = CrashCounter(count: todayCrashCounter.count + 1, date: todayCrashCounter.date)
						try! crashCounterTable.update(counter)
						return counter
					} else {
						let counter = CrashCounter(count: 1, date: Date())
						try! crashCounterTable.insert(counter)
						return counter
					}
				} ()
				let count = crashCounter.count
				bot.send(
					message: "Xcode 今日已崩溃 *\(count)* 次。",
					to: message,
					parseMode: .markdown)
				bot.send(Sticker(id: "CAADBQADFgADeW-oDo2q3CV0lvJBAg"), to: message)
			case "/admin", "/admin@cocoarobot":
				switch bot.getChatAdministrators(ofChatWithId: message.chatId) {
				case .success(let admins):
					let text = admins.compactMap({ $0.user.isBot ? nil : $0.user.username?.usernameWrapped })
						.joined(separator: " ")
					bot.send(message: text, to: message.chat)
				case .failure(let error):
					bot.send(message: "Failed to call admins.\n\(error)", to: shaneChatId)
				}
			default:
				break
			}
		default:
			break
		}
	})
}
