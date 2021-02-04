//
//  TestUI.swift
//  HashAccess
//
//  Created by Tom on 2021/01/26.
//

import Foundation
import AppKit


class TestUI: NSView,NSTextFieldDelegate {
    
    var controller:ViewController? = nil
    let dropView:DropView
    let chooseFileButton = NSButton()
    let resultView = NSTextField()
    let copyResultButton = NSButton()
    let findHashField = NSTextField()
    let findHashButton = NSButton()
    let hashOrName = NSPopUpButton()
    
    override init(frame frameRect:NSRect) {
        let dropFrame = frameRect
        self.dropView = DropView(frame:dropFrame)
        super.init(frame:frameRect)
        dropView.baseView = self
        frame = frameRect
        
        let minFrame = NSView(frame:CGRect(x: 0,y: 0,width: 500,height: 300))
        addSubview(minFrame)
        addSubview(dropView)
        addSubview(chooseFileButton)
        addSubview(resultView)
        addSubview(copyResultButton)
        addSubview(findHashField)
        addSubview(findHashButton)
        addSubview(hashOrName)
        resultView.isEnabled = false
        hashOrName.action = #selector(self.hashOrNameChanged)
        findHashButton.title = "Find"
        findHashButton.action = #selector(self.findAction)

        findHashField.delegate = self
        
        
        ["Hash", "Name"].forEach(hashOrName.addItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func configure(_ cont:ViewController) {
        self.controller = cont
        cont.view.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateLayout), name: NSView.frameDidChangeNotification, object: cont.view)
        loadDefault()
        hashOrNameChanged()
        updateLayout()
    }
    
    @objc func updateLayout() {
        if let cont = controller {
            frame = cont.view.bounds
            dropView.frame.size.width = frame.size.width - 100
            dropView.frame.size.height = frame.size.height * 0.3 - 36
            dropView.frame.origin.x = 15
            dropView.frame.origin.y = frame.size.height - dropView.frame.size.height - 15
            
            resultView.frame.size.width = frame.size.width - 15
            resultView.frame.size.height = frame.size.height * 0.7 - 36
            resultView.frame.origin.x = 15
            resultView.frame.origin.y = 15
            
            hashOrName.frame.size.width = 80
            hashOrName.frame.size.height = 36
            hashOrName.frame.origin.x = 15
            hashOrName.frame.origin.y = frame.size.height - dropView.frame.size.height - 18 - hashOrName.frame.size.height
            
            findHashField.frame.size.width = frame.size.width - hashOrName.frame.size.width - 100
            findHashField.frame.size.height = 36
            findHashField.frame.origin.x = 15 + hashOrName.frame.size.width
            findHashField.frame.origin.y = hashOrName.frame.origin.y
            
            findHashButton.frame.size.width = 80
            findHashButton.frame.size.height = 36
            findHashButton.frame.origin.x = findHashField.frame.size.width + findHashField.frame.origin.x
            findHashButton.frame.origin.y = hashOrName.frame.origin.y
        }
    }
    
    func saveDefault() {
        let defaults = UserDefaults.standard
        defaults.set(hashOrName.indexOfSelectedItem, forKey:"hashOrName")
        defaults.synchronize()
    }
    
    func loadDefault() {
        let defaults = UserDefaults.standard
        defaults.synchronize()
        hashOrName.selectItem(at:defaults.integer(forKey: "hashOrName"))
    }
    
