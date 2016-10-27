//
//  Post.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 20/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import Foundation

class Post {
    
    fileprivate let FavoritesKey = "FavoritePosts"
    
    var title: String
    var text: String
    var author: User
    var id: String?
    var modificationDate: Date?
    var image: String
    var latitude: Double
    var longitude: Double
    var published: Bool
    var readings: Int
    var publicationRequested: Bool
    
    var photo: UIImage?
    
    var hasLocation: Bool {
        get {
            return latitude != 0 && longitude != 0
        }
    }
    
    var postState: String {
        get {
            if published {
                return "Published"
            } else if publicationRequested {
                return "Pending"
            } else {
                return "Unpublished"
            }
        }
    }
    
    var canBeEdited: Bool {
        get {
            return !self.published && !self.publicationRequested
        }
    }
    
    init(record: AzureProvider.JsonRecord) {
        self.title = record["title"] as? String ?? ""
        self.text = record["text"] as? String ?? ""
        self.modificationDate = record["updatedAt"] as? Date
        self.id = record["id"] as? String
        self.image = record["image"] as? String ?? ""
        self.latitude = record["latitude"] as? Double ?? 0
        self.longitude = record["longitude"] as? Double ?? 0
        self.published = record["published"] as? Bool ?? false
        self.publicationRequested = record["publicationRequested"] as? Bool ?? false
        self.readings = record["readings"] as? Int ?? 0
        
        let authorId = record["author"] as? String ?? ""
        let authorName = record["author_name"] as? String ?? ""
        self.author = User(name: authorName, id: authorId)
        
        if self.image == "" {
            self.photo = UIImage(imageLiteralResourceName: "noImage.png")
        } else {
            if let localData = getFileFromAppBundle(name: self.image) {
                self.photo = UIImage(data: localData)
            } else {
                var requestFinished = false
                AzureProvider.instance.downloadBlob(from: "images", withName: self.image) { (error, data) in
                    if let data = data {
                        self.photo = UIImage(data: data)
                        saveFileToAppBundle(name: self.image, data: data)
                    }
                    
                    requestFinished = true
                }
                
                while !requestFinished {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
                }
            }
        }
    }
    
    func toRecord() -> AzureProvider.JsonRecord {
        var record:AzureProvider.JsonRecord = [:]
        record.updateValue(self.id!, forKey: "id")
        record.updateValue(self.title, forKey: "title")
        record.updateValue(self.text, forKey: "text")
        record.updateValue(self.author.id, forKey: "author")
        record.updateValue(self.author.name, forKey: "author_name")
        record.updateValue(self.image, forKey: "image")
        record.updateValue(self.latitude, forKey: "latitude")
        record.updateValue(self.longitude, forKey: "longitude")
        record.updateValue(self.readings, forKey: "readings")
        record.updateValue(self.publicationRequested, forKey: "publicationRequested")
        record.updateValue(self.published, forKey: "published")
        
        return record
    }
    
    func toIDRecord() -> AzureProvider.JsonRecord {
        var record:AzureProvider.JsonRecord = [:]
        record.updateValue(self.id!, forKey: "id")

        return record
    }
}

extension Post {
    
    var isFavorite: Bool {
        get {
            guard let postId = id else {
                return false
            }
            
            return getFavorites().contains(postId)
        }
    }
    
    func addToFavorites() {
        var favorites = getFavorites()
        favorites.append(self.id!)
        UserDefaults.standard.set(favorites, forKey: self.FavoritesKey)
    }
    
    private func getFavorites() -> [String] {
        return UserDefaults.standard.array(forKey: self.FavoritesKey) as? [String] ?? []
    }
}
