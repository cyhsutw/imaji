import Foundation

class EmojiInfo {
    var keywords = [String]()
    var char: String?

    init(keywords: [String], char: String) {
        self.keywords = keywords
        self.char = char
    }
}

class EmojiOracle {
    static let sharedOracle = EmojiOracle()

    fileprivate lazy var textEmojiMapping: [String : String] = {
        if let path = Bundle.main.path(forResource: "TextEmojiMapping", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String : String] {
            return dict
        }
        return [String : String]()
    }()
    
    
    init() {
        // init the dict
        let _ = textEmojiMapping
    }
    
    func toEmoji(_ text: String) -> String? {
        return textEmojiMapping[text]
    }
}
