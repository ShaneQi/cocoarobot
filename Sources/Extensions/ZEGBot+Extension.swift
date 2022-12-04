//
//  ZEGBot+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 7/7/18.
//

import ZEGBot

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
