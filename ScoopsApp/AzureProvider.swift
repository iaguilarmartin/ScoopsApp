//
//  AzureProvider.swift
//  ScoopsApp
//
//  Created by Ivan Aguilar Martin on 20/10/16.
//  Copyright © 2016 Ivan Aguilar Martin. All rights reserved.
//

import Foundation

class AzureProvider {
    
    public typealias JsonRecord = Dictionary<AnyHashable, Any>
    
    typealias APIResult = (_ error: Error?, _ user: JsonRecord?) -> Void
    typealias LoginResult = (_ error: Error?, _ user: String?) -> Void
    typealias QueryResult = (_ error: Error?, _ records: [JsonRecord]?) -> Void
    typealias UpdateResult = (_ error: Error?, _ record: JsonRecord?) -> Void
    typealias DeleteResult = (_ error: Error?, _ id: String?) -> Void
    typealias StorageResult = (_ error: Error?, _ result: Bool) -> Void
    typealias DownloadResult = (_ error: Error?, _ result: Data?) -> Void
    
    static let instance = AzureProvider()
    var msClient: MSClient?
    var storageClient: AZSCloudBlobClient?
    
    private init() {
        do {
            msClient = MSClient(applicationURLString: "https://scoopsapp.azurewebsites.net")
            
            let credentials = AZSStorageCredentials(accountName: "scoopsappstorage",
                                                    accountKey: "A9bhVFmLsUGFPZlVKh9I/eAcMJMUO3JzUaK6NWP8igu0guXdOXuPNiSewsHkkot7iEWUnjL3ZzcZSCjTXKJC0w==")
            let account = try AZSCloudStorageAccount(credentials: credentials, useHttps: true)
            
            storageClient = account.getBlobClient()
            
        } catch let error {
            print(error)
        }
    }
    
    func login(controller: UIViewController, completion: @escaping LoginResult) {
        msClient?.login(withProvider: "facebook", controller: controller, animated: true, completion: { (user, error) in
            if let error = error {
                print("Error while doing login into Facebook: \(error)")
                completion(error, nil)
                return
            }
            
            completion(nil, user?.userId)
        })
    }
    
    func callAPI(name: String, method: String, parameters: JsonRecord, completion: @escaping APIResult) {
        msClient?.invokeAPI(name, body: nil, httpMethod: method, parameters: parameters, headers: nil, completion: { (result, response, error) in
            
            if let error = error {
                print("Error while calling API: \(error)")
                completion(error, nil)
                return
            }
            
            completion(error, result as? AzureProvider.JsonRecord)
        })
    }
    
    func query(table tableName: String,
                    queryString: String?,
                    orderField: String?,
                    ascending: Bool,
                    completion: @escaping QueryResult) {

        let table = msClient?.table(withName: tableName)
        var query: MSQuery?
        
        if let queryString = queryString {
            let predicate = NSPredicate(format: queryString)
            query = table?.query(with: predicate)
        } else {
            query = table?.query()
        }
        
        if let orderField = orderField {
            if ascending {
                query?.order(byAscending: orderField)
            } else {
                query?.order(byDescending: orderField)
            }
        }
        
        query?.read(completion: { (result, error) in
            if let error = error {
                print("Error while reading all records: \(error)")
                completion(error, nil)
                return
            }
            
            completion(nil, result?.items)
        })
    }
    
    func insert(record: JsonRecord, into tableName: String, completion: @escaping UpdateResult) {
        msClient?.table(withName: tableName).insert(record, completion: { (result, error) in
            if let error = error {
                print("Error while inserting record \(record): \(error)")
                completion(error, nil)
                return
            }
            
            completion(nil, result)
        })
    }
    
    func update(record: JsonRecord, into tableName: String, completion: @escaping UpdateResult) {
        msClient?.table(withName: tableName).update(record, completion: { (result, error) in
            if let error = error {
                print("Error while inserting record \(record): \(error)")
                completion(error, nil)
                return
            }
            
            completion(nil, result)
        })
    }
    
    func deleteRecord(id: String, from tableName: String, completion: @escaping DeleteResult) {
        msClient?.table(withName: tableName).delete(withId: id, completion: { (deletedId, error) in
            if let error = error {
                print("Error while deleting record with id \(id): \(error)")
                completion(error, nil)
                return
            } else {
                completion(nil, deletedId as? String)
            }
        })
    }
    
    func saveBlob(into containerName: String, withData data: Data, andName name: String, completion: @escaping StorageResult) {
        
        let blobContainer = self.storageClient?.containerReference(fromName: containerName.lowercased())
        blobContainer?.exists(completionHandler: { (error, containerExist) in
            if let error = error {
                print("Error while validating container with name \(containerName): \(error)")
                completion(error, false)
            }
            
            if containerExist {
                let myBlob = blobContainer?.blockBlobReference(fromName: name)
                myBlob?.upload(from: data, completionHandler: { (uploadError) in
                    if uploadError != nil {
                        print("Error uploading blob: \(uploadError)")
                        completion(uploadError, false)
                    }
                    
                    completion(nil, true)
                })
            } else {
                print("The container with name \(containerName) does not exist")
                completion(nil, false)
            }
        })
    }
    
    func deleteBlob(from containerName: String, withName name: String, completion: @escaping StorageResult) {
        
        let blobContainer = self.storageClient?.containerReference(fromName: containerName.lowercased())
        blobContainer?.exists(completionHandler: { (error, containerExist) in
            if let error = error {
                print("Error while validating container with name \(containerName): \(error)")
                completion(error, false)
            }
            
            if containerExist {
                let myBlob = blobContainer?.blockBlobReference(fromName: name)
                myBlob?.delete(completionHandler: { (deleteError) in
                    if deleteError != nil {
                        print("Error deleting blob: \(deleteError)")
                        completion(deleteError, false)
                    }
                    
                    completion(nil, true)
                })
            } else {
                print("The container with name \(containerName) does not exist")
                completion(nil, false)
            }
        })
    }

    func downloadBlob(from containerName: String, withName name: String, completion: @escaping DownloadResult) {
        
        let blobContainer = self.storageClient?.containerReference(fromName: containerName.lowercased())
        blobContainer?.exists(completionHandler: { (error, containerExist) in
            if let error = error {
                print("Error while validating container with name \(containerName): \(error)")
                completion(error, nil)
            }
            
            if containerExist {
                let myBlob = blobContainer?.blockBlobReference(fromName: name)
                myBlob?.downloadToData(completionHandler: { (donwloadError, blobData) in
                    if donwloadError != nil {
                        print("Error downloading blob: \(donwloadError)")
                        completion(donwloadError, nil)
                    }
                    
                    completion(nil, blobData)
                })
            } else {
                print("The container with name \(containerName) does not exist")
                completion(nil, nil)
            }
        })
    }
}
