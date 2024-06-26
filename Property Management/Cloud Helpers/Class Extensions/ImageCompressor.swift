//
//  ImageCompressor.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/26/24.
//

import UIKit
import Photos

struct ImageCompressor {
    static func compress(image: UIImage, maxByte: Int,
                         completion: @escaping (UIImage?) -> ()) {
        //        DispatchQueue.global(qos: .userInitiated).async {
        //            guard let currentImageSize = image.jpegData(compressionQuality: 1.0)?.count else {
        //                return completion(nil)
        //            }
        //
        //            var iterationImage: UIImage? = image
        //            var iterationImageSize = currentImageSize
        //            var iterationCompression: CGFloat = 1.0
        //
        //            while iterationImageSize > maxByte && iterationCompression > 0.01 {
        //                let percentageDecrease = getPercentageToDecreaseTo(forDataCount: iterationImageSize)
        //
        //                let canvasSize = CGSize(width: image.size.width * iterationCompression,
        //                                        height: image.size.height * iterationCompression)
        //                UIGraphicsBeginImageContextWithOptions(canvasSize, false, image.scale)
        //                defer { UIGraphicsEndImageContext() }
        //                image.draw(in: CGRect(origin: .zero, size: canvasSize))
        //                iterationImage = UIGraphicsGetImageFromCurrentImageContext()
        //
        //                guard let newImageSize = iterationImage?.jpegData(compressionQuality: 1.0)?.count else {
        //                    return completion(nil)
        //                }
        //                iterationImageSize = newImageSize
        //                iterationCompression -= percentageDecrease
        //            }
        //            completion(iterationImage)
        //        }
        completion(image)
    }
    
    //returns jpeg data
    static func compressImageToTargetSize(image: UIImage, targetSize: CGFloat) -> Data? {
        let targetSizeBytes = targetSize
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        guard imageData != nil else { return nil }
        
        while imageData!.count > Int(targetSizeBytes) && compression > 0.01 {
            compression -= 0.01
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    private static func getPercentageToDecreaseTo(forDataCount dataCount: Int) -> CGFloat {
        switch dataCount {
        case 0..<5000000: return 0.03
        case 5000000..<10000000: return 0.1
        default: return 0.2
        }
    }
}

extension PHAsset {
    func getAssetThumbnail() -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: self,
                             targetSize: CGSize(width: self.pixelWidth, height: self.pixelHeight),
                             contentMode: .aspectFit,
                             options: option,
                             resultHandler: {(result, info) -> Void in
            thumbnail = result!
        })
        return thumbnail
    }
}

