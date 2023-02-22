//
//  AppEnvironment+Dependency.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Core
import Photo
import Camera
import Gallery
import SwiftUI

public extension AppEnvironment {
    var galleryDependency: GalleryDependency { GalleryDependency(photoLibrary: photoLibrary) }
    var cameraDependency: CameraDependency { CameraDependency(camera: camera, photoLibrary: photoLibrary) }

    func photoDependency(photo: UIImage?, assetId: String, fileName: String) -> PhotoDependency {
        PhotoDependency(
            photo: photo,
            assetId: assetId,
            fileName: fileName,
            photoLibrary: photoLibrary
        )
    }
}
