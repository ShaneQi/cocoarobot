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
CRUDLogging.queryLogDestinations = []
CRUDLogging.errorLogDestinations = []

func mysql() throws -> Database<MySQLDatabaseConfiguration> {
	return Database(configuration: try MySQLDatabaseConfiguration(
		database: dbName, host: dbHost, port: dbPort, username: dbUser, password: dbPassword))
}

do {
	let db = try mysql()
	try db.create(CrashCounter.self, primaryKey: \.date)
	try db.create(PendingMember.self, primaryKey: \.id)
	try db.create(WelcomeMessage.self, primaryKey: \.chatId)
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

			if let senderId = message.from?.id {
				do {
					let pendingMemberTable = try mysql().table(PendingMember.self)
					let query = pendingMemberTable.where(\PendingMember.id == senderId)
					if try query.count() > 0 {
						try bot.deleteMessage(inChat: message.chatId, messageId: message.messageId)
						Logger.default.log("Filtered a message.", bot: bot)
						// RETURN POINT
						return
					}
				} catch let error {
					Logger.default.log("Failed to filter message due to: \(error)", bot: bot)
				}
			}

			if let newMember = message.newChatMember {
				do {
					Logger.default.log("Received new chat member message at \(Date().timeIntervalSince1970).")
					Logger.default.log("The new chat memeber message's timestamp is \(message.date).")
					try bot.restrictChatMember(
						chatId: message.chatId,
						userId: newMember.id,
						untilDate: Date().addingTimeInterval(60 * 6),
						canSendMessages: false,
						canSendMediaMessages: false,
						canSendOtherMessages: false,
						canAddWebPagePreviews: false)
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
						newMemberMessageId: message.messageId,
						chatId: verificationMessage.chatId))
					func kickMemberIfNeeded(chatId: Int, user: User) {
						do {
							let query = try mysql().table(PendingMember.self)
								.where(\PendingMember.chatId == chatId && \PendingMember.id == user.id)
							if let memberToKick = try query.first() {
								do {
									try bot.deleteMessage(inChat: chatId, messageId: memberToKick.verificationMessageId)
									try bot.deleteMessage(inChat: chatId, messageId: memberToKick.newMemberMessageId)
								} catch let error {
									Logger.default.log("Failed to delete unverified member's verification/join message due to: \(error)", bot: bot)
								}
								try query.delete()
								try bot.kickChatMember(chatId: chatId, userId: user.id, untilDate: Date().addingTimeInterval(120))
								Logger.default.log("Kicking: \(user.displayName) from \(message.chatId)", bot: bot)
							}
						} catch let error {
							Logger.default.log("Failed to kick unverified member due to: \(error)", bot: bot)
						}
					}

					let name = [newMember.firstName, newMember.lastName].compactMap({ $0 }).joined(separator: "Ï").lowercased()
					var doesHitBlackList = true
					for words in blackListWords {
						var containsAllWords = true
						for word in words where !name.contains(word.lowercased()) {
							containsAllWords = false
							break
						}
						if !containsAllWords {
							doesHitBlackList = false
							break
						}
					}
					if doesHitBlackList {
						Logger.default.log("\(name) hit blacklist.", bot: bot)
					}
					let durationToWaitForVerification: Double = doesHitBlackList ? 5 : 60 * 5
					DispatchQueue(label: "com.shaneqi.cocoarobot.verifier.\(message.chatId).\(newMember.id)").async {
						#if os(Linux)
						_ = Timer.scheduledTimer(
						withTimeInterval: durationToWaitForVerification, repeats: false) { _ in
							kickMemberIfNeeded(chatId: message.chatId, user: newMember)
						}
						#else
						if #available(OSX 10.12, *) {
							_ = Timer.scheduledTimer(
							withTimeInterval: durationToWaitForVerification, repeats: false) { _ in
								kickMemberIfNeeded(chatId: message.chatId, user: newMember)
							}
						}
						#endif
						RunLoop.current.run()
					}
				} catch let error {
					Logger.default.log("Failed to complete verification request due to: \(error)", bot: bot)
				}
			} else if message.leftChatMember != nil {
				do {
					try bot.deleteMessage(inChat: message.chatId, messageId: message.messageId)
				} catch let error {
					Logger.default.log("Failed to delete left chat member message due to: \(error)", bot: bot)
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
							untilDate: Date(timeIntervalSince1970: 0),
							canSendMessages: true,
							canSendMediaMessages: true,
							canSendOtherMessages: true,
							canAddWebPagePreviews: true)

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
