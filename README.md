# HashAccess-Swift
Once you register the files, you can always find them with their hash values.

You can simulate the act of like the part of Swarm of Ethereum or IPFS on your local storage.

## Usage - Test UI
With Hash
1. Drag and drop the file into the upper field.
2. You get the hash value.
3. Paste the hash and press enter.
4. The file path will be shown.

With Name
1. Choose "Name" from the popup.
2. Enter the name in the textfield of the center.
3. Drag and drop the file. Then the file is registered with the entered name.
4. Enter the name for the search
5. The file path will be shown.


## Usage - HashAccess

Copy the HashAccess.swift in this project to yours

```
// To register the files
hashAccess.register(urls:[URL]) { (result) -> (Void) in
  //You get a dictionary of [URL:String]
  //URL is the registered file
  //String is the hash value
}

// To retrieve all file paths for the hash value
hashAccess.get(hashString:hashString) { (result) -> (Void) in
  //You get an array of [URL]
}


// To register a file with a name
hashAccess.register(name:name,url:url) { (result) -> (Void) in
  //you get a string value of the hash
}

// To retrieve the file path for the name
hashAccess.get(name:name) { (result) -> (Void) in
  //You get a URL
}

```

## License
[MIT](https://choosealicense.com/licenses/mit/)

## Contact
[E-mail](tomo_dev@sockettv.org), [twitter](https://twitter.com/DevYamashita), [Facebook](https://www.facebook.com/TomohiroYamashitaApps/)
