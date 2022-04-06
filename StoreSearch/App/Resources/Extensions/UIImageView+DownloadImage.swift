//
//  UIImageView+DownloadImage.swift
//  StoreSearch
//
//  Created by Jordan Harvey-Morgan on 4/5/22.
//

import UIKit

extension UIImageView {
    
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url) { [weak self] url, _, error in
            
            if
                error == nil,
                let url = url,
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data)
            {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
            
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
}
