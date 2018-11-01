//
//  PendingMember.swift
//  cocoarobot
//
//  Created by Shane Qi on 11/1/18.
//

import Foundation

struct PendingMember: Codable {

	let id: Int
	let joinedAt: Date
	let verificationMessageId: Int
	let chatId: Int

}
