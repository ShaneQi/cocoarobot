//
//  ZEGBot+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 7/7/18.
//

import ZEGBot

extension Sticker {

	init(id: String) {
		self.fileId = id
		self.emoji = nil
		self.width = 0
		self.height = 0
		self.thumb = nil
		self.fileSize = nil
	}

}

extension Int: Sendable {

	public var chatId: Int { return self }
	public var replyToMessageId: Int? { return nil }

}
