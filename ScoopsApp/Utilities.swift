//
//  Utilities.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 20/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import Foundation

func generateLoadingViewController(in controller: UIViewController, withText text: String) -> UIViewController {
    
    let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
    alert.view.tintColor = UIColor.black
    
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 10, y: 5, width: 50, height: 50))
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
    loadingIndicator.startAnimating();
    
    alert.view.addSubview(loadingIndicator)
    
    return alert
}

// Function to reduce image size in orther to consume less system memory
func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func saveFileToAppBundle(name: String, data: Data) {
    let appCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    let localFilePath = URL(fileURLWithPath: appCachePath, isDirectory: true).appendingPathComponent(name)
    try? data.write(to: localFilePath, options: [])
}

func getFileFromAppBundle(name: String) -> Data? {
    let appCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    let localFilePath = URL(fileURLWithPath: appCachePath, isDirectory: true).appendingPathComponent(name)
    return try? Data(contentsOf: localFilePath)
}
