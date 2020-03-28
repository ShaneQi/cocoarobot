//
//  String+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/2/17.
//
//

extension String {

	var usernameWrapped: String { get { return ("@" + self) } }

}

extension String {
	
	func subed(fromIndex offset: Int, length: Int) -> String {
		let start = (offset < 0) ? 0 : offset
		let end = (start + length > count) ? count : start + length
		let fromIndex = index(startIndex, offsetBy: start)
		let toIndex = index(startIndex, offsetBy: end)
		var copy = self
		copy.removeSubrange(toIndex..<endIndex)
		copy.removeSubrange(startIndex..<fromIndex)
		return copy
	}

}

extension String {

	static let unauthorizedChat = "❌ Service not authorized in this chat."
	static let welcome = [
		-1001107934528: "欢迎加入 iOS/macOS/iPadOS/watchOS/tvOS 开发者群组。",
		-1001344763823: "欢迎加入 Eastwatch App 讨论组。"
	]
	static func newMemberVerification(forChatId chatId: Int) -> String {
		return [
			welcome[chatId],
			"*发言前请点击下方验证按钮。*\n*若五分钟内无法完成验证，你将会被从此群组中移除。*",
			"(BETA)"
			].compactMap({ $0 }).joined(separator: "\n\n")
	}
	static let newMemberVerificationButton = "我是好人"
	static let verificationSuccess = "验证成功，谢谢。"
	static let verificationWarning = "无需你的验证，谢谢。"
	static let about = "Cocoa Robot 开源在 [GitHub](https://github.com/ShaneQi/cocoarobot)."
	static let commandList = [
		-1001107934528: [
			"命令列表：",
			"/crash - 今天你的 Xcode 崩溃了吗？"
			].joined(separator: "\n")
	]
	static let crashCount = "Xcode 今日已崩溃 *%d* 次。"

	
}
