//
//  TestUI.swift
//  HashAccess
//
//  Created by Tom on 2021/01/26.
//

import Foundation
import AppKit

class TestUI: NSView, NSTextFieldDelegate {
    
    var controller:ViewController? = nil
    let dropView:DropView
    let chooseFileButton = NSButton()
    let resultView = NSTextField()
    let copyResultButton = NSButton()
    let findHashField = NSTextField()
    let findHashButton = NSButton()
    
    
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
        resultView.isEnabled = false

        findHashField.delegate = self
        findHashField.placeholderString = "Paste the hash here"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func configure(_ cont:ViewController) {
        self.controller = cont
        cont.view.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateLayout), name: NSView.frameDidChangeNotification, object: cont.view)
        updateLayout()
    }
    
    @objc func updateLayout() {
        if let cont = controller {
            frame = cont.view.bounds
            dropView.frame.size.width = frame.size.width - 100
            dropView.frame.size.height = frame.size.height * 0.3 - 36
            dropView.frame.origin.x = 15
            dropView.frame.origin.y = frame.size.height - dropView.frame.size.height - 15
            
            resultView.frame.size.width = frame.size.width - 100
            resultView.frame.size.height = frame.size.height * 0.7 - 36
            resultView.frame.origin.x = 15
            resultView.frame.origin.y = 15
            
            findHashField.frame.size.width = frame.size.width - 100
            findHashField.frame.size.height = 36
            findHashField.frame.origin.x = 15
            findHashField.frame.origin.y = frame.size.height - dropView.frame.size.height - 18 - findHashField.frame.size.height
        }
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
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            startFindWithHash()
            
            return true
        }
        return false
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
                controller!.hashAccess.get(hashString:hash) { (result) -> (Void) in
                    if result.count > 0 {
                        urls += [result[0]]
                    }
                }
            }
            setURLResults(urls)
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
        findHashField.stringValue = ""
        
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
        findHashField.stringValue = ""
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
            
            String("Drag and drop the file here").draw(in: NSOffsetRect(dirtyRect, 0, 1), withAttributes: textFontAttributes)
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
            if let view = baseView, let contr = view.controller {
                contr.registerFiles(urls: urls)
            }
            
            return true
        }
        
        return false
    }

    
}
