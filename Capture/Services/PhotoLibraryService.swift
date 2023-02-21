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
    let imageCachingManager = PHCachingImageManager()

    override init() {
        self.photoLibrary = .shared()
        super.init()
    }
}

// MARK: - Fetching
extension PhotoLibraryService {
    func fetchAllPhotos() async -> PHFetchResult<PHAsset> {
        await withCheckedContinuation { (continuation: CheckedContinuation<PHFetchResult<PHAsset>, Never>) in
            imageCachingManager.allowsCachingHighQualityImages = false
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            continuation.resume(returning: PHAsset.fetchAssets(with: .image, options: fetchOptions))
        }
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
            if let url {
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                createRequest.addResource(with: .pairedVideo, fileURL: url, options: options)
            }
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
