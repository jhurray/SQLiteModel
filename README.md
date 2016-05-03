<img src="./Resources/SQLiteModel_logo.png"></img>
A developer friendly Object Relational Model for [SQLite3](http://www.sqlite.org/), wrapped over [SQLite.swift](https://github.com/stephencelis/SQLite.swift)

```swift
struct Person: SQLiteModel {
    
    // Required by SQLiteModel protocol
    var localID: SQLiteModelID = -1
    
    static let Name = Expression<String>("name")
    static let Age = Expression<Int>("age")
    static let BFF = Relationship<Person?>("best_friend")
    
    // Required by SQLiteModel protocol
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Name)
        tableBuilder.column(Age, defaultValue: 0)
        tableBuilder.relationship(BFF, mappedFrom: self)
    }
}

```

```swift
    
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
* [Example projects](https://github.com/jhurray/SQLiteModel-Example-Project)🔍
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
[Carthage][] is a simple, decentralized dependency manager for Cocoa. To
install SQLite.swift with Carthage:

 1. Make sure Carthage is [installed][Carthage Installation].

 2. Update your Cartfile to include the following:

    ```
    github "jhurray/SQLiteModel" ~> 0.3.2
    ```

 3. Run `carthage update` and [add the appropriate framework][Carthage Usage].


[Carthage]: https://github.com/Carthage/Carthage
[Carthage Installation]: https://github.com/Carthage/Carthage#installing-carthage
[Carthage Usage]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application

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

####ORM's
There are a lot of good data storage solutions out there, **Realm** and **CoreData** being the most popular. The biggest issue with these solutions is that they force your models be reference types (classes) instead of value types (structs).

Apple's documentation lists a couple conditions where if true, a struct is probably a better choice than a class [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/ClassesAndStructures.html). The following condition is especially relevant:

>The structure’s primary purpose is to encapsulate a few relatively simple data values.

Sounds like a database row fits that description. Ideally if one are trying to model a database row, one should use structs, which **SQLiteModel** supports.

That being said, structs arent always the answer. **SQLiteModel** also supports using classes, but as of now they have to be `final`.


####SQLite Wrappers
There are also a lot of wrappers over SQLite that exist, but aren't object relational models. **SQLite.swift** and **FMDB** are 2 great libraries that serve this functionality. These are very powerful and flexible, but they take a while to set up the right way as they require a lot of boilerplate code. 

With **SQLiteModel**, the boilerplate code is already written. Obviously you are sacrificing flexibility for ease of use, but for most data storage needs this is acceptable (IMO).

####TL;DR    
* **SQLiteModel** supports structs which are probably better than classes for modeling database tables and rows.
* **SQLiteModel** provides extensive functionality with minimum boilerplate code.

##Example Projects
There a couple good examples of how to use SQLiteModel

###Playground
Included in this repo is a playground that you can use to fool around with the syntax and features of SQLiteModel. Make sure you open `SQLiteModel.xcworkspace` since this project uses cocoapods. Here one can find `SQLiteModel.playground` under the SQLiteModel project

###Example Applications
There is a repo with example applications for **iOS**, **TVOS**, AND **OSX** that can be found [here](https://github.com/jhurray/SQLiteModel-Example-Project). These projects all use CocoaPods, so make sure to open the `.xcworkspace` to get them running. 

The iOS example that is provided is the best and most thorough example of how to use SQLiteModel. The app is a blog platform that allows users create, delete, and save blog posts. Users can also add images to blogs using relationships, and view all images on another tab. 

##Moving Forward    
- [x] ~~Carthage support~~
- [x] ~~Complex relationship queries~~     
- [x] ~~Reading in pre-existing databases~~  
- [ ] More scalar queries    
- [ ] More table alteration options  
- [ ] Improved data pipeline between db and value types
- [ ] Performance improvements for relationships

##Contact Info
Feel free to email me at [jhurray33@gmail.com](mailto:jhurray33@gmail.com?subject=SQLiteModel). I'd love to hear your thoughts on this, or see examples where this has been used.

You can also hit me up on twitter [@JeffHurray](https://twitter.com/JeffHurray).

##Contributing
If you want to add functionality please open an issue and/or create a pull request.

##Shoutout
Big thank you to [Stephen Celis](https://github.com/stephencelis) for writing `SQLite.swift` which (IMHO) is one of the best Swift open source libraries that exists today.

##License
SQLiteModel is available under the MIT license. See the LICENSE file for more information.
