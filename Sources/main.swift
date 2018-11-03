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
FrequencyMonitor.instance.start()

func mysql() throws -> Database<MySQLDatabaseConfiguration> {
	return Database(configuration: try MySQLDatabaseConfiguration(
		database: dbName, host: dbHost, port: dbPort, username: dbUser, password: dbPassword))
}

do {
	try mysql().create(CrashCounter.self, primaryKey: \.date)
	try mysql().create(PendingMember.self, primaryKey: \.id)
	try mysql().create(WelcomeMessage.self, primaryKey: \.chatId)
} catch let error {
	Logger.default.log("Failed to create mysql tables.\n\(error)", bot: bot)
}

bot.run { updateResult, bot in

	guard case .success(let update) = updateResult else { return }

	switch update {
	case .message(_, let message):
		guard authorizedChats.contains(message.chat.id) else {
			bot.send(message: String.unauthorizedChat, to: message.chat)
			Logger.default.log("Unauthorized service was requested by: (\(message.chat)).", bot: bot)
			return
		}

		FrequencyMonitor.instance.punch()

		if let newMember = message.newChatMember {
//		if message.text == "new" {
//			let newMember = message.from!
			do {
				let pendingMemberTable = try mysql().table(PendingMember.self)
				try pendingMemberTable.where(\PendingMember.id == newMember.id).delete()
				switch bot.send(
					message: "[\(newMember.displayName)](tg://user?id=\(newMember.id)) " + String.newMemberVerification,
					to: message.chat,
					parseMode: .markdown,
					replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [[
						InlineKeyboardButton(text: String.newMemberVerificationButton, callbackData: verificationKey)
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
				Logger.default.log("Failed to send insert pending member.\n\(error)", bot: bot)
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
							message: String.about,
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
								message: String(format: .crashCount, newCount),
								to: message,
								parseMode: .markdown)
							bot.send(Sticker(id: "CAADBQADFgADeW-oDo2q3CV0lvJBAg"), to: message)
						} catch let error {
							Logger.default.log("Failed to count crash.\n\(error)", bot: bot)
						}
					case "/admin", "/admin@cocoarobot":
						switch bot.getChatAdministrators(ofChatWithId: message.chatId) {
						case .success(let admins):
							let text = admins.compactMap({ $0.user.isBot ? nil : $0.user.username?.usernameWrapped })
								.joined(separator: " ")
							bot.send(message: text, to: message.chat)
						case .failure(let error):
							Logger.default.log("Failed to call admins.\n\(error)", bot: bot)
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
				let db = try mysql()
				let pendingMemberTable = db.table(PendingMember.self)
				let query = pendingMemberTable.where(\PendingMember.id == callbackQuery.from.id)
				if let pendingMember = try query.first() {
					try query.delete()
					bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationSuccess)
					bot.deleteMessage(inChat: pendingMember.chatId, messageId: pendingMember.verificationMessageId)

					let welcomeMessageTable = db.table(WelcomeMessage.self)
					let query = welcomeMessageTable.where(\WelcomeMessage.chatId == pendingMember.chatId)
					if let previousWelcomeMessage = try query.first() {
						bot.deleteMessage(inChat: previousWelcomeMessage.chatId, messageId: previousWelcomeMessage.id)
						try query.delete()
					}
					let text = [String.welcome + "\n",
								String.commandList + "\n",
								String.about
						].joined(separator: "\n")
					switch bot.send(
						message: text, to: pendingMember.chatId, parseMode: .markdown,
						disableWebPagePreview: true) {
					case .success(let message):
						try welcomeMessageTable.insert(WelcomeMessage(id: message.messageId, chatId: message.chatId))
					default:
						break
					}
				} else {
					bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationWarning)
				}
			} catch let error {
				Logger.default.log("Failed to verify pending member.\n\(error)", bot: bot)
			}
		default:
			break
		}
	default:
		break
	}
}