    func chooseFolder() -> URL? {
        let dialog = NSOpenPanel()
        
        dialog.title = "Choose Folder"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = true
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                return result
            }
        }
        return nil
    }
    
    @objc func hashOrNameChanged() {
        saveDefault()
        if hashOrName.indexOfSelectedItem == 0 {
            findHashField.placeholderString = "Paste hash for searching"
        } else {
            findHashField.placeholderString = "Name for registering file or searching"
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            findAction()
            return true
        }
        return false
    }
    
    @objc func findAction() {
        if hashOrName.indexOfSelectedItem == 0 {
            startFindWithHash()
        } else {
            startFindWithName()
        }
    }
    
    func showTheFile(_ url:URL) {
        NSWorkspace.shared.selectFile(url.path ,
            inFileViewerRootedAtPath:"")
    }
    
    func dragged(urls:[URL]) {
        
        if controller == nil {
            return
        }
        if hashOrName.indexOfSelectedItem == 0 {
            controller!.registerFiles(urls:urls)
        } else if urls.count == 1 {
            let name = findHashField.stringValue
            if name != "" {
                let url = urls[0]
                if controller!.hashAccess.exists(name:name) {
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.messageText = "\(name) already exists. Do you want to update with the new file?"
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Cancel")
                    alert.beginSheetModal(for: controller!.view.window!) { (result) -> (Void) in
                        if result == .alertFirstButtonReturn {
                            self.controller!.hashAccess.register(name:name,url:url) { (result) -> (Void) in
                                if result != nil {
                                    self.setResult(string: "\(name) is updated with \(url.lastPathComponent)")
                                }
                            }
                        }
                    }
                } else {
                    controller!.registerFileWithName(url:url, name:name)
                }
            }
        }
    }
    
    
    func startFindWithHash() {
        
        resultView.isEnabled = false
        
        var hashes = [String]()
        for string in findHashField.stringValue.components(separatedBy:"\n") {
            hashes += string.components(separatedBy:",")
        }
        
        if hashes.count == 1 {
            controller!.findWithHash(hash:hashes[0])
        } else if hashes.count > 1 {
            var urls = [URL]()
            for hash in hashes {
                controller!.hashAccess.get(hash:hash) { (result) -> (Void) in
                    if result.count > 0 {
                        urls += [result[0]]
                    }
                }
            }
            setURLResults(urls)
        }
    }
    
    func startFindWithName() {
        let name = findHashField.stringValue
        if name != "" {
            controller!.findWithName(name:name)
        }
    }
    
    func setHashResults(_ result:[URL:String]) {
        var hashes = ""
        var urls = ""
        for (url,hash) in result {
            hashes += hash + "\n"
            urls += url.path + "\n"
        }
        if result.count > 0 {
            resultView.isEnabled = true
        }
        resultView.stringValue = hashes
        //findHashField.stringValue = ""
        
    }
    
    func setURLResults(_ result:[URL]) {
        var string = ""
        for url in result {
            string += url.path + "\n"
        }
        
        if result.count > 0 {
            resultView.isEnabled = true
        }
        resultView.stringValue = string
        //findHashField.stringValue = ""
        if result.count == 1 {
            showTheFile(result[0])
        }
    }
    
    func setResult(string:String) {
        resultView.stringValue = string
        resultView.isEnabled = true
    }
}




class DropView: NSView {
    
    var baseView:TestUI? = nil
    
    let acceptableTypes: [NSPasteboard.PasteboardType] = [.fileURL]
    var isDragging = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isDragging {
            NSColor.selectedControlColor.set()
        } else {
            NSColor.lightGray.set()
        }
        let path = NSBezierPath(rect: bounds)
        path.fill()
        
        if let actualFont = NSFont(name: "Helvetica Bold", size: 14.0) {
            let textFontAttributes = [
                NSAttributedString.Key.font: actualFont,
                NSAttributedString.Key.foregroundColor: NSColor.darkGray,
                NSAttributedString.Key.paragraphStyle: NSMutableParagraphStyle.default.mutableCopy(),
            ]
            
            String("Drag and drop the file to register").draw(in: NSOffsetRect(dirtyRect, 0, 1), withAttributes: textFontAttributes)
        }
    }
    override init(frame frameRect:NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes(acceptableTypes)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        var allow = false
        let pasteBoard = draggingInfo.draggingPasteboard
        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: nil) {
            
            
            allow = true
        }
        return allow
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isDragging = allow
        return allow ? NSDragOperation.copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragging = false
    }
    
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        
        isDragging = false
        let pasteBoard = draggingInfo.draggingPasteboard
        
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           urls.count > 0 {
            if let view = baseView {
                view.dragged(urls: expandDirectoryContents(urls))
            }
            
            return true
        }
        
        return false
    }
    
    func expandDirectoryContents(_ urls:[URL]) -> [URL] {
        
        return urls
        
        
        /*
        // The permissions will be lost

        var result = [URL]()
        for url in urls {
            
            url.startAccessingSecurityScopedResource()
            
            if let urlEnum = FileManager.default.enumerator(at: url.resolvingSymlinksInPath(), includingPropertiesForKeys: nil) {
                for case let url as URL in urlEnum {
                    result += [url]
                }
            }
            url.stopAccessingSecurityScopedResource()
        }
        return result + urls
        */
    }
    
}
