//
//  FirebaseStorage.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/21/24.
//

import UIKit
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import FirebaseStorage

class FirebaseStorage {
    
    //Singleton Instance
    static let shared: FirebaseStorage = {
        let instance = FirebaseStorage()
        // setup code
        return instance
    }()
    
    var db: StorageReference!
    private var disableUpdates: Bool!
    
    init() {
        db = Storage.storage().reference()
        disableUpdates = false
    }
    
    func uploadWorkReciept(_ work: RegisteredWork, image: UIImage, completion: @escaping((Bool) -> Void)) throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirebaseError("User is not logged in")
        }
        guard let image = image.jpegData(compressionQuality: 0.7) else {
            throw FirebaseError("Error creating image data")
        }
        db.child(work.imagePath).putData(image, metadata: StorageMetadata(dictionary: ["id" : work.internalID])) { metadata, error in
                if let error = error {
                    print(error.localizedDescription)
                    completion(false)
                } else {
                    print("success uploading data \(metadata?.dictionaryRepresentation() ?? [:])")
                    print("uploaded work: \(work)")
                    completion(true)
                }
            }
            
        
        
    }
    
    struct FirebaseError: LocalizedError {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
        
        var errorDescription: String? {
            description
        }
        
    }
}
