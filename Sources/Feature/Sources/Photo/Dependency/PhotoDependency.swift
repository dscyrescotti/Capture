//
//  PhotoDependency.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Core
import SwiftUI
import Foundation

public struct PhotoDependency {
    let photo: UIImage?
    let assetId: String
    let fileName: String
    let photoLibrary: PhotoLibraryService

    public init(
        photo: UIImage?,
        assetId: String,
        fileName: String,
        photoLibrary: PhotoLibraryService
    ) {
        self.photo = photo
        self.assetId = assetId
        self.fileName = fileName
        self.photoLibrary = photoLibrary
    }
}
