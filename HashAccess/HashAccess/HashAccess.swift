//
//  HashAccess.swift
//  HashAccess
//
//  Created by Tom on 2021/01/21.
//


import Foundation
import CommonCrypto

class HashAccess:NSObject {
    
    var hashDictionary:[String:[Data]] = [:]
   
    
    override init () {
        //
    }
    
    
    func saveDefault() {
        let defaults = UserDefaults.standard
        defaults.set(hashDictionary, forKey:"HASH_DICTIONARY")
        defaults.synchronize()
    }
    
    func loadDefault() {
        let defaults = UserDefaults.standard
        defaults.synchronize()
        if let data = defaults.object(forKey: "HASH_DICTIONARY") as? [String:[Data]] {
            hashDictionary = data
        }
    }
    
    
    
    func register(fileURLs:[URL], completion: @escaping(([URL:String]) -> (Void))) {
        var resultHashes:[URL:String] = [:]
        for url in fileURLs {
            register(fileURL:url) { (result) -> (Void) in
                if let string = result {
                    resultHashes[url] = string
                }
            }
            print("droppedFile: \(url)")
        }
        print("register completed")
        completion(resultHashes)
    }
    
    
    func register(fileURL:URL?, completion: @escaping ((String?) -> (Void))) {
        
        var resultHash:String? = nil
        if fileURL == nil {
            completion(nil)
            return
        }
        loadDefault()
        var data:Data? = nil
        fileURL!.startAccessingSecurityScopedResource()
        do {
            data = try fileURL!.bookmarkData(options:NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys:nil, relativeTo:nil)
        } catch {
            print(error)
            completion(nil)
            return
        }
        
        resultHash = sha256(url:fileURL!)

        fileURL!.stopAccessingSecurityScopedResource()
        if let dat = data, let hash = resultHash {
            var files = [dat]
            if let exists = hashDictionary[hash] {
                var dataExists = false
                for existdata in exists {
                    if existdata == dat {
                        dataExists = true
                    }
                }
                if dataExists == false {
                    files += exists
                } else {
                    files = exists
                }
            }
            hashDictionary[hash] = files
            saveDefault()
        }
        completion(resultHash)
    }
    
    func get(hashString:String?, completion:@escaping(([URL]) -> (Void))) {
        
        var resultFiles:[URL] = []
        
        loadDefault()
        if let hash = hashString {
            var resultDatas:[Data] = []
            if let exists = hashDictionary[hash]  {
                resultDatas = exists
            }
            for data in resultDatas {
                do {
                    let url = try NSURL.init(resolvingBookmarkData: data, options:.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: nil) as URL
                    
                        resultFiles += [url]
                } catch let error as NSError {
                    print(error.description)
                }
            }
        }
        completion(resultFiles)
    }
    
    func sha256(url:URL) -> String? {
        do {
            let data = try Data(contentsOf: url, options:Data.ReadingOptions())
            var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = digestData.withUnsafeMutableBytes {digestBytes in
                data.withUnsafeBytes {messageBytes in
                    CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
                }
            }
            return digestData.base64EncodedString()
        } catch let error as NSError {
            print(error.description)
            return nil
        }
    }
}
