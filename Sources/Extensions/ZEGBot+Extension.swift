//
//  ZEGBot+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 7/7/18.
//

import ZEGBot

//extension Sticker {
//
//	init(id: String) {
//		self.fileId = id
//		self.emoji = nil
//		self.width = 0
//		self.height = 0
//		self.thumb = nil
//		self.fileSize = nil
//	}
//
//}

extension Int: Sendable {

	public var chatId: Int { return self }
	public var replyToMessageId: Int? { return nil }

}

extension User {

	var displayName: String {
		if let username = username {
			return "@" + username
		} else {
			let name = [firstName, lastName].compactMap({ $0 }).joined(separator: " ")
			if name.isEmpty {
				return "user\(id)"
			} else {
				return name
			}
		}
	}

}
