//
//  main.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

import ZEGBot

let bot = ZEGBot(token: token)

bot.run(with: {
	update, bot in
	
	guard let message = update.message else { return }
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
			switch command.uppercased() {
			case "/ABOUT":
				bot.send(
					message: "Cocoa Robot powered by [Swift 3.1](https://github.com/apple/swift), [Perfect](https://github.com/PerfectlySoft/Perfect) and [ZEGBot](https://github.com/ShaneQi/ZEGBot)，maintained by @ShaneQi. Submitting issues and pull requests on >> [GitHub](https://github.com/ShaneQi/cocoarobot) <<.",
					to: message,
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
