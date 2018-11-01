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
	try mysql().create(PendingMember.self, primaryKey: \.id)
	try mysql().create(WelcomeMessage.self, primaryKey: \.chatId)
} catch let error {
	bot.send(message: "Failed to create mysql tables.\n\(error)", to: shaneChatId)
}

bot.run { updateResult, bot in

	guard case .success(let update) = updateResult else { return }

	switch update {
	case .message(_, let message):
		guard authorizedGroups.contains(message.chat.id) || message.chat.id == shaneChatId else {
			bot.send(message: "❌ Service not authorized.", to: message.chat)
			bot.send(message:"Unauthorized service was requested by: (\(message.chat)).", to: shaneChatId)
			return
		}
		if let newMember = message.newChatMember {
//		if message.text == "new" {
//			let newMember = message.from!
			do {
				let pendingMemberTable = try mysql().table(PendingMember.self)
				try pendingMemberTable.where(\PendingMember.id == newMember.id).delete()
				switch bot.send(
					message: "[\(newMember.displayName)](tg://user?id=\(newMember.id)",
					to: message.chat,
					parseMode: .markdown,
					replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [[
						InlineKeyboardButton(text: "I'm good.", callbackData: verificationKey)
						]])) {
				case .success(let verificationMessage):
					try pendingMemberTable.insert(PendingMember(
						id: newMember.id, joinedAt: Date(),
						verificationMessageId: verificationMessage.messageId,
						chatId: verificationMessage.chatId))
				case .failure:
					break
				}
			} catch let error {
				bot.send(message: "Failed to send insert pending member.\n\(error)", to: shaneChatId)
			}
		} else if let entities = message.entities {
			entities.forEach { entity in
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
			}
		}
	case .callbackQuery(_, let callbackQuery):
		switch callbackQuery.data {
		case verificationKey?:
			do {
				let pendingMemberTable = try mysql().table(PendingMember.self)
				let query = pendingMemberTable.where(\PendingMember.id == callbackQuery.from.id)
				if let pendingMember = try query.first() {
					try query.delete()
					bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: "Thanks.")
					bot.deleteMessage(inChat: pendingMember.chatId, messageId: pendingMember.verificationMessageId)

					let text = [welcome + "\n",
								commandList + "\n",
								about
						].joined(separator: "\n")
					bot.send(message: text, to: pendingMember.chatId, parseMode: .markdown, disableWebPagePreview: true)
				} else {
					bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: "No action required from you.")
				}
			} catch let error {
				bot.send(message: "Failed to verify pending member.\n\(error)", to: shaneChatId)
			}
		default:
			break
		}
	default:
		break
	}
}
