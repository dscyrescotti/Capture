//
//  PhotoLibraryService.swift
//  Capture
//
//  Created by Aye Chan on 2/18/23.
//

import UIKit
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

    func loadImage(for localId: String, targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default) async throws -> UIImage? {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [localId],
            options: nil
        )
        guard let asset = results.firstObject else {
            throw PhotoLibraryError.photoNotFound
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        return try await withCheckedThrowingContinuation { [unowned self] continuation in
            imageCachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options,
                resultHandler: { image, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image)
                }
            )
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
