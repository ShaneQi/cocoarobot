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

func mysql() throws -> Database<MySQLDatabaseConfiguration> {
	return Database(configuration: try MySQLDatabaseConfiguration(
		database: dbName, host: dbHost, port: dbPort, username: dbUser, password: dbPassword))
}

do {
	try mysql().create(CrashCounter.self, primaryKey: \.date)
} catch let error {
	bot.send(message: "Failed to create crash count table.\n\(error)", to: shaneChatId)
}

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
				do {
					let crashCounterTable = try mysql().table(CrashCounter.self)
					let date = Date().firstMomentOfToday
					let query = crashCounterTable.where(\CrashCounter.date == date)
					let newCount = (try query.first()?.count ?? 0) + 1
					try query.delete()
					let counter = CrashCounter(count: newCount, date: date)
					try crashCounterTable.insert(counter)
					bot.send(
						message: "Xcode 今日已崩溃 *\(newCount)* 次。",
						to: message,
						parseMode: .markdown)
					bot.send(Sticker(id: "CAADBQADFgADeW-oDo2q3CV0lvJBAg"), to: message)
				} catch let error {
					bot.send(message: "Failed to count crash.\n\(error)", to: shaneChatId)
				}
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
