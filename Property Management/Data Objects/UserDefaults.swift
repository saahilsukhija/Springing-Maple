//
//  UserDefaults.swift
//  CongressionalAppBiking
//
//  Created by Saahil Sukhija on 7/9/21.
//

import UIKit

public extension UserDefaults {
    
    /// Set Codable object into UserDefaults
    ///
    /// - Parameters:
    ///   - object: Codable Object
    ///   - forKey: Key string
    /// - Throws: UserDefaults Error
    func set<T: Codable>(object: T, forKey: String) throws {
        
        let jsonData = try JSONEncoder().encode(object)
        
        set(jsonData, forKey: forKey)
    }
    
    /// Get Codable object into UserDefaults
    ///
    /// - Parameters:
    ///   - object: Codable Object
    ///   - forKey: Key string
    /// - Throws: UserDefaults Error
    func get<T: Codable>(objectType: T.Type, forKey: String) throws -> T? {
        
        guard let result = value(forKey: forKey) as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(objectType, from: result)
    }
    
    func isKeyPresent(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func removeAll(except keys: [String] = ["user_settings"]) {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if !keys.contains(key) {
                defaults.removeObject(forKey: key)
                print("deleted \(key)")
            }
        }
    }
    
    func saveImages(_ images: [UIImage], forKey key: String) throws {
        let data = coreDataObjectFromImages(images: images)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func getImages(forKey key: String) throws -> [UIImage] {
        let data = UserDefaults.standard.data(forKey: key)
        return imagesFromCoreData(object: data) ?? []
    }
    
    private func coreDataObjectFromImages(images: [UIImage]) -> Data? {
        let dataArray = NSMutableArray()
        
        for img in images {
            if let data = img.pngData() {
                dataArray.add(data)
            }
        }
        
        return try? NSKeyedArchiver.archivedData(withRootObject: dataArray, requiringSecureCoding: true)
    }

    private func imagesFromCoreData(object: Data?) -> [UIImage]? {
        var retVal = [UIImage]()

        guard let object = object else { return nil }
        if let dataArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: object) {
            for data in dataArray {
                if let data = data as? Data, let image = UIImage(data: data) {
                    retVal.append(image)
                }
            }
        }
        
        return retVal
    }
    
    
    func updateUploadedImagesCount(property: String, _ date: Date = Date()) {
        print("UPDATING " + date.toMonthDate())
        let key = "imagecount_\(property)_\(date.toMonthDate())"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }
    
    func getUploadedImagesCount(property: String, _ date: Date = Date()) -> Int {
        print("GETTING " + date.toMonthDate())
        let key = "imagecount_\(property)_\(date.toMonthDate())"
        let current = UserDefaults.standard.integer(forKey: key)
        return current
    }
    
//    func saveVideos(_ videos: [(NSData, UIImage)], forKey key: String) throws {
//        var videoData: [Data] = []
//        var thumbnailData: [UIImage] = []
//        
//        for v in videos {
//            videoData.append(v.0 as Data)
//            thumbnailData.append(v.1)
//        }
//        
//        UserDefaults.standard.set(videoData, forKey: key + "_videos")
//        try? saveImages(thumbnailData, forKey: key + "_thumbnails")
//    }
//    
//    func getVideos(forKey key: String) throws -> [(NSData, UIImage)] {
//        let videoData = UserDefaults.standard.array(forKey: key + "_videos") as? [Data] ?? []
//        let thumbnailData = try? getImages(forKey: key + "_thumbnails")
//        
//        var out: [(NSData, UIImage)] = []
//        
//        for (i, v) in videoData.enumerated() {
//            out.append((NSData(data: v), thumbnailData?[i] ?? .actions))
//        }
//        return out
//        
//    }
}

