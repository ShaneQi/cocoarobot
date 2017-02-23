struct Arguements: Sequence, IteratorProtocol {

	private var characters: String.CharacterView
	
	init(string: String) {
		self.characters = string.characters
	}
	
	mutating func next() -> String? {
		guard characters.count > 0 else { return nil }
		var result = [Character]()
		var character: Character
		var inQuote = false
		while characters.count > 0 {
			character = characters.removeFirst()
			if character == "\"" && !inQuote {
				inQuote = true
				continue
			} else if character == "\"" && inQuote {
				inQuote = false
				return String(result)
			} else if character == " " && !inQuote {
				if result.count == 0 { continue }
				return String(result)
			}
			result.append(character)
		}
		if result.count == 0 { return nil }
		return String(result)
	}
	
}
