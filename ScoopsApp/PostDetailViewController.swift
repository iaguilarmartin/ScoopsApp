//
//  PostDetailViewController.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 19/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import UIKit
import CoreLocation

class PostDetailViewController: UIViewController {

    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var tvTitle: UITextView!
    @IBOutlet weak var tvContent: UITextView!
    @IBOutlet weak var editToolbar: UIToolbar!
    @IBOutlet weak var tvReadings: UILabel!
    @IBOutlet weak var labelReadings: UILabel!
    @IBOutlet weak var btnLike: UIButton!
    
    var model: Post
    var delegate: PostDetailViewControllerDelegate?
    var imageUUID: String?
    let isNewPost: Bool
    let isEditor: Bool
    
    var locationManager: CLLocationManager?
    
    init(post: Post, newPost: Bool, isEditor: Bool) {
        model = post
        isNewPost = newPost
        self.isEditor = isEditor
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isTranslucent = false
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(setPhoto))
        photo.isUserInteractionEnabled = true
        photo.addGestureRecognizer(gesture)
        
        putBorderOn(textView: tvTitle)
        putBorderOn(textView: tvContent)
        
        if isNewPost {
            // Requesting current user location
            let locationStatus = CLLocationManager.authorizationStatus()
            if (locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse || locationStatus == .notDetermined) && CLLocationManager.locationServicesEnabled() {
                
                self.locationManager = CLLocationManager()
                self.locationManager?.requestWhenInUseAuthorization()
                self.locationManager?.delegate = self
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                
                self.locationManager?.startUpdatingLocation()
            }
        } else if !isEditor {
            model.readings = model.readings + 1
            self.tvReadings.text = String(model.readings)
            self.btnLike.isHidden = false
            self.labelReadings.isHidden = false
            
            if model.isFavorite {
                self.btnLike.isEnabled = false
            }
            
            AzureProvider.instance.callAPI(name: "scoopsAPI", method: "POST", parameters: ["post_id": model.id!]) { (error, result) in
                
                if error == nil {
                    print("Reading added to the post")
                }
            }
        }
        
        self.tvTitle.text = model.title
        self.tvContent.text = model.text
        self.imageUUID = model.image
        self.photo.image = model.photo
        
        updateUI()
    }
    
    @IBAction func likePost(_ sender: AnyObject) {
        self.btnLike.isEnabled = false
        self.model.addToFavorites()
    }
    
    @IBAction func savePost(_ sender: AnyObject) {
        self.model.text = tvContent.text
        self.model.title = tvTitle.text
        
        let loadingVC = generateLoadingViewController(in: self, withText: "Saving post...")
        present(loadingVC, animated: true) {
            
            if self.imageUUID != self.model.image {
                if self.model.image != "" {
                    AzureProvider.instance.deleteBlob(from: "images", withName: self.model.image, completion: { (error, deleted) in
                        
                        
                        if self.imageUUID != "" {
                            AzureProvider.instance.saveBlob(into: "images", withData: UIImageJPEGRepresentation(self.photo.image!, 1.0)!, andName: self.imageUUID!, completion: { (error, saved) in
                                
                                self.savePostInAzure()
                            })
                        } else {
                            self.savePostInAzure()
                        }
                    })
                } else if self.imageUUID != "" {
                    AzureProvider.instance.saveBlob(into: "images", withData: UIImageJPEGRepresentation(self.photo.image!, 1.0)!, andName: self.imageUUID!, completion: { (error, saved) in
                        
                        self.savePostInAzure()
                    })
                }
                
                self.model.image = self.imageUUID!
                
            } else {
                self.savePostInAzure()
            }
        }
    }
    
    @IBAction func deletePost(_ sender: AnyObject) {
        let loadingVC = generateLoadingViewController(in: self, withText: "Deleting post...")
        present(loadingVC, animated: true) {
            
            if self.model.image != "" {
                AzureProvider.instance.deleteBlob(from: "images", withName: self.model.image, completion: { (error, deleted) in
                })
            }
            
            AzureProvider.instance.deleteRecord(id: self.model.id!, from: "Post", completion: { (error, id) in
    
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                    
                    if error == nil {
                        self.delegate?.postDataModified(post: self.model)
                        let _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            })
        }
    }
    
    func updateUI() {
    
        if isEditor {
            var buttonText = model.postState
            if buttonText == "Unpublished" {
                buttonText = "Publish"
            }
            
            let btn = UIBarButtonItem(title: buttonText, style: .plain, target: self, action: #selector(publishPost))
            btn.isEnabled = model.canBeEdited
            self.navigationItem.rightBarButtonItem = btn
        }
        
        editToolbar.isHidden = !isEditor || !model.canBeEdited
    }
    
    func putBorderOn(textView: UITextView) {
        textView.layer.cornerRadius = 5
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1
    }
    
    func savePostInAzure() {
        AzureProvider.instance.update(record: self.model.toRecord(), into: "Post") { (error, record) in
            
            if let record = record {
                self.model = Post(record: record)
                self.delegate?.postDataModified(post: self.model)
            }
            
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
                self.updateUI()
            }
        }

    }
    
    func publishPost() {
        if tvTitle.text != "" && tvContent.text != "" {
            self.model.publicationRequested = true
            self.savePost(self)
        } else {
            let alertVC = UIAlertController(title: "Warning", message: "Post title and content can not be empty", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            }))
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    func setPhoto() {
        
        if isEditor && model.canBeEdited {
            // If device camera and photolibrary are available then
            // an ActionSheet is displayed so the user can choose the source
            // of the image
            if UIImagePickerController.isSourceTypeAvailable(.camera) && UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                let actionSheet = UIAlertController(title: "Select photo source", message: nil, preferredStyle: .actionSheet)
                let actionCamera = UIAlertAction(title: "New photo", style: .default) { (action: UIAlertAction) in
                    self.launchPicker(sourceType: .camera)
                }
                let actionLibrary = UIAlertAction(title: "Photo from library", style: .default) { (action: UIAlertAction) in
                    self.launchPicker(sourceType: .photoLibrary)
                }
                actionSheet.addAction(actionCamera)
                actionSheet.addAction(actionLibrary)
                
                present(actionSheet, animated: true, completion: nil)
                
            } else if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.launchPicker(sourceType: .camera)
            } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.launchPicker(sourceType: .photoLibrary)
            }
        }
    }
    
    // Function to display either camera or photo library
    func launchPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    // Function to stop receiving locations
    func stopRequestingLocations() {
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.delegate = nil
        self.locationManager = nil
    }
}

//MARK: - UIImagePickerControllerDelegate
extension PostDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // If user does not select any photo then image is replaced
        // in CoreData for the default image
        self.imageUUID = ""
        self.photo.image = UIImage(imageLiteralResourceName: "noImage.png")
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // If user selects a photo then model is updated with the new image
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            DispatchQueue.global(qos: .userInitiated).async {
                let screenBounds = UIScreen.main.bounds
                if let resizedImg = resizeImage(image: img, newWidth: screenBounds.size.width) {
                    DispatchQueue.main.async {
                        self.photo.image = resizedImg
                        self.imageUUID = UUID().uuidString
                    }
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CLLocationManagerDelegate
extension PostDetailViewController: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Storing current user location into the post
        if !self.model.hasLocation {
            if let lastLocation = locations.last {
                self.model.longitude = lastLocation.coordinate.longitude
                self.model.latitude = lastLocation.coordinate.latitude
                self.stopRequestingLocations()
            }
        } else {
            self.stopRequestingLocations()
        }
    }
}

protocol PostDetailViewControllerDelegate {
    func postDataModified(post: Post)
}
