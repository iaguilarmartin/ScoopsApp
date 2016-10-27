//
//  User.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 27/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import Foundation

struct User {
    let name: String
    let id: String
    
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
    
    init(record: AzureProvider.JsonRecord?) {
        self.name = record?["name"] as? String ?? ""
        self.id = record?["id"] as? String ?? ""
    }
}
