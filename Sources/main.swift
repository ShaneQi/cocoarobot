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
	Logger.default.log("Failed to create mysql tables due to: \(error)", bot: bot)
}

do {
	try bot.run { update, bot in

		switch update {
		case .message(_, let message):
			guard authorizedChats.contains(message.chat.id) else {
				do {
					try bot.send(message: String.unauthorizedChat, to: message.chat)
					Logger.default.log("Unauthorized service was requested by: (\(message.chat)).", bot: bot)
				} catch let error {
					Logger.default.log("Failed to send unauthorized service alert due to: \(error)", bot: bot)
				}
				return
			}

			if let newMember = message.newChatMember {
				do {
					let pendingMemberTable = try mysql().table(PendingMember.self)
					try pendingMemberTable.where(\PendingMember.id == newMember.id).delete()
					let verificationMessage = try bot.send(
						message: "[\(newMember.displayName)](tg://user?id=\(newMember.id)) " + String.newMemberVerification,
						to: message.chat,
						parseMode: .markdown,
						replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [[
							InlineKeyboardButton(text: String.newMemberVerificationButton, callbackData: verificationKey)
							]]))
					try pendingMemberTable.insert(PendingMember(
						id: newMember.id, joinedAt: Date(),
						verificationMessageId: verificationMessage.messageId,
						chatId: verificationMessage.chatId))
					try bot.restrictChatMember(
						chatId: message.chatId,
						userId: newMember.id,
						untilDate: 0,
						canSendMessages: false,
						canSendMediaMessages: false,
						canSendOtherMessages: false,
						canSendWebPagePreviews: false)
				} catch let error {
					Logger.default.log("Failed to complete verification request due to: \(error)", bot: bot)
				}
			} else if let entities = message.entities {
				entities.forEach { entity in
					switch entity.type {
					case .botCommand:
						guard let text = message.text else { break }
						let command = text.subed(fromIndex: entity.offset, length: entity.length)
						switch command.lowercased() {
						case "/about", "/about@cocoarobot":
							do {
								try bot.send(
									message: String.about,
									to: message,
									parseMode: .markdown,
									disableWebPagePreview: true)
							} catch let error {
								Logger.default.log("Failed to send about message due to: \(error)", bot: bot)
							}
						case "/crash", "/crash@cocoarobot":
							do {
								let crashCounterTable = try mysql().table(CrashCounter.self)
								let date = Date().firstMomentOfToday
								let query = crashCounterTable.where(\CrashCounter.date == date)
								let newCount = (try query.first()?.count ?? 0) + 1
								try query.delete()
								let counter = CrashCounter(count: newCount, date: date)
								try crashCounterTable.insert(counter)
								try bot.send(
									message: String(format: .crashCount, newCount),
									to: message,
									parseMode: .markdown)
								try bot.send(Sticker(id: "CAADBQADFgADeW-oDo2q3CV0lvJBAg"), to: message)
							} catch let error {
								Logger.default.log("Failed to count crash die to: \(error)", bot: bot)
							}
						case "/admin", "/admin@cocoarobot":
							do {
								let admins = try bot.getChatAdministrators(ofChatWithId: message.chatId)
								let text = admins.compactMap({ $0.user.isBot ? nil : $0.user.username?.usernameWrapped })
									.joined(separator: " ")
								try bot.send(message: text, to: message.chat)
							} catch let error {
								Logger.default.log("Failed to call admins due to: \(error)", bot: bot)
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
						try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationSuccess)
						try bot.deleteMessage(inChat: pendingMember.chatId, messageId: pendingMember.verificationMessageId)
						try bot.restrictChatMember(
							chatId: pendingMember.chatId,
							userId: pendingMember.id,
							untilDate: 0,
							canSendMessages: true,
							canSendMediaMessages: true,
							canSendOtherMessages: true,
							canSendWebPagePreviews: true)

						let welcomeMessageTable = db.table(WelcomeMessage.self)
						let query = welcomeMessageTable.where(\WelcomeMessage.chatId == pendingMember.chatId)
						if let previousWelcomeMessage = try query.first() {
							try? bot.deleteMessage(inChat: previousWelcomeMessage.chatId, messageId: previousWelcomeMessage.id)
							try query.delete()
						}
						let text = [String.welcome + "\n",
									String.commandList + "\n",
									String.about
							].joined(separator: "\n")
						let newWelcomeMessage = try bot.send(
							message: text, to: pendingMember.chatId, parseMode: .markdown,
							disableWebPagePreview: true)
						try welcomeMessageTable.insert(WelcomeMessage(
							id: newWelcomeMessage.messageId, chatId: newWelcomeMessage.chatId))
					} else {
						try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationWarning)
					}
				} catch let error {
					Logger.default.log("Failed to finish verification due to: \(error)", bot: bot)
				}
			default:
				break
			}
		default:
			break
		}
	}
} catch let error {
	Logger.default.log("Exit due to: \(error)", bot: bot)
}
