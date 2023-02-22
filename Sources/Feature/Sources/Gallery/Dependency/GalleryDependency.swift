//
//  GalleryDependency.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Core
import Foundation

public struct GalleryDependency {
    let photoLibrary: PhotoLibraryService

    public init(photoLibrary: PhotoLibraryService) {
        self.photoLibrary = photoLibrary
    }
}
