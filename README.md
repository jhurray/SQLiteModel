# SQLiteModel
The easiest way to persist data in Swift

A developer friendly Object Relational Model for [SQLite3](http://www.sqlite.org/), wrapped over [SQLite.swift](https://github.com/stephencelis/SQLite.swift)

```swift
struct Person: SQLiteModel {
    
    var localID: SQLiteModelID = -1
    
    static let Name = Expression<String>("name")
    static let Age = Expression<Int>("age")
    static let BFF = Relationship<Person?>("best_friend")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Name)
        tableBuilder.column(Age, defaultValue: 0)
        tableBuilder.relationship(BFF, mappedFrom: self)
    }
}

try Person.createTable()
    
let jack = try Person.new([
       Person.Age <- 10,
       Person.Name <- "Jack"
   ])
    
let jill = try Person.new([
   Person.Age <- 12,
   Person.Name <- "Jill"
   ])

// Set age
// same as jack.set(Person.Age, 11)
jack <| Person.Age |> 11
// Get age
// same as jack.get(Person.Age)
let age = jack => Person.Age

// Set Best Friend
// same as jack.set(Person.BFF, jill)
jack <| Person.BFF |> jill

let people = try Person.fetchAll()

```

## Features
* Easy set up 👌
* Database functionality 💾 (*Create / Drop Table, Insert, Update, Delete, Fetch*)
* Relationships 👫 (*One to One, Many to One, Many to Many*)
* Schema alterations 🛠
* Sync and Async execution 🏁🚀
* Thread safety 👮☢️
* Easy to read and write syntax 🙌
* Verbose error handling and logging ❗️🖨
* [Thoroughly documented](https://github.com/jhurray/SQLiteModel/wiki) 🤓🗂
* Well tested 📉📊📈
* iOS, OSX, tvOS support 📱💻📺
* [Example projects](https://github.com/jhurray/SQLiteModel-Example-Project)
* Pure Swift 💞😻

## Installation

SQLiteModel requires Swift 2 (and Xcode 7) or greater.

###CocoaPods
If you are unfamiliar with [CocoaPods](https://cocoapods.org/) please read these guides before proceeding:

* [Getting Started](https://guides.cocoapods.org/using/getting-started.html)    
* [Using CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

Add the following to your Podfile:

```ruby
use_frameworks!

pod 'SQLiteModel'
```

###Carthage
Not Yet supported

###Manual

To install SQLite.swift as an Xcode sub-project:

 1. Drag the **SQLite.xcodeproj** file into your own project.
    ([Submodule][], clone, or [download][] the project first.)

 2. In your target’s **General** tab, click the **+** button under **Linked
    Frameworks and Libraries**.

 3. Select the appropriate **SQLite.framework** for your platform.

 4. **Add**.

[Submodule]: http://git-scm.com/book/en/Git-Tools-Submodules
[download]: https://github.com/stephencelis/SQLite.swift/archive/master.zip

##Documentation

The [wiki](https://github.com/jhurray/SQLiteModel/wiki) for this repo contains extensive documentation.

##Why SQLiteModel
There are a lot of good data storage solutions out there, **Realm** and **CoreData** being the first 2 that come to mind. My biggest issue with these solutions is that they make your models be classes instead of structs.

Apple's documentation lists a couple conditions where if true, a struct is probably a better choice than a class [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/ClassesAndStructures.html). I find the following condition especially relevant:

>The structure’s primary purpose is to encapsulate a few relatively simple data values.

That sounds like a database table to me. Ideally if we are trying to model a database table, we should use structs, which **SQLiteModel** supports.

That being said, structs arent always the answer. **SQLiteModel** also supports using classes, but as of now they have to be `final`.

There are also a lot of wrappers over SQLite that exist, but aren't object relational models. **SQLite.swift** and **FMDB** are my 2 personal favorites. These are very powerful and flexible, but they take a while to set up the right way as they require a lot of boilerplate code. 

With **SQLiteModel**, the boilerplate code is already written. Obviously you are sacrificing flexibility for ease of use, but for most data storage needs this is acceptable (IMO).

####TL;DR    
* **SQLiteModel** supports structs which are probably better than classes for modeling database tables and rows.
* **SQLiteModel** provides extensive functionality with minimum boilerplate code.

##Example Projects
There a couple good examples of how to use SQLiteModel

###Playground
I have included a playground in this repo that you can use to fool around with the syntax and features of SQLiteModel. Make sure you open `SQLiteModel.xcworkspace` since I am using cocoapods. Here you can find `SQLiteModel.playground` under the SQLiteModel project

###Example Applications
I created a repo with example applications for **iOS**, **TVOS**, AND **OSX** that can be found [here](https://github.com/jhurray/SQLiteModel-Example-Project). These projects all use CocoaPods, so make sure you open the `.xcworkspace` to get them running. 

The iOS example I provided is the best and most thorough example of how to use SQLiteModel. The app is a blog platform that allows you create, delete, and save blog posts. You can also add images to blogs using relationships, and view all images on another tab. 

##Moving Forward    
- [ ] Carthage support
- [ ] More scalar queries  
- [ ] Reading in pre-existing databases
- [ ] More table alteration options  
- [ ] Performance improvements for relationships

##Contact Info
Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com?subject=SQLiteModel). I'd love to hear your thoughts on this, or see examples where this has been used.

You can also hit me up on twitter [@JeffHurray](https://twitter.com/JeffHurray).

##Contributing
If you want to add functionality feel free to open an issue and/or create a pull request. I am always open to improving my work.

##Shoutout
Big thank you to [Stephen Celis](https://github.com/stephencelis) for writing `SQLite.swift` which I think is one of the best Swift open source libraries that exists today. SQLiteModel would not have been possible without his work.

##License
SQLiteModel is available under the MIT license. See the LICENSE file for more information.
