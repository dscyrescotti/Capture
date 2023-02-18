//
//  PhotoLibraryService.swift
//  Capture
//
//  Created by Aye Chan on 2/18/23.
//

import Photos
import Foundation

class PhotoLibraryService: NSObject {
    let photoLibrary: PHPhotoLibrary

    override init() {
        self.photoLibrary = .shared()
        super.init()
    }
}

// MARK: - Saving
extension PhotoLibraryService {
    func savePhoto(for photoData: Data, withLivePhotoURL url: URL? = nil) async throws {
        guard photoLibraryPermissionStatus == .authorized else {
            throw PhotoLibraryError.photoLibraryDenied
        }
        try await photoLibrary.performChanges {
            let createRequest = PHAssetCreationRequest.forAsset()
            createRequest.addResource(with: .photo, data: photoData, options: nil)
//            if let url {
//                let options = PHAssetResourceCreationOptions()
//                options.shouldMoveFile = true
//                createRequest.addResource(with: .pairedVideo, fileURL: url, options: options)
//            }
        }
    }
}

// MARK: - Permission
extension PhotoLibraryService {
    var photoLibraryPermissionStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestPhotoLibraryPermission() async {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
}
