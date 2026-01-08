//
//  DebertaV2Tokenizer.swift
//
//
//
//

import Foundation
import Hub

/// A helper struct representing a pre-tokenized word
public struct DebertaWord {
    public let text: String
    public let range: Range<String.Index>
    public let hasLeadingSpace: Bool
    
    public init(text: String, range: Range<String.Index>, hasLeadingSpace: Bool) {
        self.text = text
        self.range = range
        self.hasLeadingSpace = hasLeadingSpace
    }
}

/// A pure Swift implementation of the DeBERTa-v2 pre-tokenization logic.
/// Only implements the splitting logic required for GLiNER's input generation.
public class DebertaV2Tokenizer: UnigramTokenizer {
    
    /// Splits text into words considering punctuation and whitespace, mimicking DeBERTa-v2 behavior.
    /// - Parameter text: The input text
    /// - Returns: An array of `DebertaWord`
    public func tokenizeToWords(_ text: String) -> [DebertaWord] {
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
                    let isFirst = (words.isEmpty)
                    let shouldPrepend = hasLeadingSpace || isFirst
                    let prefix = shouldPrepend ? "\u{2581}" : ""
                    
                    words.append(DebertaWord(text: prefix + currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
                    
                    currentToken = ""
                    lastTokenEndIndex = endStrIndex
                }
                
                // Advance past whitespace
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
                    let isFirst = (words.isEmpty)
                    let shouldPrepend = hasLeadingSpace || isFirst
                    let prefix = shouldPrepend ? "\u{2581}" : ""
                    
                    words.append(DebertaWord(text: prefix + currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
                    
                    currentToken = ""
                    lastTokenEndIndex = endStrIndex
                }
                
                // 2. Emit the punctuation itself as a token
                let punctStr = String(Character(scalar))
                let punctEndIndex = text.index(after: scalarStartStrIndex)
                let range = scalarStartStrIndex..<punctEndIndex
                let hasLeadingSpace = (scalarStartStrIndex > lastTokenEndIndex)
                let isFirst = (words.isEmpty)
                let shouldPrepend = hasLeadingSpace || isFirst
                let prefix = shouldPrepend ? "\u{2581}" : ""
                
                words.append(DebertaWord(text: prefix + punctStr, range: range, hasLeadingSpace: hasLeadingSpace))
                
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
            let isFirst = (words.isEmpty)
            let shouldPrepend = hasLeadingSpace || isFirst
            let prefix = shouldPrepend ? "\u{2581}" : ""
            
            words.append(DebertaWord(text: prefix + currentToken, range: range, hasLeadingSpace: hasLeadingSpace))
        }
        
        return words
    }
}
