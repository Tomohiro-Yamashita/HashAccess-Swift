# HashAccess-Swift
Once you register the files, you can always find them with their hash values.

You can simulate the act of like the part of Swarm of Ethereum or IPFS on your local storage.

## Usage - Test UI
1. Drag and drop the file.
2. You get the hash value.
3. Paste the hash and press enter.
4. Then the file path will be shown.

## Usage - HashAccess

Copy the HashAccess.swift in this project to yours

```
// To register the files
hashAccess.register(fileURLs:[URL]) { (result) -> (Void) in
  //You get a dictionary of [URL:String]
  //URL is the registered file
  //String is the hash value
}

// To retrieve all file paths for the hash value
hashAccess.get(hashString:hashString) { (result) -> (Void) in
  //You get an array of [URL]
}
```

## License
[MIT](https://choosealicense.com/licenses/mit/)

## Contact
[E-mail](tomo_dev@sockettv.org), [twitter](https://twitter.com/DevYamashita), [Facebook](https://www.facebook.com/TomohiroYamashitaApps/)
