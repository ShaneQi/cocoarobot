//
//  Logger.swift
//  cocoarobot
//
//  Created by Shane Qi on 11/1/18.
//

import ZEGBot
import Foundation

final class Logger {

	static let `default` = Logger()

	private init() {}

	func log(_ errorText: String, bot: ZEGBot) {
		NSLog(errorText)
		do {
			try bot.send(message: errorText, to: shaneChatId)
		} catch let error {
			NSLog("❌ YOU MISSED: \(errorText) due to \(error), ")
		}
	}

}
