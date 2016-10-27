//
//  PostsViewController.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 18/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController {

    var editor: User?
    var segmentedControl: UISegmentedControl
    var addPostBtn: UIBarButtonItem?
    
    var updatedNeeded = true
    
    var model: [Post] = []
    
    // MARK: - Initializers
    init(editor: User?) {
        self.editor = editor
        
        segmentedControl = UISegmentedControl(items: ["Published", "Unpublished"])
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if editor != nil {
            addPostBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPost))
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadTableContent()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "postCell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        }

        let post = self.model[indexPath.row]
        cell?.textLabel?.text = post.title
        
        if editor != nil {
            cell?.detailTextLabel?.text = post.postState
        } else {
            cell?.detailTextLabel?.text = post.author.name
        }

        cell?.imageView?.image = post.photo
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = self.model[indexPath.row]
        let detailVC = PostDetailViewController(post: post, newPost: false, isEditor: editor != nil)
        detailVC.delegate = self
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension PostsViewController {
    func addPost() {
        let loadingVC = generateLoadingViewController(in: self, withText: "Creating post...")
        present(loadingVC, animated: true) {
            AzureProvider.instance.insert(record: [:], into: "Post") { (error, record) in
                if let record = record {
                    let post = Post(record: record)
                    post.author = self.editor!
                    
                    let detailVC = PostDetailViewController(post: post, newPost: true, isEditor: true)
                    
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                        self.refreshUpdateNeeded()
                        self.navigationController?.pushViewController(detailVC, animated: true)
                    }
                }
            }
        }
    }
    
    func categoryChanged() {
        self.updatedNeeded = true
        loadTableContent()
        self.tableView.reloadData()
    }
    
    func refreshUpdateNeeded() {
        if let tabVC = self.tabBarController {
            for vc in tabVC.viewControllers! {
                let postVC = vc as! PostsViewController
                postVC.updatedNeeded = true
            }
        } else {
            self.updatedNeeded = true
        }
    }
    
    func loadTableContent() {
        var query: String
        
        if editor != nil {
            self.tabBarController?.navigationItem.titleView = self.segmentedControl
            self.tabBarController?.navigationItem.rightBarButtonItem = addPostBtn
            
            query = "author = '\(editor!.id)'"
            
            if segmentedControl.selectedSegmentIndex == 0 {
                query.append(" and (published = true or publicationRequested = true)")
            } else {
                query.append(" and (published = false and publicationRequested = false)")
            }
        } else {
            self.tabBarController?.navigationItem.titleView = nil
            self.tabBarController?.navigationItem.rightBarButtonItem = nil
            self.tabBarController?.navigationItem.title = "Recent Posts"
            query = "published = true"
        }
        
        if self.updatedNeeded {
            DispatchQueue.main.async {
                let loadingVC = generateLoadingViewController(in: self, withText: "Loading posts...")
                self.present(loadingVC, animated: true) {
                    AzureProvider.instance.query(table: "Post", queryString: query, orderField: "updatedAt", ascending: false) { (error, records) in
                        
                        var posts: [Post] = []
                        
                        if let records = records {
                            for record in records {
                                let post = Post(record: record)
                                posts.append(post)
                            }
                        }
                        
                        self.model = posts
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.updatedNeeded = false
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }

    }
}

extension PostsViewController: PostDetailViewControllerDelegate {
    func postDataModified(post: Post) {
        refreshUpdateNeeded()
    }
}
