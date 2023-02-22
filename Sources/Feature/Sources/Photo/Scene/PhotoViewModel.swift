//
//  PhotoViewModel.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Core
import SwiftUI
import Utility
import Foundation

class PhotoViewModel: ObservableObject {
    let dependency: PhotoDependency

    @Published var photo: UIImage?
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero
    @Published var photoLibraryError: PhotoLibraryError?

    var photoLibrary: PhotoLibraryService {
        dependency.photoLibrary
    }

    init(dependency: PhotoDependency) {
        self.dependency = dependency
        self.photo = dependency.photo
    }
}

// MARK: - Fetching
extension PhotoViewModel {
    func loadImage(targetSize: CGSize) async {
        do {
            let size = CGSize(width: targetSize.width * 3, height: targetSize.height * 3)
            let photo = try await dependency.photoLibrary.loadImage(for: dependency.assetId, targetSize: size)
            await MainActor.run {
                self.photo = photo
            }
        } catch {
            await MainActor.run {
                photoLibraryError = error as? PhotoLibraryError ?? .photoLoadingFailed
            }
        }
    }
}
