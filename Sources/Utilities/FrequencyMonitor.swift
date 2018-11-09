//
//  FrequencyMonitor.swift
//  cocoarobot
//
//  Created by Shane Qi on 11/3/18.
//

import Foundation

final class FrequencyMonitor {

	static let instance = FrequencyMonitor()

	private init() {}

	private var startedAt = Date()
	private var lastPunchTime = Date()
	private var punchCount: Double = 0

	func start() {
		startedAt = Date()
		lastPunchTime = startedAt
		punchCount = 0
	}

	func restart() {
		start()
	}

	func punch() {
		let now = Date()
		punchCount += 1
		NSLog("🕙 one %f", now.timeIntervalSince(lastPunchTime))
		NSLog("🕙             avg %f", now.timeIntervalSince(startedAt) / punchCount)
		lastPunchTime = now
	}

}
