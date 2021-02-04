//
//  ViewController.swift
//  HashAccess
//
//  Created by Tom on 2021/01/20.
//

import Cocoa

class ViewController: NSViewController {

    
    let hashAccess = HashAccess()
    let testUI = TestUI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(testUI)
        testUI.configure(self)
    }
    
    
    
    
    //MARK: Examples of usage
    
    func registerFiles(urls:[URL]) {
        hashAccess.register(urls:urls) { (result) -> (Void) in
            for (url,hash) in result {
                print("url: \(url)   hash: \(hash)")
            }
            self.testUI.setHashResults(result)
            self.testUI.findHashField.stringValue = ""
        }
    }
    
    func registerFileWithName(url:URL, name:String) {
        self.hashAccess.register(name:name,url:url) { (result) -> (Void) in
            if result != nil {
                self.testUI.setResult(string: "\(url.lastPathComponent) is added as \(name)")
            }
        }
    }
    
    func findWithHash(hash hashString:String) {
        print(hashString)
        hashAccess.get(hash:hashString) { (result) -> (Void) in
            for path in result {
                print(path)
            }
            self.testUI.setURLResults(result)
        }
    }
    
    func findWithName(name:String) {
        hashAccess.get(name:name) { (result) -> (Void) in
            for path in result {
                print(path)
            }
            self.testUI.setURLResults(result)
        }
    }
}

