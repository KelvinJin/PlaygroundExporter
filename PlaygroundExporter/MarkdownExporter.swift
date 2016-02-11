//
//  MarkdownExporter.swift
//  PlaygroundExporter
//
//  Created by Jin Wang on 11/02/2016.
//  Copyright © 2016 Uthoft. All rights reserved.
//

import Foundation
import AppKit

private let SupportedFileExtension = ["swift"]

extension String
{
    func trim() -> String
    {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

class MarkdownExporter: NSObject {
    static let sharedInstance = MarkdownExporter()
    
    // MARK: - Xcode Helpers.
    
    private var currentWindowController: NSWindowController? {
        return NSApp.keyWindow?.windowController
    }
    
    private var currentEditor: IDEEditor? {
        guard let workspaceController = self.currentWindowController as? IDEWorkspaceWindowController else { return nil }
        
        let editorArea = workspaceController.editorArea()
        let editorContext = editorArea.lastActiveEditorContext() as? IDEEditorContext
        return editorContext?.editor() as? IDEEditor
    }
    
    private var currentSourceCodeDocument: IDESourceCodeDocument? {
        if let currentEditor = self.currentEditor as? IDESourceCodeEditor {
            return currentEditor.sourceCodeDocument
        }
        
        if let currentEditor = self.currentEditor as? IDESourceCodeComparisonEditor {
            return currentEditor.primaryDocument as? IDESourceCodeDocument
        }
        
        return nil
    }
    
//    private let markdownCommentBlockRegex = "/\/\*:(\*(?!\/)|[^*])*\*\//g"
    
    private lazy var markdownCommentBlockRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "\\/\\*:(\\*(?!\\/)|[^*])*\\*\\/", options: [])
    }()
    
    // MARK: - Public Methods
    func exportCurrentSource(html: Bool = false) {
        guard let currentSourceCodeDocument = currentSourceCodeDocument else { return }
        
        let currentFile = currentSourceCodeDocument.filePath()
        // This file URL will be the url pointed to the actual .playground file.
        let fileURL = currentFile.fileURL
        let contentFileURL = fileURL.URLByAppendingPathComponent("Contents.swift")
        
        guard let fileExtension = contentFileURL.pathExtension where SupportedFileExtension.contains(fileExtension) else { return }
        
        guard let swiftString = try? String(contentsOfURL: contentFileURL, encoding: NSUTF8StringEncoding) else { return }
        
        let fileName = currentFile.fileName
        var finalString = processSourceCode(swiftString)
        var outputFileExtension = "md"
        
        if html {
            var options = MarkdownOptions()
            options.autoHyperlink = true
            options.emptyElementSuffix = ">"
            options.encodeProblemUrlCharacters = true
            options.linkEmails = false
            options.strictBoldItalic = true
            var markbird = Markdown(options: options)
            finalString = markbird.transform(finalString)
            
            outputFileExtension = "html"
        }
        
        guard let outputFileURL = contentFileURL.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("\(fileName).\(outputFileExtension)") else { return }
        
        // Finally we'll write the markdown string to a file.
        let _ = try? finalString.writeToURL(outputFileURL, atomically: false, encoding: NSUTF8StringEncoding)
    }
    
    private func processSourceCode(inputSource: String) -> String {
        let range = NSRange(location: 0, length: inputSource.characters.count)
        var outputString = ""
        var cursor = 0
        let nsString = inputSource as NSString
        
        // We'll loop over the string to find every markdown comment block.
        markdownCommentBlockRegex.enumerateMatchesInString(inputSource, options: [], range: range) { (result, flags, stop) -> Void in
            guard let result = result else { return }
            // Let's get the start index of the current match
            let resultRange = result.range
            let startIndex = resultRange.location
            
            // If we have some code snippet after the last comment block.
            if startIndex > cursor {
                let codeRange = NSRange(location: cursor, length: startIndex - cursor)
                let code = nsString.substringWithRange(codeRange)
                outputString +=
                "\n```swift\n\(code)\n```\n"
            }
            
            var comment = nsString.substringWithRange(resultRange) as NSString
            
            // Get rid of the /*:*/ part.
            comment = comment.substringFromIndex(3) as NSString
            comment = comment.substringToIndex(comment.length - 2)
            
            // Append current comment block.
            outputString += comment as String
            
            // Update the cursor.
            cursor = startIndex + resultRange.length
        }
        
        // We'll have to check the rest of the string to make sure the last bit is counted.
        let restCode = nsString.substringFromIndex(cursor).trim()
        if restCode.characters.count > 0 {
            outputString += "\n```swift\n\(restCode)\n```\n"
        }
        
        return outputString
    }
}
