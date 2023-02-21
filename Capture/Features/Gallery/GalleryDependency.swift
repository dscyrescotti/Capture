//
//  GalleryDependency.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Foundation

struct GalleryDependency {
    let photoLibrary: PhotoLibraryService

    init(photoLibrary: PhotoLibraryService) {
        self.photoLibrary = photoLibrary
    }
}
