//
//  Sequence+Extension.swift
//  cocoarobot
//
//  Created by Shane Qi on 2/9/17.
//
//

public extension Sequence {
	func categorise<U : Hashable>(_ key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
		var dictionary: [U:[Iterator.Element]] = [:]
		for element in self {
			let key = key(element)
			if case nil = dictionary[key]?.append(element) { dictionary[key] = [element] }
		}
		return dictionary
	}
}
