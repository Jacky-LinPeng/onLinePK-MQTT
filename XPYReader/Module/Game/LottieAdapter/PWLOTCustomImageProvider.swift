//
//  CustomImageProvider.swift
//  lottie-oc
//
//  Created by 刘立超 on 2020/2/5.
//  Copyright © 2020 刘立超. All rights reserved.
//

import Foundation
import UIKit
import Lottie
/**
    自定义图片资源加载Provider
 */
public final class PWLOTCustomImageProvider: AnimationImageProvider {
  
    let folderPath: String
  
    init(folderPath: String) {
        self.folderPath = folderPath
    }
  
    public func imageForAsset(asset: ImageAsset) -> CGImage? {
        if asset.name.hasPrefix("data:"),
            let url = URL(string: asset.name),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data) {
            return image.cgImage
        }
    
        let imagePath = folderPath + "/" + asset.directory + asset.name
        guard let image = UIImage(contentsOfFile: imagePath) else {
          /// No image found.
          return nil
        }
        return image.cgImage
    }

}

