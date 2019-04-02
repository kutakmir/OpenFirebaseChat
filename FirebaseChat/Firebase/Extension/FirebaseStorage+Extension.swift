//
//  FirebaseStorage.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 01/10/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseStorage

extension Storage {
    
    static func uploadFile(fileURL: URL, completion: @escaping (_ downloadURL : URL?, _ reference: StorageReference?, _ error: Error?) -> Void) -> StorageUploadTask {
        
        let fileName = fileURL.lastPathComponent
        let filePath = "Recordings/" + fileName
        let ref = storage().reference().child(filePath)
        let uploadTask = ref.putFile(from: fileURL, metadata: nil) { (metadata: StorageMetadata?, error: Error?) in
            if let error = error {
                completion(nil, ref, error)
            } else {
                ref.downloadURL(completion: { (url: URL?, error: Error?) in
                    completion(url, ref, error)
                })
            }
        }
        return uploadTask
    }

    /// DJ: Commenting out because this function appears to not be used -- why not used?
//    static func uploadFile(fileData: Data, fileName: String, completion: @escaping (_ downloadURL : URL?, _ reference: StorageReference?, _ error: Error?) -> Void) -> StorageUploadTask {
//
//        let filePath = "Recordings/" + fileName
//        let ref = storage().reference().child(filePath)
//        let uploadTask = ref.putData(fileData, metadata: nil) { (metadata: StorageMetadata?, error: Error?) in
//            if let error = error {
//                completion(nil, ref, error)
//            } else {
//                ref.downloadURL(completion: { (url: URL?, error: Error?) in
//                    completion(url, ref, error)
//                })
//            }
//        }
//        return uploadTask
//    }
    
}

extension StorageReference {
    
    var googleStorageURI: String {
        return "gs://\(bucket)/\(fullPath)"
    }

}
