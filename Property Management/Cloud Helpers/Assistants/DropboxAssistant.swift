//
//  DropboxAssistant.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/12/24.
//

import Foundation
import SwiftyDropbox

class DropboxAssistant {
    
    static var shared = DropboxAssistant()
    
    var client: DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    var isConnected: Bool {
        return DropboxClientsManager.authorizedClient != nil
    }
    
    init() {
        
    }
    
    func getAllFolders(at path: String = "", completion: @escaping(([DropboxFolder]) -> Void)) {
        guard let client = client else { completion([]); return }
        client.files.listFolder(path: path).response { response, error in
            if let result = response {
                var folders: [DropboxFolder] = []
                
                for entry in result.entries {
                    if let folder = entry as? Files.FolderMetadata {
                        folders.append(DropboxFolder(id: folder.id, name: folder.name))
                    }
                }
                completion(folders)
                // Present folders to the user (e.g., in a UITableView)
                //self.presentFolders(folders: folders)
            } else if let error = error {
                print("Error listing Dropbox folders: \(error)")
                completion([])
            }
        }
        
    }
    
    func folderContains(_ name: String, at path: String = "", completion: @escaping(Bool) -> Void) {
        guard let client = client else { completion(false); return }
        client.files.listFolder(path: path).response { response, error in
            if let result = response {
                for entry in result.entries {
                    if let folder = entry as? Files.FolderMetadata, folder.name == name {
                        completion(true)
                        return
                    }
                }
                completion(false)
            } else if let error = error {
                print("Error listing Dropbox folders: \(error)")
                completion(false)
            }
        }
    }
}

//MARK: UPLOAD
extension DropboxAssistant {
    func createFolder(at path: String, named folderName: String, completion: @escaping (Bool, Error?) -> Void) {
        let fullPath = "\(path)/\(folderName)"
        guard let client = client else { completion(false, NSError(domain: "DropboxClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated"])); return }
        client.files.createFolderV2(path: fullPath).response { response, error in
            if let _ = response {
                completion(true, nil)
            } else if let error = error {
                print("Error creating Dropbox folder: \(error)")
                completion(false, error)
            }
        }
    }
    
    func uploadImagesToFolder(images: [UIImage], folderPath: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let client = client else { completion(false, NSError(domain: "DropboxClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated"])); return }
        
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?
        
        for (index, image) in images.enumerated() {
            if let imageData = image.pngData() {
                let fileName = "\(Date().toLongMonthDayYearFormat())_\(index+1).png"
                let filePath = "\(folderPath)/\(fileName)"
                
                dispatchGroup.enter()
                client.files.upload(path: filePath, input: imageData)
                    .response { response, error in
                        if let error = error {
                            uploadError = error
                        }
                        dispatchGroup.leave()
                    }
                    .progress { progressData in
                        //print("Upload progress for \(fileName): \(progressData.fractionCompleted)")
                    }
            } else {
                print("Failed to get PNG data for image \(index + 1)")
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
}


struct DropboxFolder: Codable {
    
    var id: String!
    var name: String!
    
}
