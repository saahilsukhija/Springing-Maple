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
                        folders.append(DropboxFolder(id: folder.id, name: folder.name, path: folder.pathLower ?? "\(folder.name)"))
                        print(folder.pathLower ?? "no path")
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
    
    func uploadImagesToFolder(images: [UIImage], folderPath: String, namingConvention: DropboxNamingConvention, property: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let client = client else {
            completion(false, NSError(domain: "DropboxClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated"]))
            return
        }
        
        var filesCommitInfo = [URL : Files.CommitInfo]()
        
        for (index, image) in images.enumerated() {
            
            guard let imageData = ImageCompressor.compressImageToTargetSize(image: image, targetSize: CGFloat(Constants.MAX_IMAGE_SIZE)) else { print("unable to compress"); return }
            let fileName: String
            let imagecount = UserDefaults.standard.getUploadedImagesCount(property: property)
            switch namingConvention {
            case .propertyName:
                fileName = "\(property)_\(Date().toLongMonthDayYearFormat())_\(imagecount+1) - \(User.shared.getUserFirstName()).jpg"
            default:
                fileName = "\(Date().toLongMonthDayYearFormat())_\(imagecount+1) - \(User.shared.getUserFirstName()).jpg"
            }
            UserDefaults.standard.updateUploadedImagesCount(property: property)
            let filePath = "\(folderPath)/\(fileName)"
            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: tempUrl)
                filesCommitInfo[tempUrl] = Files.CommitInfo(path: filePath, mode: .overwrite)
            } catch {
                print("Failed to write image data to temporary file for image \(imagecount + 1)")
            }
            
        }
        
        client.files.batchUploadFiles(
            fileUrlsToCommitInfo: filesCommitInfo,
            responseBlock: { (uploadResults: [URL: Files.UploadSessionFinishBatchResultEntry]?,
                              finishBatchRequestError: BatchUploadError?,
                              fileUrlsToRequestErrors: [URL: BatchUploadError]) -> Void in
                
                if let uploadResults = uploadResults {
                    for (clientSideFileUrl, result) in uploadResults {
                        switch result {
                        case .success(let metadata):
                            let dropboxFilePath = metadata.pathDisplay!
                            //print("Upload \(clientSideFileUrl.absoluteString) to \(dropboxFilePath) succeeded")
                        case .failure(let error):
                            print("Upload \(clientSideFileUrl.absoluteString) failed: \(error)")
                        }
                    }
                    completion(true, nil)
                } else if let finishBatchRequestError = finishBatchRequestError {
                    print("Error uploading files: possible error on Dropbox server: \(finishBatchRequestError)")
                    completion(false, finishBatchRequestError as? Error)
                } else if fileUrlsToRequestErrors.count > 0 {
                    print("Error uploading files: \(fileUrlsToRequestErrors)")
                    if let firstError = fileUrlsToRequestErrors.values.first {
                        completion(false, firstError as? Error)
                    } else {
                        completion(false, NSError(domain: "DropboxClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during batch upload"]))
                    }
                }
            }
        )
    }
    
    func uploadVideosToFolder(videos: [NSData], folderPath: String, namingConvention: DropboxNamingConvention, property: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            completion(false, NSError(domain: "DropboxClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated"]))
            return
        }
        
        var filesCommitInfo = [URL: Files.CommitInfo]()
        
        for (index, videoData) in videos.enumerated() {
            let fileName: String
            switch namingConvention {
            case .propertyName:
                fileName = "\(property)_\(Date().toLongMonthDayYearFormat())_\(index+1).mov"
            }
            
            let filePath = "\(folderPath)/\(fileName)"
            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            
            do {
                try videoData.write(to: tempUrl)
                filesCommitInfo[tempUrl] = Files.CommitInfo(path: filePath, mode: .overwrite)
            } catch {
                print("Failed to write video data to temporary file for video \(index + 1)")
            }
        }
        
        client.files.batchUploadFiles(
            fileUrlsToCommitInfo: filesCommitInfo,
            responseBlock: { (uploadResults: [URL: Files.UploadSessionFinishBatchResultEntry]?,
                              finishBatchRequestError: BatchUploadError?,
                              fileUrlsToRequestErrors: [URL: BatchUploadError]) -> Void in
                
                var successful = 0
                var failed = 0
                if let uploadResults = uploadResults {
                    for (clientSideFileUrl, result) in uploadResults {
                        switch result {
                        case .success(let metadata):
                            let dropboxFilePath = metadata.pathDisplay!
                            print("Upload \(clientSideFileUrl.absoluteString) to \(dropboxFilePath) succeeded")
                            successful += 1
                        case .failure(let error):
                            print("Upload \(clientSideFileUrl.absoluteString) failed: \(error)")
                            failed += 1
                        }
                    }
                    if failed == 0 {
                        completion(true, nil)
                    } else {
                        completion(false, NSError(domain: "Failed uploading \(failed) images", code: 0))
                    }
                } else if let finishBatchRequestError = finishBatchRequestError {
                    print("Error uploading files: possible error on Dropbox server: \(finishBatchRequestError)")
                    completion(false, finishBatchRequestError as? Error)
                } else if fileUrlsToRequestErrors.count > 0 {
                    print("Error uploading files: \(fileUrlsToRequestErrors)")
                    if let firstError = fileUrlsToRequestErrors.values.first {
                        completion(false, firstError as? Error)
                    } else {
                        completion(false, NSError(domain: "DropboxClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during batch upload"]))
                    }
                }
            }
        )
    }
}

struct DropboxFolder: Codable {
    
    var id: String!
    var name: String!
    var path: String!
    
}

enum DropboxNamingConvention {
    
    case propertyName
}
