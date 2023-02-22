//
//  GalleryViewModel.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Core
import Photos
import SwiftUI
import Foundation

class GalleryViewModel: ObservableObject {
    let dependency: GalleryDependency

    @Published var results = PHFetchResult<PHAsset>()

    var photoLibrary: PhotoLibraryService {
        dependency.photoLibrary
    }

    init(dependency: GalleryDependency) {
        self.dependency = dependency
    }
}

// MARK: - Library Update
extension GalleryViewModel {
    func bindLibraryUpdateChannel() async {
        for await changeInstance in photoLibrary.libraryUpdateChannel {
            if let changes = changeInstance.changeDetails(for: results) {
                await MainActor.run {
                    withAnimation {
                        results = changes.fetchResultAfterChanges
                    }
                }
            }
        }
    }
}

// MARK: - Fetching
extension GalleryViewModel {
    func loadImage(for assetId: String, targetSize: CGSize) async -> UIImage? {
        try? await dependency.photoLibrary.loadImage(for: assetId, targetSize: targetSize)
    }

    func loadAllPhotos() async {
        let results = await photoLibrary.fetchAllPhotos()
        await MainActor.run {
            self.results = results
        }
    }
}
