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
    
    
    func registerFiles(urls:[URL]) {
            
        hashAccess.register(fileURLs:urls) { (result) -> (Void) in
            for (url,hash) in result {
                print("url: \(url)   hash: \(hash)")
            }
            self.testUI.setHashResults(result)
        }
    }
    
    
    func findWithHash(hash hashString:String) {
        print(hashString)
        hashAccess.get(hashString:hashString) { (result) -> (Void) in
            for path in result {
                print(path)
            }
            self.testUI.setURLResults(result)
        }
    }
}

