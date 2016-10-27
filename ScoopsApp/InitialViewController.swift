//
//  InitialViewController.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 18/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    
    @IBAction func loginAsEditor(_ sender: AnyObject) {
        
        AzureProvider.instance.login(controller: self) { (error, userId) in
            if let _ = userId {
                let loadingVC = generateLoadingViewController(in: self, withText: "Getting user information...")
                self.present(loadingVC, animated: true) {
                    
                    AzureProvider.instance.callAPI(name: "facebookAPI", method: "GET", parameters: [:], completion: { (userError, userInfo) in
                        if let userInfo = userInfo {
                            let user = User(record: userInfo)
                            
                            let allPostsVC = PostsViewController(editor: nil)
                            allPostsVC.title = "Recent Posts"
                            
                            let myPostsVC = PostsViewController(editor: user)
                            myPostsVC.title = "My Posts"
                            
                            let tabVC = UITabBarController(nibName: nil, bundle: nil)
                            tabVC.setViewControllers([allPostsVC, myPostsVC], animated: true)
                            
                            let tabBarItem1: UITabBarItem = tabVC.tabBar.items![0]
                            tabBarItem1.image = UIImage(imageLiteralResourceName: "newspaper.png")
                            let tabBarItem2: UITabBarItem = tabVC.tabBar.items![1]
                            tabBarItem2.image = UIImage(imageLiteralResourceName: "inbox.png")
                            
                            let navVC = UINavigationController(rootViewController: tabVC)
                            
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                                self.present(navVC, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func loginAsReader(_ sender: AnyObject) {
        let postsVC = PostsViewController(editor: nil)
        postsVC.title = "Recent Posts"
        
        let navVC = UINavigationController(rootViewController: postsVC)
        present(navVC, animated: true, completion: nil)
    }
}
