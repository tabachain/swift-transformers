import Foundation
import Hub

/// A helper struct representing a pre-tokenized word
struct DebertaWord {
    let text: String
    let range: Range<String.Index>
    let hasLeadingSpace: Bool
}

/// A pure Swift implementation of the DeBERTa-v2 pre-tokenization logic.
/// Only implements the splitting logic required for GLiNER's input generation.
class DebertaV2Tokenizer: UnigramTokenizer {
    
    /// Splits text into words considering punctuation and whitespace, mimicking DeBERTa-v2 behavior.
    /// - Parameter text: The input text
    /// - Returns: An array of `DebertaWord`
    func tokenizeToWords(_ text: String) -> [DebertaWord] {
        var words: [DebertaWord] = []
        var currentToken = ""
        var currentTokenStartIndex = text.startIndex
        
        // Track the end of the last token to detect whitespace gaps
        // Initialize with default-start to handle leading space at the very beginning if any (though usually trimmed or start is 0)
        var lastTokenEndIndex = text.startIndex
        
        // Use UnicodeScalars to handle characters correctly
        // We need direct indexing into the original string to preserve Ranges
        
        let scalars = text.unicodeScalars
        var index = scalars.startIndex
        
        while index < scalars.endIndex {
            let scalar = scalars[index]
            let scalarStartStrIndex = String.Index(index, within: text)!
            
            // Check if it's whitespace
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                // If we have a current token accumulating, flush it
                if !currentToken.isEmpty {
                    // Calculate range for the token we just finished
                    let endStrIndex = scalarStartStrIndex
                    let range = currentTokenStartIndex..<endStrIndex
                    
                    let hasLeadingSpace = (currentTokenStartIndex > lastTokenEndIndex)
                    words.append(DebertaWord(text: currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
                    
                    currentToken = ""
                    lastTokenEndIndex = endStrIndex
                }
                
                // Advance past whitespace, updating lastTokenEndIndex
                // The whitespace itself is skipped, but serves as a gap
                // We need to advance index
                // Since this scalar is whitespace, we just discard it.
                // But we must update lastTokenEndIndex to *this* scalar's end so future checks see the gap?
                // Actually, if we skip it, the next token's start will be > lastTokenEndIndex.
                // Let's ensure lastTokenEndIndex tracks the end of *processed meaningful content*.
                // So we do NOT update lastTokenEndIndex here. We leave it at the end of the previous token.
                // The next token will start at `index + len`.
                // Wait. 
                // "Hello world"
                // Hello ends at 5. lastTokenEndIndex = 5.
                // space at 5.
                // world starts at 6.
                // 6 > 5 -> hasLeadingSpace = true.
                // Correct.
                
            } else if CharacterSet.alphanumerics.contains(scalar) {
                if currentToken.isEmpty {
                    currentTokenStartIndex = scalarStartStrIndex
                }
                currentToken.append(Character(scalar))
                
            } else {
                // Punctuation / Symbol
                // 1. Flush existing alphanum token
                if !currentToken.isEmpty {
                    let endStrIndex = scalarStartStrIndex
                    let range = currentTokenStartIndex..<endStrIndex
                    let hasLeadingSpace = (currentTokenStartIndex > lastTokenEndIndex)
                    words.append(DebertaWord(text: currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
                    
                    currentToken = ""
                    lastTokenEndIndex = endStrIndex
                }
                
                // 2. Emit the punctuation itself as a token
                let punctStr = String(Character(scalar))
                let punctEndIndex = text.index(after: scalarStartStrIndex)
                let range = scalarStartStrIndex..<punctEndIndex
                let hasLeadingSpace = (scalarStartStrIndex > lastTokenEndIndex)
                
                words.append(DebertaWord(text: punctStr, range: range, hasLeadingSpace: hasLeadingSpace))
                
                lastTokenEndIndex = punctEndIndex
            }
            
            index = scalars.index(after: index)
        }
        
        // Flush remaining token
        if !currentToken.isEmpty {
            // Find end of string index
            let endStrIndex = text.endIndex
            let range = currentTokenStartIndex..<endStrIndex
            let hasLeadingSpace = (currentTokenStartIndex > lastTokenEndIndex)
            words.append(DebertaWord(text: currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
        }
        
        return words
    }
}
