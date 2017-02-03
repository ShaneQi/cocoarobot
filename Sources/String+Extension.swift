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
		let end = (start + length > characters.count) ? characters.count : start + length
		let fromIndex = index(startIndex, offsetBy: start)
		let toIndex = index(startIndex, offsetBy: end)
		var copy = self
		copy.removeSubrange(startIndex..<fromIndex)
		copy.removeSubrange(toIndex..<endIndex)
		return copy
	}
	
}
