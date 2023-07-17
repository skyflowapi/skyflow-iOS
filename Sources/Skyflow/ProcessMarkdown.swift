import Foundation

func processMarkdownFiles(at directoryPath: String, fileNamesToDelete: [String]) {
    let fileManager = FileManager.default
    let directoryURL = URL(fileURLWithPath: directoryPath)
    
    // Check if directory exists
    if !fileManager.fileExists(atPath: directoryPath) {
        print("Directory does not exist: \(directoryPath)")
        return
    }
    
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

        for fileName in fileNamesToDelete {
            let filesToDelete = fileURLs.filter { $0.pathExtension == "md" && $0.lastPathComponent == fileName }
            
            for fileURL in filesToDelete {
                try fileManager.removeItem(at: fileURL)
            }
        }

        let filesToProcess = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

        for fileURL in filesToProcess {
            convertParamsToTable(at: fileURL)
        }

    } catch {
        print("Error while processing files: \(error.localizedDescription)")
    }
}

// Function to read markdown file, convert params to table, and update markdown
func convertParamsToTable(at fileURL: URL) {
    guard var markdown = try? String(contentsOf: fileURL) else {
        print("Failed to read markdown file: \(fileURL.path)")
        return
    }

    markdown = extractHeadings(from: markdown)

    // Array to store the updated lines of markdown
    var updatedMarkdownLines: [String] = []
    
    // Flag to indicate if a parameter list is being processed
    var isProcessingParameters = false
    
    // Array to store the lines of the current parameter list
    var parameterList: [String] = []

    var emptyLineCount = 0

    updatedMarkdownLines.append("{% env enable=\"goSdkRef\" %}")
    updatedMarkdownLines.append("")
    
    // Iterate over each line in the markdown
    for line in markdown.components(separatedBy: .newlines) {
        let startsWithParameters = line.range(
            of: #"^#{2,4}\s*Parameters"#,
            options: .regularExpression
        ) != nil
        if startsWithParameters { 
            // Start of a new parameter list
            isProcessingParameters = true
        } else if isProcessingParameters && emptyLineCount == 2{
            // End of the current parameter list

            // Convert parameters list to a table
            updatedMarkdownLines.append("")
            let parameterTable = convertToTable(parameterList)
            updatedMarkdownLines.append(contentsOf: parameterTable)
            updatedMarkdownLines.append("")
            
            // Reset the parameter list
            parameterList = []
            isProcessingParameters = false
            emptyLineCount = 0
        }
        
        // Append the line to the updated markdown
        if isProcessingParameters && !startsWithParameters{
            if(line.isEmpty)
            {
                emptyLineCount = emptyLineCount + 1
            }
            parameterList.append(line)
        } else {
            updatedMarkdownLines.append(line)
        }
    }

    if isProcessingParameters && emptyLineCount == 2{
        // For parameter list at the end of file

        // Convert parameters list to a table
        updatedMarkdownLines.append("")
        let parameterTable = convertToTable(parameterList)

        updatedMarkdownLines.append(contentsOf: parameterTable)
        updatedMarkdownLines.append("")
        
        // Reset the parameter list
        parameterList = []
        isProcessingParameters = false
        emptyLineCount = 0
    }
    
    updatedMarkdownLines.append("{% /env %}")
    updatedMarkdownLines.append("")
    // Join the updated markdown lines
    let updatedMarkdown = updatedMarkdownLines.joined(separator: "\n")
    
    // Write the updated markdown back to the file
    do {
        try updatedMarkdown.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Updated markdown written to: \(fileURL.path)")
    } catch {
        print("Error writing updated markdown: \(error)")
    }
}

// Function to convert parameters to a table
func convertToTable(_ parameters: [String]) -> [String] {
    var table: [String] = []
    table.append("| Name | Description |")
    table.append("| ---- | ----------- |")
    for line in parameters {
        if(!line.isEmpty)
        {
            let arr = line.split(separator: ":")
            let name = arr[0].split(separator: "-")[1].trimmingCharacters(in: .whitespaces)
            let description = arr[1].trimmingCharacters(in: .whitespaces)
            table.append("| \(name) | \(description) |")
        }
    }
    return table
}

func extractHeadings(from markdown: String) -> String {
    var modifiedMarkdown = ""
    
    let lines = markdown.components(separatedBy: .newlines)
    var isInsideCodeBlock = false
    
    for line in lines {
        if line.starts(with: "```") {
            isInsideCodeBlock.toggle()
        }
        
        if isInsideCodeBlock || !line.starts(with: "###") {
            modifiedMarkdown += line + "\n"
        } else if let methodName = extractMethodName(from: line) {
            modifiedMarkdown += "### \(methodName)\n"
        }
    }
    
    return modifiedMarkdown
}

func extractMethodName(from line: String) -> String? {
    let components = line.components(separatedBy: " ")
    guard components.count > 1 else {
        return nil
    }
    
    let methodName = components[1]
    let sanitizedMethodName = sanitizeMethodName(methodName)
    return sanitizedMethodName
}

func sanitizeMethodName(_ methodName: String) -> String {
    let pattern = "\\([^()]*\\)"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: methodName.utf16.count)
    
    let sanitizedMethodName = regex.stringByReplacingMatches(
        in: methodName,
        options: [],
        range: range,
        withTemplate: "()"
    )
    
    return sanitizedMethodName
}
// Usage example
let path = "docs/markdown"
let filesToDelete = ["_Footer.md", "_Sidebar.md", "ContainerOptions.md", "ContainerProtocol.md", "Callback.md", "TokenProvider.md", "SkyflowValidationError.md", "Label.md", "UILabel.md", "ValidationRule.md", "SkyflowLabelView.md", "Home.md", "RevealOptions.md"]

processMarkdownFiles(at: path, fileNamesToDelete: filesToDelete)