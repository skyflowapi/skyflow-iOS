import Foundation

func deleteMarkdownFiles(at path: String, fileNamesToDelete: [String]) {
    let fileManager = FileManager.default
    
    do {
        let fileURLs = try fileManager.contentsOfDirectory(atPath: path)
        
        for fileName in fileNamesToDelete {
            let fileToDelete = fileURLs.filter { $0.pathExtension == "md" && $0.lastPathComponent == fileName }
            
            for fileURL in fileToDelete {
                try fileManager.removeItem(at: fileURL)
                print("Deleted file: \(fileURL.lastPathComponent)")
            }
        }
    } catch {
        print("Error while deleting files: \(error.localizedDescription)")
    }
}

// Usage example
let path = "docs/markdown"
let filesToDelete = ["Callback.md", "_Footer.md", "_Sidebar.md"]

deleteMarkdownFiles(at: path, fileNamesToDelete: filesToDelete)
