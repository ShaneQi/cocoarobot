//
//  main.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

import ZEGBot
import Foundation
import MySQLNIO

let bot = ZEGBot(token: token)
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

func mysqlConnection() throws -> MySQLConnection {
	let eventLoop = eventLoopGroup.next()
	var tls = TLSConfiguration.makeClientConfiguration()
	tls.certificateVerification = .none
	let conn = try MySQLConnection.connect(
//		to: .init(ipAddress: "0.0.0.0", port: 3306),
		to: .makeAddressResolvingHost(dbHost, port: dbPort),
		username: dbUser,
		database: dbName,
		password: dbPassword,
		tlsConfiguration: tls,
		on: eventLoop
	).wait()
	return conn
}

//do {
//	let db = try mysql()
//	try db.create(CrashCounter.self, primaryKey: \.date)
//	try db.create(PendingMember.self, primaryKey: \.id)
//	try db.create(WelcomeMessage.self, primaryKey: \.chatId)
//} catch let error {
//	Logger.default.log("Failed to create mysql tables due to: \(error)", bot: bot)
//}

do {
	try bot.run { updates, bot in
		for update in updates {
		switch update {
		case let .message(_, message):
			guard authorizedChats.contains(message.chat.id) else {
				do {
					try bot.send(message: String.unauthorizedChat, to: message.chat)
					Logger.default.log("Unauthorized service was requested by: (\(message.chat)).", bot: bot)
				} catch let error {
					Logger.default.log("Failed to send unauthorized service alert due to: \(error)", bot: bot)
				}
				break
			}

			if let senderId = message.from?.id {
				do {
print("sql")
					let mysql = try mysqlConnection()
					defer {
						try? mysql.close().wait()
					}
print("result")
					let result = try mysql.query(
						"SELECT * FROM PendingMember WHERE id = ?;",
						[MySQLData(int: senderId)]).wait()
					if result.count > 0 {
						try bot.deleteMessage(inChat: message.chatId, messageId: message.messageId)
						Logger.default.log("Filtered a message.", bot: bot)
						break
					}
				} catch let error {
					Logger.default.log("Failed to filter message due to: \(error)", bot: bot)
				}
			}

			if let newMember = message.newChatMember {
				do {
					let mysql = try mysqlConnection()
					defer {
						try? mysql.close().wait()
					}
					let dateFormatter = DateFormatter()
					dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
					dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
					Logger.default.log("Received new chat member message at \(dateFormatter.string(from: Date())).")
					Logger.default.log("""
					The new chat memeber message's timestamp is \
					\(dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(message.date)))).
					""")
					try bot.restrictChatMember(
						chatId: message.chatId,
						userId: newMember.id,
						untilDate: Date().addingTimeInterval(60 * 6),
						canSendMessages: false,
						canSendMediaMessages: false,
						canSendOtherMessages: false,
						canAddWebPagePreviews: false)
					_ = try mysql.query("DELETE FROM PendingMember WHERE id = ?;", [MySQLData(int: newMember.id)]).wait()
					let verificationMessage = try bot.send(
						message: "[\(newMember.displayName)](tg://user?id=\(newMember.id)) " + String.newMemberVerification,
						to: message.chat,
						parseMode: .markdown,
						replyMarkup: InlineKeyboardMarkup(inlineKeyboard: [[
							InlineKeyboardButton(text: String.newMemberVerificationButton, callbackData: verificationKey),
							InlineKeyboardButton(text: String.newMemberAdminOverrideButton, callbackData: adminOverrideKey)
						]]))
					_ = try mysql.query(
						"INSERT INTO PendingMember VALUES (?, ?, ?, ?, ?);",
						[
							MySQLData(int: newMember.id),
							MySQLData(date: Date()),
							MySQLData(int: verificationMessage.messageId),
							MySQLData(int: message.messageId),
							MySQLData(int: verificationMessage.chatId)
						]).wait()
					func kickMemberIfNeeded(chatId: Int, user: User) {
						do {
							let mysql = try mysqlConnection()
							defer {
								try? mysql.close().wait()
							}
							let result = try mysql.query(
								"SELECT * FROM PendingMember WHERE chatId = ? AND id = ?;",
								[MySQLData(int: chatId), MySQLData(int: user.id)]).wait()
							if let memberToKick = result.first,
							   let verificationMessageId = memberToKick.column("verificationMessageId")?.int,
							   let newMemberMessageId = memberToKick.column("newMemberMessageId")?.int {
								do {
									try bot.deleteMessage(inChat: chatId, messageId: verificationMessageId)
									try bot.deleteMessage(inChat: chatId, messageId: newMemberMessageId)
								} catch let error {
									Logger.default.log("Failed to delete unverified member's verification/join message due to: \(error)", bot: bot)
								}
								_ = try mysql.query(
									"DELETE FROM PendingMember WHERE chatId = ? AND id = ?;",
									[MySQLData(int: chatId), MySQLData(int: user.id)]).wait()
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
						_ = Timer.scheduledTimer(
							withTimeInterval: durationToWaitForVerification, repeats: false) { _ in
								kickMemberIfNeeded(chatId: message.chatId, user: newMember)
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
								let mysql = try mysqlConnection()
								defer {
									try? mysql.close().wait()
								}
								let date = Date().firstMomentOfToday
								let result = try mysql.query("SELECT * FROM CrashCounter WHERE date = ?;", [MySQLData(date: date)]).wait().first
								let previousCount = result?.column("count")?.int
								let newCount = (previousCount ?? 0) + 1
								_ = try mysql.query("REPLACE INTO CrashCounter VALUES (?, ?);", [MySQLData(int: newCount), MySQLData(date: date)]).wait()
								try bot.send(
									message: String(format: .crashCount, newCount),
									to: message,
									parseMode: .markdown)
								try bot.send(stickerAt: .telegramServer(fileId: "CAADBQADFgADeW-oDo2q3CV0lvJBAg"), to: message)
							} catch let error {
								Logger.default.log("Failed to count crash due to: \(error)", bot: bot)
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
					let mysql = try mysqlConnection()
					defer {
						try? mysql.close().wait()
					}
					let result = try mysql.query("SELECT * FROM PendingMember WHERE id = ?;", [MySQLData(int: callbackQuery.from.id)]).wait()
					if let row = result.first {
						_ = try mysql.query("DELETE FROM PendingMember WHERE id = ?;", [MySQLData(int: callbackQuery.from.id)]).wait()
						try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationSuccess)
						if let chatId = row.column("chatId")?.int,
						   let verificationMessageId = row.column("verificationMessageId")?.int {
							try bot.deleteMessage(inChat: chatId, messageId: verificationMessageId)
							try bot.restrictChatMember(
								chatId: chatId,
								userId: callbackQuery.from.id,
								untilDate: Date(timeIntervalSince1970: 0),
								canSendMessages: true,
								canSendMediaMessages: true,
								canSendOtherMessages: true,
								canAddWebPagePreviews: true)
							let result = try mysql.query("SELECT * FROM WelcomeMessage WHERE chatId = ?;", [MySQLData(int: chatId)]).wait()
							if let row = result.first,
							   let previousWelcomeMessageId = row.column("id")?.int {
								try? bot.deleteMessage(inChat: chatId, messageId: previousWelcomeMessageId)
							}
							let text = [String.welcome + "\n",
										String.commandList + "\n",
										String.about
							].joined(separator: "\n")
							let newWelcomeMessage = try bot.send(
								message: text, to: chatId, parseMode: .markdown,
								disableWebPagePreview: true)
							_ = try mysql.query("REPLACE INTO WelcomeMessage VALUES (?, ?);", [MySQLData(int: newWelcomeMessage.messageId), MySQLData(int: newWelcomeMessage.chatId)]).wait()
						}
					} else {
						try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.verificationWarning)
					}
				} catch let error {
					Logger.default.log("Failed to finish verification due to: \(error)", bot: bot)
				}
			case adminOverrideKey?:
				do {
					let allegedAdminId = callbackQuery.from.id
					guard let message = callbackQuery.message else {
						Logger.default.log("Alleged admin (\(allegedAdminId)) failed to admin override new member due to: didn't find the verification message.", bot: bot)
						break
					}
					let chatId = message.chat.id
					let admins = try bot.getChatAdministrators(ofChatWithId: chatId)
					if admins.contains(where: { $0.user.id == allegedAdminId }) {
						let mysql = try mysqlConnection()
						defer {
							try? mysql.close().wait()
						}
						let adminId = allegedAdminId
						let result = try mysql.query(
							"SELECT * FROM PendingMember WHERE verificationMessageId = ?;",
							[MySQLData(int: message.messageId)]).wait()
						if let row = result.first,
						   let id = row.column("id")?.int,
						   let verificationMessageId = row.column("verificationMessageId")?.int,
						   let newMemberMessageId = row.column("newMemberMessageId")?.int {
							do {
								try bot.deleteMessage(inChat: chatId, messageId: verificationMessageId)
								try bot.deleteMessage(inChat: chatId, messageId: newMemberMessageId)
							} catch let error {
								Logger.default.log("Failed to delete unverified member's verification/join message due to: \(error)", bot: bot)
							}
							_ = try mysql.query(
								"DELETE FROM PendingMember WHERE verificationMessageId = ?;",
								[MySQLData(int: message.messageId)]).wait()
							try bot.kickChatMember(chatId: chatId, userId: id, untilDate: Date().addingTimeInterval(120))
							Logger.default.log("Admin (\(adminId)) overriding new member: \(id) from \(chatId)", bot: bot)
							try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.newMemberAdminOverrideSuccess)
						} else {
							Logger.default.log("Admin (\(adminId)) failed to admin override a new member from \(chatId) due to: didn't find the pending member.", bot: bot)
						}
					} else {
						do {
							try bot.answerCallbackQuery(callbackQueryId: callbackQuery.id, text: String.newMemberAdminOverrideWarning)
						} catch {
							Logger.default.log("Failed to send admin override new member warning due to: \(error)", bot: bot)
						}
					}
				} catch let error {
					Logger.default.log("Failed to admin override new member due to: \(error)", bot: bot)
				}
			default:
				break
			}
		default:
			break
		}
		}
	}
} catch let error {
	Logger.default.log("Exit due to: \(error)", bot: bot)
}
