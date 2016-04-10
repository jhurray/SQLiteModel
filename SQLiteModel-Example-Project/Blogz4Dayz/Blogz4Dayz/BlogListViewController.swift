//
//  BlogListViewController.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import UIKit

class BlogListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    var blogz: [BlogModel]? = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.title = "Blogs4Dayz"
        
        let composeButton = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "newBlog:")
        navigationItem.rightBarButtonItem = composeButton
        
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 24.0
        let width: CGFloat = view.bounds.size.width / 2  - 2 * spacing
        let ratio: CGFloat = 16.0 / 12.0
        layout.itemSize = CGSize.init(width: width, height: width * ratio)
        layout.scrollDirection = .Vertical
        layout.sectionInset = UIEdgeInsets.init(top: spacing, left: spacing, bottom: spacing, right: spacing)
        
        collectionView.registerClass(BlogListCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.frame = view.bounds
        collectionView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        view.addSubview(collectionView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadData()
    }
    
    func newBlog(sender: AnyObject?) {
        let controller = BlogComposeViewController()
        controller.blog = try! BlogModel.new([])
        controller.title = "New Blog"
        let navController = UINavigationController(rootViewController: controller)
        presentViewController(navController, animated: true, completion: nil)
    }
    
    func fetchBlogs() {
        self.blogz = try? BlogModel.fetchAll()
    }
    
    func reloadData() {
        self.fetchBlogs()
        self.collectionView.reloadData()
    }
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let controller = BlogComposeViewController()
        let blog = self.blogz![indexPath.row]
        controller.blog = blog
        controller.title = "Edit Blog"
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let count = self.blogz?.count else {
            return 0
        }
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! BlogListCell
        cell.backgroundColor = UIColor.whiteColor()
        if let blog = blogz?[indexPath.row] {
            cell.reloadWithBlogModel(blog)
        }
        return cell
    }
}
