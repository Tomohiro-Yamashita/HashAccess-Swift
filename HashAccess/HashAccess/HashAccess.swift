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
    let nameAccess = NameAccess()
   
    
    override init () {
        super.init()
        loadDefault()
    }
    
    
    func hashDictionaryPath() -> URL {
        return defaultArchivePath(name:"HashDictionary")
    }
    
    func saveDefault() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: hashDictionary, requiringSecureCoding: false)
            try data.write(to:hashDictionaryPath())
        } catch {
            print("Couldn't write file")
        }
    }
    
    func loadDefault() {
        do {
            let data = try Data(contentsOf: hashDictionaryPath(), options:Data.ReadingOptions())
            if let loaded = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String:[Data]] {
                hashDictionary = loaded
            }
        } catch {
            print("Couldn't read file.")
        }
    }
    
    
    func register(urls fileURLs:[URL], completion: @escaping(([URL:String]) -> (Void))) {
        var resultHashes:[URL:String] = [:]
        for url in fileURLs {
            register(url:url) { (result) -> (Void) in
                if let string = result {
                    resultHashes[url] = string
                }
            }
            print("droppedFile: \(url)")
        }
        print("register completed")
        completion(resultHashes)
    }
    
    
    func register(url fileURL:URL, completion: @escaping ((String?) -> (Void))) {
        
        var resultHash:String? = nil
        var data:Data? = nil
        fileURL.startAccessingSecurityScopedResource()
        do {
            data = try fileURL.bookmarkData(options:NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys:nil, relativeTo:nil)
        } catch {
            print(error)
            completion(nil)
            return
        }
        
        resultHash = sha256(url:fileURL)

        fileURL.stopAccessingSecurityScopedResource()
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
    
    func register(name:String, url fileURL:URL, completion: @escaping ((String?) -> (Void))) {
        var resultHash:String? = nil
        register(url:fileURL) { (result) -> (Void) in
            if let hash = result {
                if self.nameAccess.get(name) != hash {
                    if self.nameAccess.register(name:name, hash:hash) {
                        resultHash = hash
                    }
                }
            }
        }
        completion(resultHash)
    }
    
    func exists(name:String) -> Bool {
        return nameAccess.exists(name)
    }
    
    
    
    func get(hash:String, completion:@escaping(([URL]) -> (Void))) {
        
        var resultFiles:[URL] = []
        
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
        completion(resultFiles)
    }
    
    func get(name:String, completion:@escaping(([URL]) -> (Void))) {
        var resultURLs = [URL]()
        if let hash = nameAccess.get(name) {
            self.get(hash:hash)  { (result) -> (Void) in
                resultURLs = result
            }
        }
        completion(resultURLs)
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










class NameAccess:NSObject {
    
    var nameDictionary:[String:[Date:String]] = [:]
    
    override init () {
        super.init()
        self.loadDefault()
        print(nameDictionaryPath())
    }
    
    func nameDictionaryPath() -> URL {
        return defaultArchivePath(name:"NameDictionary")
    }
    
    func saveDefault() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: nameDictionary, requiringSecureCoding: false)
            try data.write(to:nameDictionaryPath())
        } catch {
            print("Couldn't write file")
        }
    }
    
    func loadDefault() {
        do {
            let data = try Data(contentsOf: nameDictionaryPath(), options:Data.ReadingOptions())
            if let loaded = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String:[Date:String]] {
                nameDictionary = loaded
            }
        } catch {
            print("Couldn't read file.")
        }
    }
    
    
    func exists(_ name:String) -> Bool {
        if self.nameDictionary[name] != nil {
            return true
        }
        return false
    }
    
    func  register(name:String, hash:String) -> Bool {
        let update = exists(name)
        var success = false
        if update {
            success = self.update(name:name, hash:hash)
        } else {
            success = self.new(name:name, hash:hash)
        }
        return success
    }
    
    func new(name:String, hash:String) -> Bool {
        if exists(name) == false {
            let version = [Date():hash]
            nameDictionary[name] = version
            
            saveDefault()
            return true
        }
        return false
    }
    
    func update(name:String, hash:String) -> Bool {
        if let version = self.nameDictionary[name] {
            var newVersion = version
            newVersion[Date()] = hash
            nameDictionary[name] = newVersion
            
            saveDefault()
            return true
        }
        return false
    }
    
    func getAllVersions(_ name:String) -> [Date:String] {
        if let dic = nameDictionary[name] {
            return dic
        }
        return [:]
    }
    
    func get(_ name:String) -> String? {
        let versions = getAllVersions(name)
        if let latest = versions.max(by: { a, b in a.key < b.key }) {
            return latest.value
        }
        return nil
    }
    
}

func defaultArchivePath(name:String) -> URL {
    return FileManager.default.urls(for:.applicationSupportDirectory,
                                    in:.userDomainMask )[0].appendingPathComponent(name)
}
